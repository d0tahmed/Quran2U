import re
import json

def is_arabic(text):
    for char in text:
        if '\u0600' <= char <= '\u06FF':
            return True
    return False

def parse_hisnul_muslim(filepath):
    entries = []
    
    current_category = ""
    current_title = ""
    
    current_translit = []
    current_english = []
    current_arabic = []
    current_reference = ""
    
    # State tracking for block inside an entry
    # 0 = translit, 1 = english, 2 = arabic
    state = 0 
    
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
            
        if re.match(r'^\(\d+\)$', line):
            i += 1
            continue
            
        if line.startswith("Chapter:"):
            current_category = line.replace("Chapter:", "").strip()
            current_title = current_category
            i += 1
            
            # skip the next (number)
            if i < len(lines) and re.match(r'^\(\d+\)$', lines[i].strip()):
                i += 1
            
            # skip the arabic chapter title
            if i < len(lines) and is_arabic(lines[i]):
                i += 1
                
            continue
            
        # Check if end of entry
        ref_match = re.search(r'Reference\s*:\s*Hisn al-Muslim\s*(\d+[a-z]?)', line)
        if ref_match:
            # Save entry
            entries.append({
                'id': ref_match.group(1),
                'category': current_category,
                'title': current_title,
                'arabic': ' '.join(current_arabic).strip(),
                'transliteration': ' '.join(current_translit).strip(),
                'englishTranslation': ' '.join(current_english).strip(),
                'reference': current_reference.strip(),
                'urduTranslation': ''
            })
            
            # reset entry buffers
            current_translit = []
            current_english = []
            current_arabic = []
            current_reference = ""
            state = 0
            i += 1
            continue
            
        # Parse content
        if is_arabic(line):
            current_arabic.append(line)
        else:
            # Could be translit or english
            # Check if line contains "Reference:"
            if "Reference:" in line:
                parts = line.split("Reference:")
                eng_part = parts[0].strip()
                ref_part = parts[1].strip()
                if eng_part:
                    current_english.append(eng_part)
                current_reference = ref_part
                state = 2 # expect arabic next
            else:
                if state == 0:
                    # How to differentiate Translit from English?
                    # Usually English comes after Translit. We can look for special characters or just assume the first part is Translit
                    # Wait, looking at the text, the English starts with Capital letter and doesn't have ` or ā.
                    # But it's risky.
                    # Let's check if we've seen any English indicators.
                    # A naive approach: if we already have english words like "O Allah", "Praise", "There is none", etc.
                    # Let's just collect until we hit something that looks like English.
                    # Actually, transliteration has things like ḥ, ā, ī, ū, `, '. 
                    if re.search(r'[āīūṣḍṭẓḥ`]', line.lower()):
                        current_translit.append(line)
                    else:
                        # might be english, or might be translit without special chars
                        # let's just append to english if translit already has some content and this looks like pure english
                        if len(current_translit) > 0 and not re.search(r'[āīūṣḍṭẓḥ`]', line.lower()) and "Allah" in line or "Lord" in line or "worship" in line:
                            current_english.append(line)
                            state = 1
                        else:
                            if state == 1:
                                current_english.append(line)
                            else:
                                current_translit.append(line)
                elif state == 1:
                    current_english.append(line)
                
        i += 1
        
    return entries

if __name__ == "__main__":
    entries = parse_hisnul_muslim('raw_data.txt')
    with open('parsed_duas.json', 'w', encoding='utf-8') as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
    print(f"Parsed {len(entries)} entries.")
