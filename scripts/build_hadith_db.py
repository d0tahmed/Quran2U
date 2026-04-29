import urllib.request
import json
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../assets/db/hadith.db')
BASE_URL = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions'

# Define our collections mapping matching the Dart enum exactly
COLLECTIONS = {
    'bukhari':  {'name': 'Sahih al Bukhari', 'files': ['eng-bukhari', 'urd-bukhari', 'ara-bukhari']},
    'muslim':   {'name': 'Sahih Muslim', 'files': ['eng-muslim', 'urd-muslim', 'ara-muslim']},
    'abuDawud': {'name': 'Sunan Abu Dawood', 'files': ['eng-abudawud', 'urd-abudawud', 'ara-abudawud']},
    'tirmidhi': {'name': "Jami' at-Tirmidhi", 'files': ['eng-tirmidhi', 'urd-tirmidhi', 'ara-tirmidhi']},
    'nasai':    {'name': "Sunan an-Nasa'i", 'files': ['eng-nasai', 'urd-nasai', 'ara-nasai']},
    'ibnMajah': {'name': 'Sunan Ibn Majah', 'files': ['eng-ibnmajah', 'urd-ibnmajah', 'ara-ibnmajah']}
}

def parse_num(val):
    if val is None: return 0
    if isinstance(val, (int, float)): return int(val)
    if isinstance(val, str):
        try: return int(float(val))
        except: return 0
    return 0

def init_db(conn):
    c = conn.cursor()
    # Books Table
    c.execute('''
        CREATE TABLE IF NOT EXISTS books (
            id TEXT PRIMARY KEY,
            name TEXT
        )
    ''')
    
    # Sections Table
    c.execute('''
        CREATE TABLE IF NOT EXISTS sections (
            book_id TEXT,
            section_number INTEGER,
            name_en TEXT,
            name_ur TEXT,
            name_ar TEXT,
            first_hadith INTEGER,
            last_hadith INTEGER,
            PRIMARY KEY (book_id, section_number)
        )
    ''')
    
    # Hadiths Table
    c.execute('''
        CREATE TABLE IF NOT EXISTS hadiths (
            book_id TEXT,
            section_number INTEGER,
            hadith_number INTEGER,
            arabic_number INTEGER,
            book_reference INTEGER,
            hadith_reference INTEGER,
            text_en TEXT,
            text_ur TEXT,
            text_ar TEXT,
            PRIMARY KEY (book_id, hadith_number)
        )
    ''')
    
    # Indexes for fast lookup
    c.execute('CREATE INDEX IF NOT EXISTS idx_hadiths_section ON hadiths (book_id, section_number)')
    
    conn.commit()

def fetch_json(file_prefix):
    url = f"{BASE_URL}/{file_prefix}.min.json"
    print(f"Fetching {url}...")
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read().decode('utf-8'))

def build_db():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        
    conn = sqlite3.connect(DB_PATH)
    init_db(conn)
    c = conn.cursor()
    
    for book_id, info in COLLECTIONS.items():
        print(f"\nProcessing {book_id}...")
        c.execute('INSERT INTO books (id, name) VALUES (?, ?)', (book_id, info['name']))
        
        eng_data = fetch_json(info['files'][0])
        urd_data = fetch_json(info['files'][1])
        ara_data = fetch_json(info['files'][2])
        
        # Build Sections
        # We use English as the baseline for sections
        sections_eng = eng_data['metadata']['sections']
        sections_urd = urd_data['metadata']['sections']
        sections_ara = ara_data['metadata']['sections']
        details = eng_data['metadata']['section_details']
        
        # Keep track of which section each hadith belongs to
        # (Some hadiths might have weird numbering, so mapping them properly is good)
        section_ranges = {} 
        
        for sec_num_str, sec_name_en in sections_eng.items():
            if not sec_name_en.strip(): continue
            sec_num = parse_num(sec_num_str)
            
            sec_detail = details.get(sec_num_str, {})
            first_h = parse_num(sec_detail.get('hadithnumber_first', 0))
            last_h = parse_num(sec_detail.get('hadithnumber_last', 0))
            
            # If completely empty (like Bukhari 0), skip
            if first_h == 0 and last_h == 0: continue
            
            section_ranges[sec_num] = (first_h, last_h)
            
            sec_name_ur = sections_urd.get(sec_num_str, '')
            sec_name_ar = sections_ara.get(sec_num_str, '')
            
            c.execute('''
                INSERT INTO sections (book_id, section_number, name_en, name_ur, name_ar, first_hadith, last_hadith)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (book_id, sec_num, sec_name_en, sec_name_ur, sec_name_ar, first_h, last_h))
            
        # Build Hadiths
        # We assume hadiths are ordered the same in all languages, or at least they share the same hadith_number
        hadiths_dict = {}
        
        for lang_code, data in [('en', eng_data), ('ur', urd_data), ('ar', ara_data)]:
            for h in data['hadiths']:
                h_num = parse_num(h.get('hadithnumber'))
                text = h.get('text', '')
                
                if h_num not in hadiths_dict:
                    ref = h.get('reference', {})
                    arabic_num = parse_num(h.get('arabicnumber'))
                    b_ref = parse_num(ref.get('book'))
                    h_ref = parse_num(ref.get('hadith'))
                    
                    # Determine section number based on ranges
                    sec_num = 0
                    for s_num, (f_h, l_h) in section_ranges.items():
                        if f_h <= h_num <= l_h:
                            sec_num = s_num
                            break
                    
                    hadiths_dict[h_num] = {
                        'arabic_number': arabic_num,
                        'book_reference': b_ref,
                        'hadith_reference': h_ref,
                        'sec_num': sec_num,
                        'text_en': '',
                        'text_ur': '',
                        'text_ar': ''
                    }
                
                hadiths_dict[h_num][f'text_{lang_code}'] = text
        
        # Insert hadiths
        batch = []
        for h_num, h_data in hadiths_dict.items():
            batch.append((
                book_id,
                h_data['sec_num'],
                h_num,
                h_data['arabic_number'],
                h_data['book_reference'],
                h_data['hadith_reference'],
                h_data['text_en'],
                h_data['text_ur'],
                h_data['text_ar']
            ))
            
        c.executemany('''
            INSERT INTO hadiths (book_id, section_number, hadith_number, arabic_number, book_reference, hadith_reference, text_en, text_ur, text_ar)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', batch)
        
        conn.commit()
        print(f"Inserted {len(batch)} hadiths for {book_id}")

    # Vacuum to compress DB
    c.execute('VACUUM')
    conn.commit()
    conn.close()
    print(f"\nDone! DB generated at {DB_PATH}. Size: {os.path.getsize(DB_PATH) / 1024 / 1024:.2f} MB")

if __name__ == '__main__':
    build_db()
