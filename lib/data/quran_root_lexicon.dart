// lib/data/quran_root_lexicon.dart
//
// Curated lexical dossier for high-frequency Quranic roots.
//
// Sources summarised: Ibn Fāris (Maqāyīs al-Lugha), al-Rāghib al-Iṣfahānī
// (Mufradāt Alfāẓ al-Qurʾān), Lane's Arabic-English Lexicon, and the standard
// tafsīr tradition. Entries are deliberately short summaries — the UI always
// tells the reader to return to full tafsīr for rulings.
//
// Extending this file is the only work needed to deepen coverage: add the root
// to [roots], then map its common mushaf spellings in [surfaceIndex].

import 'package:quran_recitation/models/word_insight.dart';

class QuranRootLexicon {
  QuranRootLexicon._();

  /// Root key format matches `ArabicText.guessRoot` output: letters joined
  /// by single spaces, e.g. 'ح م د'.
  static const Map<String, RootEntry> roots = <String, RootEntry>{
    'ا ل ه': RootEntry(
      root: 'ا ل ه',
      transliteration: 'ʾ-L-H',
      coreSense: 'To be worshipped; the One turned to in awe and longing',
      deepMeaning:
          'The root carries the sense of turning to something out of love, awe '
          'and helplessness — the heart that runs to a refuge. "Ilāh" is '
          'therefore anything taken as an object of ultimate devotion, while '
          '"Allāh" is the proper name of the only Being for whom that devotion '
          'is real and deserved. Classical grammarians treat "Allāh" as a name '
          'that admits no plural, no dual and no feminine — a linguistic mirror '
          'of tawḥīd itself.',
      whyUsed:
          'When the Quran uses the proper name rather than a description, it is '
          'addressing the listener\'s relationship with God directly, not '
          'arguing a concept.',
      family: ['الله', 'إله', 'آلهة', 'اللهم'],
    ),
    'ر ح م': RootEntry(
      root: 'ر ح م',
      transliteration: 'R-Ḥ-M',
      coreSense: 'Tenderness that acts; womb-like enveloping care',
      deepMeaning:
          'The same root gives "raḥim" — the womb — so the word carries the '
          'image of a mercy that surrounds, protects and nourishes something '
          'too weak to survive on its own. "Al-Raḥmān" is the intensive form '
          '(faʿlān): mercy overflowing, universal, momentary and total — it '
          'covers believer and disbeliever alike. "Al-Raḥīm" is the constant '
          'form (faʿīl): mercy that persists, specifically toward the believers.',
      whyUsed:
          'Pairing Raḥmān with Raḥīm answers two different fears at once — that '
          'God\'s mercy might be too small, and that it might not last.',
      family: ['الرحمن', 'الرحيم', 'رحمة', 'رحم', 'مرحمة'],
    ),
    'ح م د': RootEntry(
      root: 'ح م د',
      transliteration: 'Ḥ-M-D',
      coreSense: 'Praise given freely for intrinsic worth',
      deepMeaning:
          'Arabic distinguishes three kinds of praise: "madḥ" (praise that may '
          'be flattery, even for something inanimate), "shukr" (thanks for a '
          'favour received) and "ḥamd" — praise offered both for what is given '
          'and for what the praised One simply is. Ḥamd combines admiration '
          'with love and is due whether or not the praiser benefits.',
      whyUsed:
          'The Quran opens with "al-ḥamdu lillāh" rather than "ashkuru" because '
          'ḥamd is unconditional: it stands even in loss, where thanks alone '
          'might falter.',
      family: ['الحمد', 'حميد', 'محمود', 'أحمد', 'محمد'],
    ),
    'ر ب ب': RootEntry(
      root: 'ر ب ب',
      transliteration: 'R-B-B',
      coreSense: 'To nurture something stage by stage until it is complete',
      deepMeaning:
          'A "rabb" is at once owner, sustainer, master and the one who raises '
          'a thing gradually to its perfection — the word covers a gardener with '
          'his plants, a teacher with his students and a king with his realm. '
          'Used absolutely and without annexation ("al-Rabb"), it belongs to God '
          'alone; annexed ("rabb al-bayt"), it can be used of creatures.',
      whyUsed:
          'Choosing "Rabb" over "Mālik" frames God as actively cultivating the '
          'reader, not merely owning them.',
      family: ['رب', 'ربنا', 'ربك', 'أرباب', 'ربانيين'],
    ),
    'ع ل م': RootEntry(
      root: 'ع ل م',
      transliteration: 'ʿ-L-M',
      coreSense: 'To know; a mark by which a thing is recognised',
      deepMeaning:
          'The root\'s primary image is "ʿalāma" — a signpost. Knowledge in '
          'Arabic is therefore not raw data but the mark that lets you '
          'distinguish one reality from another. "ʿĀlam" (world) is from the '
          'same root: creation is itself a sign pointing to its Maker.',
      whyUsed:
          'Wherever the Quran contrasts "those who know" with "those who do not", '
          'it is contrasting people who read the signs with people who look past them.',
      family: ['علم', 'عالم', 'العالمين', 'يعلمون', 'عليم', 'معلوم'],
    ),
    'ع ب د': RootEntry(
      root: 'ع ب د',
      transliteration: 'ʿ-B-D',
      coreSense: 'Willing servitude; a path smoothed by walking it',
      deepMeaning:
          'An "ʿabd" is a servant owned entirely by another, but the root is '
          'also used for a road made smooth and easy by constant treading '
          '("ṭarīq muʿabbad"). Worship in Arabic therefore implies a life '
          'levelled and made passable by repeated obedience — humility that '
          'becomes second nature, not a single act.',
      whyUsed:
          'The Quran calls the Prophet ﷺ "ʿabduhu" at the highest moments '
          '(Isrāʾ, revelation) — servitude is presented as a rank, not a burden.',
      family: ['نعبد', 'عبادة', 'عباد', 'عبد', 'معبود'],
    ),
    'د ي ن': RootEntry(
      root: 'د ي ن',
      transliteration: 'D-Y-N',
      coreSense: 'Requital, debt, submission, and a way of life — all at once',
      deepMeaning:
          'The root binds three ideas that English separates: "dayn" (a debt '
          'that must be repaid), "dāna" (to judge or requite) and "dīn" (a '
          'system one submits to). A religion in this language is a ledger — '
          'obligations owed and accounts settled.',
      whyUsed:
          '"Mālik yawm al-dīn" reads simultaneously as Master of the Day of '
          'Judgement and Owner of the day every debt falls due.',
      family: ['الدين', 'يوم الدين', 'مدينون', 'دان'],
    ),
    'ه د ي': RootEntry(
      root: 'ه د ي',
      transliteration: 'H-D-Y',
      coreSense: 'To guide gently, and to gift',
      deepMeaning:
          'The root joins "hidāya" (guidance) with "hadiyya" (a gift) — guidance '
          'is framed as a present, not a demand. Classical usage adds the nuance '
          'of showing the way *with kindness*, leading someone forward rather '
          'than pointing from a distance.',
      whyUsed:
          '"Ihdinā" is a request for continuous leading, not one-time '
          'directions — which is why the already-guided are taught to keep asking.',
      family: ['اهدنا', 'هدى', 'هداية', 'مهتدون', 'الهادي'],
    ),
    'ص ر ط': RootEntry(
      root: 'ص ر ط',
      transliteration: 'Ṣ-R-Ṭ',
      coreSense: 'A wide, straight, swallowing road',
      deepMeaning:
          'Arabic has several words for path: "sabīl" (a route one takes), '
          '"ṭarīq" (any way, good or bad) and "ṣirāṭ" — a broad highway so '
          'clear that travellers are "swallowed" into it, from the same sense as '
          '"sarṭ", to swallow. It is always singular in the Quran, while paths '
          'away from it appear in the plural.',
      whyUsed:
          'The singular form is itself an argument: there are many ways off, '
          'and one way through.',
      family: ['الصراط', 'صراط مستقيم'],
    ),
    'ق و م': RootEntry(
      root: 'ق و م',
      transliteration: 'Q-W-M',
      coreSense: 'To stand upright; to establish and maintain',
      deepMeaning:
          'From standing comes "istiqāma" (uprightness), "qayyim" (that which '
          'is self-sustaining and sustains others), "qawm" (a people who stand '
          'together) and "iqāmat al-ṣalāh" — not merely performing prayer but '
          'establishing it, keeping it standing in a life.',
      whyUsed:
          'The Quran says "aqīmū al-ṣalāh", never "iʿmalū" — the verb demands '
          'that prayer be kept upright, not just executed.',
      family: ['مستقيم', 'يقيمون', 'قيوم', 'قوم', 'قائم', 'قيامة'],
    ),
    'ن ع م': RootEntry(
      root: 'ن ع م',
      transliteration: 'N-ʿ-M',
      coreSense: 'Softness, ease, and the favour that produces it',
      deepMeaning:
          'The root\'s physical sense is softness and smoothness to the touch. '
          'A "niʿma" is a blessing that makes life soft; "naʿīm" is the settled '
          'delight of Paradise. The verb "anʿama" is transitive with "ʿalā" — a '
          'favour poured down onto someone.',
      whyUsed:
          '"Those upon whom You bestowed favour" identifies the guided by what '
          'they received, not by what they achieved.',
      family: ['أنعمت', 'نعمة', 'النعيم', 'أنعم'],
    ),
    'ض ل ل': RootEntry(
      root: 'ض ل ل',
      transliteration: 'Ḍ-L-L',
      coreSense: 'To lose the way; to be lost while still moving',
      deepMeaning:
          'Ḍalāl is not standing still — it is walking with effort in the wrong '
          'direction, or losing something in a place where it cannot be '
          'recovered (milk lost in water is "ḍalla"). It covers both the one who '
          'never knew the road and the one who knew and drifted.',
      whyUsed:
          'Paired against "al-maghḍūb", it separates two failures: knowing and '
          'refusing, versus sincerity without knowledge.',
      family: ['الضالين', 'ضلال', 'أضل', 'ضلالة'],
    ),
    'غ ض ب': RootEntry(
      root: 'غ ض ب',
      transliteration: 'GH-Ḍ-B',
      coreSense: 'Anger with intensity and consequence',
      deepMeaning:
          'The root denotes a hardening, a rising up — Arabs called a hard rock '
          '"ghaḍba". When attributed to God it is understood, in the Sunni '
          'creed, as a real attribute befitting His majesty, expressed in '
          'withdrawal of favour and in punishment, without likeness to created '
          'emotion.',
      whyUsed:
          'The passive "al-maghḍūb ʿalayhim" hides the agent out of adab — '
          'God\'s name is not attached to the anger directly.',
      family: ['المغضوب', 'غضب', 'غضبان'],
    ),
    'ك ت ب': RootEntry(
      root: 'ك ت ب',
      transliteration: 'K-T-B',
      coreSense: 'To join things together; to write, to prescribe',
      deepMeaning:
          'The original sense is stitching or joining (a "katība" is a squadron '
          'joined in ranks) — writing is joining letters. Hence "kutiba ʿalaykum" '
          'means an obligation *bound* onto you, and "kitāb" is both a book and a '
          'decree.',
      whyUsed:
          'Calling revelation "al-Kitāb" asserts fixity: something written is '
          'settled and cannot be quietly revised.',
      family: ['كتاب', 'الكتاب', 'كتب', 'مكتوب', 'كاتب'],
    ),
    'ق ر ا': RootEntry(
      root: 'ق ر ا',
      transliteration: 'Q-R-ʾ',
      coreSense: 'To gather; to recite by joining letter to letter',
      deepMeaning:
          'The root means to collect and bring together. Recitation gathers '
          'sounds into words; "Qurʾān" is therefore both "the Recitation" and '
          '"the Collection" — and it names the book as something heard before '
          'it is read.',
      whyUsed:
          'The first revealed command is "Iqraʾ" — an oral verb — which is why '
          'the Quran\'s primary mode is sound.',
      family: ['قرآن', 'اقرأ', 'يقرأ', 'قراءة'],
    ),
    'ا م ن': RootEntry(
      root: 'ا م ن',
      transliteration: 'ʾ-M-N',
      coreSense: 'Safety; and the trust that produces safety',
      deepMeaning:
          'Before it means "belief", the root means security — "amn" is the '
          'absence of fear, "amāna" is a trust you can safely leave with '
          'someone. "Īmān" is thus not bare assent but giving your heart\'s '
          'security to what you affirm, which is why it pairs with action '
          'throughout the Quran.',
      whyUsed:
          'The believer is "muʾmin" — one who has found safety and gives safety '
          'to others; the same word is a name of God, al-Muʾmin.',
      family: ['آمنوا', 'إيمان', 'مؤمنون', 'أمانة', 'أمن'],
    ),
    'ك ف ر': RootEntry(
      root: 'ك ف ر',
      transliteration: 'K-F-R',
      coreSense: 'To cover over; to bury',
      deepMeaning:
          'A farmer is "kāfir" in classical Arabic because he covers the seed '
          'with soil, and night is "kāfir" because it covers the horizon. '
          'Disbelief is named for this act of covering: the truth is there, and '
          'something is laid over it. The same root gives "kaffāra" — an '
          'expiation that covers a sin.',
      whyUsed:
          'The image assumes recognition first: you can only cover what is '
          'already present.',
      family: ['كفروا', 'كافرون', 'كفر', 'كفارة'],
    ),
    'و ق ي': RootEntry(
      root: 'و ق ي',
      transliteration: 'W-Q-Y',
      coreSense: 'To shield; to place a barrier between yourself and harm',
      deepMeaning:
          'Taqwā is built on protection, not fear. A "wiqāya" is a shield or '
          'cover. The muttaqī is the traveller who walks through a thorn field '
          'with his garment gathered in — alert, careful, guarding himself. Fear '
          'is a by-product; the core is vigilance.',
      whyUsed:
          'Translating taqwā as "fear of God" loses the shield: the Quran is '
          'describing self-protection through obedience.',
      family: ['المتقين', 'تقوى', 'اتقوا', 'وقاية', 'أتقى'],
    ),
    'ص ب ر': RootEntry(
      root: 'ص ب ر',
      transliteration: 'Ṣ-B-R',
      coreSense: 'To restrain and confine oneself',
      deepMeaning:
          'The root means to hold something back — "ṣabr" is used of imprisoning '
          'an animal, and of a bitter medicinal plant. Patience in Arabic is '
          'therefore active self-restraint under pressure, not passive waiting, '
          'and it is bitter by admission.',
      whyUsed:
          'Because it means restraint, ṣabr is commanded in three arenas: '
          'obedience, avoiding sin, and enduring decree.',
      family: ['صبر', 'الصابرين', 'اصبروا', 'صبار'],
    ),
    'ش ك ر': RootEntry(
      root: 'ش ك ر',
      transliteration: 'SH-K-R',
      coreSense: 'To acknowledge a favour and let it show',
      deepMeaning:
          'Arabs describe a camel that grows visibly fat on little fodder as '
          '"shakūr" — the benefit shows on it. Gratitude in this language is '
          'therefore not a feeling but visible evidence of a gift received, '
          'appearing in tongue, heart and limbs.',
      whyUsed:
          'God calls Himself "al-Shakūr": the One who magnifies small deeds — '
          'gratitude flowing in the opposite direction.',
      family: ['شكر', 'شاكرين', 'اشكروا', 'شكور'],
    ),
    'ذ ك ر': RootEntry(
      root: 'ذ ك ر',
      transliteration: 'DH-K-R',
      coreSense: 'To remember; to mention aloud',
      deepMeaning:
          'One root covers silent recollection and spoken mention, because '
          'Arabic treats remembrance as incomplete until it surfaces on the '
          'tongue. "Dhikr" also names the reminder itself — the Quran calls '
          'itself al-Dhikr.',
      whyUsed:
          '"Remember Me and I will remember you" trades on both senses at once: '
          'inner attention and public mention.',
      family: ['ذكر', 'اذكروا', 'الذكر', 'تذكرة', 'ذاكرين'],
    ),
    'خ ل ق': RootEntry(
      root: 'خ ل ق',
      transliteration: 'KH-L-Q',
      coreSense: 'To bring into being according to a measure',
      deepMeaning:
          'The root implies proportioning — a leather-worker "yakhluqu" when he '
          'cuts hide precisely to size. Creation in the Quran is therefore never '
          'random emergence; it is design to specification. From the same root '
          'comes "khuluq", character: the shape a soul is cut into.',
      whyUsed:
          'Pairing "khalaqa" with "sawwā" and "qaddara" builds a sequence: '
          'bring into being, shape, then measure out.',
      family: ['خلق', 'الخالق', 'مخلوق', 'خلائق', 'خُلُق'],
    ),
    'ا م ر': RootEntry(
      root: 'ا م ر',
      transliteration: 'ʾ-M-R',
      coreSense: 'A command; an affair that matters',
      deepMeaning:
          'The same word covers an order given and the matter it concerns — '
          '"amr" is both the decree and the situation being decreed. The plural '
          'differs with the meaning: "awāmir" for commands, "umūr" for affairs.',
      whyUsed:
          '"Al-amr" in cosmic contexts denotes God\'s executive decree, the '
          'command by which things simply are.',
      family: ['أمر', 'الأمر', 'يأمرون', 'أمير', 'أمور'],
    ),
    'ن ز ل': RootEntry(
      root: 'ن ز ل',
      transliteration: 'N-Z-L',
      coreSense: 'To descend; to alight as a guest',
      deepMeaning:
          'The root includes hospitality — "nuzul" is the provision laid out for '
          'an arriving guest. Two verb forms matter: "anzala" (sending down in '
          'one movement) and "nazzala" (sending down in stages), and the Quran '
          'uses both about itself for different aspects of its revelation.',
      whyUsed:
          'The gradual form answers the objection "why not all at once?" — '
          'staged descent lets revelation meet events as they happen.',
      family: ['أنزل', 'نزل', 'تنزيل', 'منزل', 'نزول'],
    ),
    'ر س ل': RootEntry(
      root: 'ر س ل',
      transliteration: 'R-S-L',
      coreSense: 'To send forth with gentleness and purpose',
      deepMeaning:
          'The root\'s base sense is an unhurried, flowing motion — hair let '
          'down loosely is "mursal". A "rasūl" is one sent with a message, and '
          'the word denotes both the messenger and the message he carries.',
      whyUsed:
          'The gentleness in the root frames prophethood as a sending of mercy '
          'before it is a sending of warning.',
      family: ['رسول', 'رسل', 'أرسل', 'رسالة', 'مرسلين'],
    ),
    'ن و ر': RootEntry(
      root: 'ن و ر',
      transliteration: 'N-W-R',
      coreSense: 'Light — and, by extension, fire',
      deepMeaning:
          'Both "nūr" (light) and "nār" (fire) grow from this root: light that '
          'reveals and a blaze that consumes. Classical usage distinguishes '
          '"nūr" from "ḍiyāʾ" — ḍiyāʾ is light a body produces itself (the sun), '
          'nūr is light reflected or bestowed (the moon).',
      whyUsed:
          'Revelation is called "nūr" rather than "ḍiyāʾ": borrowed light, given '
          'by God, which is why guidance is never self-generated.',
      family: ['نور', 'النار', 'منير', 'أنار', 'نيران'],
    ),
    'ظ ل م': RootEntry(
      root: 'ظ ل م',
      transliteration: 'Ẓ-L-M',
      coreSense: 'To put something where it does not belong; darkness',
      deepMeaning:
          'The lexical definition is "placing a thing outside its proper place". '
          'The same root gives "ẓulumāt" (layers of darkness), because injustice '
          'and darkness share the sense of things being out of their right '
          'order. Shirk is called "great ẓulm" for exactly this reason: it '
          'misplaces worship.',
      whyUsed:
          'When the Quran says wrongdoers "wronged themselves", it is precise: '
          'the misplacement damages the doer first.',
      family: ['ظلم', 'الظالمين', 'ظلمات', 'مظلوم', 'أظلم'],
    ),
    'ح ق ق': RootEntry(
      root: 'ح ق ق',
      transliteration: 'Ḥ-Q-Q',
      coreSense: 'That which is firmly established and due',
      deepMeaning:
          'Ḥaqq spans truth, reality, right and obligation — one word for what '
          'is *actually so* and what is *owed*. Its opposite, "bāṭil", means '
          'something that collapses when examined, void from the inside.',
      whyUsed:
          'Al-Ḥaqq as a name of God asserts that reality itself is not neutral: '
          'it belongs to Him.',
      family: ['الحق', 'حقيق', 'حقوق', 'أحق', 'يحق'],
    ),
    'ع د ل': RootEntry(
      root: 'ع د ل',
      transliteration: 'ʿ-D-L',
      coreSense: 'To balance two sides evenly',
      deepMeaning:
          'The image is a load balanced on both flanks of a camel — equal weight, '
          'straightened. From it come "iʿtidāl" (moderation) and, curiously, '
          '"ʿadl" as a ransom or equivalent: what balances the scale.',
      whyUsed:
          'ʿAdl (giving each their exact due) is distinguished from "iḥsān" '
          '(giving more than due) — the Quran commands both together.',
      family: ['عدل', 'اعدلوا', 'عادل', 'يعدلون'],
    ),
    'س ل م': RootEntry(
      root: 'س ل م',
      transliteration: 'S-L-M',
      coreSense: 'Wholeness, freedom from defect — hence peace and submission',
      deepMeaning:
          'The core is soundness: a thing intact and free of flaw. Peace '
          '("salām") is a state without breach; "islām" is handing yourself over '
          'whole, without withholding a part; "salīm" (as in "qalbin salīm") is a '
          'heart uncorroded.',
      whyUsed:
          'Submission and peace share one root because, in the Quran\'s logic, '
          'wholeness comes precisely from not fragmenting your loyalty.',
      family: ['إسلام', 'مسلمون', 'سلام', 'أسلم', 'سليم'],
    ),
    'ح ي ي': RootEntry(
      root: 'ح ي ي',
      transliteration: 'Ḥ-Y-Y',
      coreSense: 'Life; and modesty',
      deepMeaning:
          'The root joins "ḥayāt" (life) with "ḥayāʾ" (modesty) — the Arabs saw '
          'shame-modesty as a sign of a living heart, and its loss as a kind of '
          'death. "Ḥayawān" in Surah al-ʿAnkabūt names the Hereafter as *life '
          'itself*, the intensive form.',
      whyUsed:
          'Al-Ḥayy as a divine name is paired with al-Qayyūm: self-living and '
          'self-sustaining, the two things creation is not.',
      family: ['حياة', 'الحي', 'يحيي', 'أحياء', 'حياء'],
    ),
    'م و ت': RootEntry(
      root: 'م و ت',
      transliteration: 'M-W-T',
      coreSense: 'The departure of life-force; stillness',
      deepMeaning:
          'Beyond biological death the root covers any loss of vitality — dead '
          'land, a dead heart, a still night. The Quran uses it as a recurring '
          'proof: land revived after death is the argument for resurrection.',
      whyUsed:
          'Death is described as something "created" (Mulk 67:2), which makes it '
          'an event with purpose rather than mere absence.',
      family: ['الموت', 'ميت', 'أموات', 'يميت', 'مماتي'],
    ),
    'ر ز ق': RootEntry(
      root: 'ر ز ق',
      transliteration: 'R-Z-Q',
      coreSense: 'Provision granted — everything one benefits from',
      deepMeaning:
          'Rizq is wider than money: it is anything God allots that a creature '
          'benefits from, including knowledge, children, health and time. The '
          'grammar is always of *giving* — a rizq is received, never generated.',
      whyUsed:
          '"Out of what We have provided them they spend" reminds the giver that '
          'he is redistributing, not donating from his own stock.',
      family: ['رزق', 'رزقناهم', 'الرزاق', 'يرزق', 'أرزاق'],
    ),
    'د ع و': RootEntry(
      root: 'د ع و',
      transliteration: 'D-ʿ-W',
      coreSense: 'To call; to summon toward oneself',
      deepMeaning:
          'One root serves supplication ("duʿāʾ"), invitation ("daʿwa") and '
          'claim ("iddiʿāʾ"). Supplication is thus framed as calling out to '
          'someone assumed to be near enough to hear — which is why the Quran '
          'answers a question about duʿāʾ with "I am near".',
      whyUsed:
          'Calling on someone is an admission of need; the Quran classifies '
          'duʿāʾ itself as worship for exactly that reason.',
      family: ['دعاء', 'ادعوني', 'يدعون', 'داعي', 'دعوة'],
    ),
    'ت و ب': RootEntry(
      root: 'ت و ب',
      transliteration: 'T-W-B',
      coreSense: 'To return',
      deepMeaning:
          'Tawba is simply a return — the servant returns to God, and God '
          '"returns" to the servant with acceptance. The Quran uses the same verb '
          'for both directions, and mentions God\'s turning first: He turns to '
          'them so that they may turn to Him.',
      whyUsed:
          'Naming repentance "return" implies the sinner is going back to '
          'somewhere he belongs, not approaching a stranger.',
      family: ['تاب', 'توبة', 'التواب', 'توبوا', 'تائبون'],
    ),
    'غ ف ر': RootEntry(
      root: 'غ ف ر',
      transliteration: 'GH-F-R',
      coreSense: 'To cover protectively',
      deepMeaning:
          'A "mighfar" is the mail helmet a warrior wears — the root means '
          'covering *in order to protect*. Divine forgiveness therefore both '
          'conceals the sin and shields the sinner from its consequence, which is '
          'more than mere pardon ("ʿafw", erasure).',
      whyUsed:
          'The intensive names al-Ghafūr and al-Ghaffār stress abundance and '
          'repetition — covering again and again.',
      family: ['غفر', 'الغفور', 'استغفروا', 'مغفرة', 'غفار'],
    ),
    'ع ذ ب': RootEntry(
      root: 'ع ذ ب',
      transliteration: 'ʿ-DH-B',
      coreSense: 'To prevent; punishment that cuts off',
      deepMeaning:
          'Lexicographers link "ʿadhāb" to prevention — punishment that stops a '
          'person from repeating an act, and stops water from being sweet '
          '("ʿadhb" means sweet water, its opposite in taste but same root in '
          'sense of cutting off thirst).',
      whyUsed:
          'The Quran often qualifies it — "ʿadhāb alīm", "ʿadhāb ʿaẓīm" — because '
          'the noun alone does not convey degree.',
      family: ['عذاب', 'يعذب', 'معذبين', 'عذب'],
    ),
    'ع م ل': RootEntry(
      root: 'ع م ل',
      transliteration: 'ʿ-M-L',
      coreSense: 'Deliberate action, done with intent',
      deepMeaning:
          '"ʿAmal" differs from "fiʿl": fiʿl is any act, including the '
          'accidental and the instinctive, while ʿamal is purposeful work. This '
          'is why reward attaches to ʿamal — intention is baked into the word.',
      whyUsed:
          'The Quran\'s standard pairing is "believed and did righteous deeds": '
          'the second term prevents faith from being read as a claim alone.',
      family: ['عمل', 'أعمال', 'يعملون', 'عاملون', 'الصالحات'],
    ),
    'ق ل ب': RootEntry(
      root: 'ق ل ب',
      transliteration: 'Q-L-B',
      coreSense: 'To turn over, to overturn',
      deepMeaning:
          'The heart is named "qalb" because it turns — the Arabs named it for '
          'its instability, not its constancy. Hence the Prophet\'s ﷺ frequent '
          'supplication addressed to the "Turner of hearts", and the Quran\'s '
          'concern with hearts that are sealed, hardened or sound.',
      whyUsed:
          'When the Quran locates understanding in the qalb rather than the '
          'mind, it is saying comprehension is a state that can flip.',
      family: ['قلب', 'قلوب', 'انقلب', 'تقلب', 'مقلب'],
    ),
    'ن ف س': RootEntry(
      root: 'ن ف س',
      transliteration: 'N-F-S',
      coreSense: 'Self, soul — and breath',
      deepMeaning:
          'The root ties the self to breathing ("nafas"), to preciousness '
          '("nafīs") and to competition ("tanāfus"). The Quran names three '
          'states of the nafs: the one that incites to evil, the self-reproaching '
          'one, and the one at peace.',
      whyUsed:
          'Because nafs also means "the very same thing", phrases like "wronged '
          'themselves" land with double force.',
      family: ['نفس', 'أنفس', 'نفوس', 'تنفس', 'نفيس'],
    ),
    'س م ع': RootEntry(
      root: 'س م ع',
      transliteration: 'S-M-ʿ',
      coreSense: 'To hear — and therefore to respond',
      deepMeaning:
          'In Arabic idiom hearing implies compliance: "samiʿa Allāhu liman '
          'ḥamidah" means God *responds to* the one who praises Him. "Samiʿnā wa '
          'aṭaʿnā" is the believer\'s formula precisely because hearing without '
          'obedience is treated as not hearing at all.',
      whyUsed:
          'Al-Samīʿ is usually paired with al-ʿAlīm or al-Baṣīr: hearing joined '
          'to full knowledge leaves no room for unheard speech.',
      family: ['سمع', 'يسمعون', 'السميع', 'استمعوا', 'سماع'],
    ),
    'ب ص ر': RootEntry(
      root: 'ب ص ر',
      transliteration: 'B-Ṣ-R',
      coreSense: 'Sight — outward and inward',
      deepMeaning:
          'Baṣar is the eye\'s seeing; "baṣīra" is insight, the eye of the heart. '
          'The Quran plays the two against each other: "it is not the eyes that '
          'are blind, but the hearts within the chests".',
      whyUsed:
          '"Baṣāʾir" (plural of baṣīra) is used for the Quran itself: a set of '
          'lenses that restore inward vision.',
      family: ['بصر', 'أبصار', 'البصير', 'بصيرة', 'يبصرون'],
    ),
    'ع ق ل': RootEntry(
      root: 'ع ق ل',
      transliteration: 'ʿ-Q-L',
      coreSense: 'To tie down; to restrain by reason',
      deepMeaning:
          'An "ʿiqāl" is the rope that ties a camel\'s knee so it cannot wander. '
          'Reason in Arabic is thus a restraint, not a horizon-expander: the '
          'intellect is what holds a person back from folly.',
      whyUsed:
          'The Quran almost always uses the verb ("do you not reason?") rather '
          'than the noun — intellect is an act you perform, not a possession.',
      family: ['يعقلون', 'عقل', 'عاقل', 'تعقلون'],
    ),
    'ب ي ن': RootEntry(
      root: 'ب ي ن',
      transliteration: 'B-Y-N',
      coreSense: 'Separation — and therefore clarity',
      deepMeaning:
          'The root means to be distinct or between. Clarity ("bayān") is the '
          'act of separating one thing from another so it can be recognised, '
          'which is why the same root gives "bayn" (between) and "mubīn" '
          '(manifest).',
      whyUsed:
          'Calling the Quran "mubīn" claims it both is clear and *makes* things '
          'clear — the form carries an active sense.',
      family: ['بين', 'بينات', 'مبين', 'تبيان', 'بيان'],
    ),
    'ح ك م': RootEntry(
      root: 'ح ك م',
      transliteration: 'Ḥ-K-M',
      coreSense: 'To restrain in order to set right; to judge wisely',
      deepMeaning:
          'The root\'s image is the bridle ("ḥakama") that controls a horse. '
          'Judgement, governance and wisdom all grow from it: "ḥukm" (ruling), '
          '"ḥikma" (wisdom — knowing what prevents error), "muḥkam" (a verse of '
          'settled, unambiguous meaning).',
      whyUsed:
          'Al-Ḥakīm is placed after names of power (al-ʿAzīz al-Ḥakīm) so that '
          'might is read as never arbitrary.',
      family: ['حكم', 'حكمة', 'الحكيم', 'يحكمون', 'محكمات'],
    ),
    'م ل ك': RootEntry(
      root: 'م ل ك',
      transliteration: 'M-L-K',
      coreSense: 'To own and to have the power to dispose',
      deepMeaning:
          'The root separates into "malik" (king — sovereignty over people) and '
          '"mālik" (owner — full disposal over property). Surah al-Fātiḥa is '
          'recited in both readings, and the tafsīr tradition treats them as '
          'complementary rather than competing.',
      whyUsed:
          'On the Day of Judgement the Quran strips all other ownership: "To '
          'whom belongs the dominion today?"',
      family: ['ملك', 'مالك', 'الملك', 'ملكوت', 'مملوك'],
    ),
    'ق د ر': RootEntry(
      root: 'ق د ر',
      transliteration: 'Q-D-R',
      coreSense: 'To measure precisely; hence power',
      deepMeaning:
          'Qadar is a measure or amount before it is "destiny". God\'s power '
          '("qudra") is expressed through exact proportioning: "He created '
          'everything and determined it with precise measure". Laylat al-Qadr '
          'is named for the measuring out of the year\'s decree — and for its '
          'immense worth.',
      whyUsed:
          'Framing power as measurement rejects the idea of raw, undirected '
          'force.',
      family: ['قدير', 'قدر', 'مقدار', 'يقدر', 'قدرة'],
    ),
    'ع ز ز': RootEntry(
      root: 'ع ز ز',
      transliteration: 'ʿ-Z-Z',
      coreSense: 'Strength that cannot be overcome; rarity',
      deepMeaning:
          'ʿIzza combines three senses lexicographers list together: being '
          'unbreakable, being unreachable, and being scarce/precious. "ʿAzīz" '
          'therefore means mighty, impenetrable and dear all at once.',
      whyUsed:
          'When the Quran says honour belongs entirely to God, it uses this '
          'root — honour sought elsewhere is by definition breakable.',
      family: ['العزيز', 'عزة', 'أعز', 'عزيز'],
    ),
    'ص د ق': RootEntry(
      root: 'ص د ق',
      transliteration: 'Ṣ-D-Q',
      coreSense: 'Truthfulness; correspondence between word and reality',
      deepMeaning:
          'From it come "ṣidq" (truth in speech), "ṣadaqa" (charity — proof that '
          'a claim of faith is true), "ṣadāq" (dowry) and "taṣdīq" '
          '(affirmation). A "ṣiddīq" is someone whose truthfulness has become '
          'their nature.',
      whyUsed:
          'Charity is called ṣadaqa because it verifies faith: money is where '
          'sincerity is hardest to fake.',
      family: ['صدق', 'صادقين', 'صدقة', 'تصديق', 'صديق'],
    ),
    'ش ر ك': RootEntry(
      root: 'ش ر ك',
      transliteration: 'SH-R-K',
      coreSense: 'To share; to be a partner',
      deepMeaning:
          'Sharing is neutral in itself — a "sharika" is a business partnership. '
          'Shirk becomes the gravest wrong only when the sharing is of what '
          'belongs exclusively to God: worship, ultimate reliance, and the right '
          'to legislate.',
      whyUsed:
          'The Quran argues against shirk on grounds of ownership, not '
          'preference: a partner has no share in creation.',
      family: ['شرك', 'مشركين', 'شريك', 'أشركوا', 'شركاء'],
    ),
    'ف ل ح': RootEntry(
      root: 'ف ل ح',
      transliteration: 'F-L-Ḥ',
      coreSense: 'To split open the earth; to cultivate — hence to succeed',
      deepMeaning:
          'A "fallāḥ" is a farmer who splits the soil. Success in Arabic is '
          'agricultural: you break hard ground, plant, wait, and harvest later. '
          '"Falāḥ" therefore implies patient work whose result appears in '
          'another season — which the Quran locates in the Hereafter.',
      whyUsed:
          'The adhān calls "come to falāḥ" — inviting to the harvest, not to '
          'immediate gain.',
      family: ['أفلح', 'المفلحون', 'فلاح', 'تفلحون'],
    ),
    'خ س ر': RootEntry(
      root: 'خ س ر',
      transliteration: 'KH-S-R',
      coreSense: 'Loss; capital eaten away',
      deepMeaning:
          'Khusr is a merchant\'s word: not failing to profit, but losing the '
          'principal itself. Surah al-ʿAṣr swears that humanity is in exactly '
          'this state by default — time consuming the one commodity nobody can '
          'replace.',
      whyUsed:
          'The commercial framing runs through the Quran: faith is a trade, and '
          'loss is measured in what was spent, not merely missed.',
      family: ['خسر', 'خاسرين', 'خسران', 'يخسرون'],
    ),
    'ص ل و': RootEntry(
      root: 'ص ل و',
      transliteration: 'Ṣ-L-W',
      coreSense: 'Connection; supplication; blessing',
      deepMeaning:
          'The noun covers the ritual prayer, any supplication, and — when its '
          'subject is God — sending mercy and honour. Lexicographers connect it '
          'to "ṣalā", the lower back that bends, tying the word to the physical '
          'act of bowing.',
      whyUsed:
          'One word doing all three jobs makes the point that ṣalāh is a link: '
          'the servant calls, God responds with blessing.',
      family: ['الصلاة', 'يصلون', 'مصلين', 'صلى', 'صلوات'],
    ),
    'ن ف ق': RootEntry(
      root: 'ن ف ق',
      transliteration: 'N-F-Q',
      coreSense: 'To pass through and out; to spend',
      deepMeaning:
          'A "nafaq" is a tunnel with two openings, and the jerboa\'s escape '
          'burrow ("nāfiqāʾ") gives "munāfiq" — the hypocrite who keeps a second '
          'exit. Spending ("infāq") is money passing out of your hands; both '
          'senses share the idea of something not staying put.',
      whyUsed:
          'Spending and hypocrisy from one root is a warning in itself: wealth '
          'that leaves openly builds faith, a life with a hidden exit destroys it.',
      family: ['ينفقون', 'نفقة', 'منافقون', 'أنفقوا'],
    ),
    'غ ي ب': RootEntry(
      root: 'غ ي ب',
      transliteration: 'GH-Y-B',
      coreSense: 'What is hidden from perception',
      deepMeaning:
          'Ghayb is not "the supernatural" but simply whatever is absent from '
          'the senses — including a person\'s absence (hence "ghība", backbiting: '
          'speaking of someone not present). Belief "in the ghayb" is trust in '
          'reported reality that cannot be tested by sight.',
      whyUsed:
          'The Quran makes belief in the unseen the first quality of the '
          'muttaqīn — before prayer and charity — because everything else rests '
          'on it.',
      family: ['الغيب', 'غائب', 'غيبة', 'يغيب'],
    ),
    'ج ن ن': RootEntry(
      root: 'ج ن ن',
      transliteration: 'J-N-N',
      coreSense: 'To conceal, to cover over',
      deepMeaning:
          'Everything from this root is hidden: "janna" (a garden so dense its '
          'ground is hidden by foliage), "jinn" (creatures unseen), "janīn" (the '
          'foetus in the womb), "junūn" (madness — reason veiled) and "junna" (a '
          'shield).',
      whyUsed:
          'Paradise is named for concealment: it is the reward you cannot see, '
          'which is why it must be believed before it is entered.',
      family: ['جنة', 'جنات', 'الجن', 'جنين', 'مجنون'],
    ),
    'س ب ح': RootEntry(
      root: 'س ب ح',
      transliteration: 'S-B-Ḥ',
      coreSense: 'To swim, to travel swiftly — to declare God far above defect',
      deepMeaning:
          'The physical sense is moving swiftly through water or space (the sun '
          'and moon "swim" in their orbits). Tasbīḥ is the soul moving swiftly '
          'away from every unworthy thought about God — a declaration of '
          'transcendence, not merely praise.',
      whyUsed:
          '"Subḥān" appears exactly where a false claim about God has been '
          'mentioned: it is a corrective, thrown up immediately.',
      family: ['سبحان', 'يسبح', 'تسبيح', 'سابحات', 'مسبحين'],
    ),
    'خ ش ي': RootEntry(
      root: 'خ ش ي',
      transliteration: 'KH-SH-Y',
      coreSense: 'Awe born of knowledge',
      deepMeaning:
          'Khashya is distinguished from "khawf": khawf is fear of harm, which '
          'anyone can feel, while khashya is reverence proportional to how well '
          'you know the One feared — hence "only those of His servants who have '
          'knowledge truly fear Him".',
      whyUsed:
          'Choosing khashya over khawf marks the fear of the learned from the '
          'fear of the threatened.',
      family: ['خشية', 'يخشون', 'خاشعين', 'أخشى'],
    ),
    'و ل ي': RootEntry(
      root: 'و ل ي',
      transliteration: 'W-L-Y',
      coreSense: 'Nearness with no gap; hence protection and allegiance',
      deepMeaning:
          'The root means two things being adjacent with nothing between them. '
          'From it: "walī" (ally, guardian, protector), "walā" (loyalty) and '
          '"tawallā" — which means both to turn toward in allegiance and to turn '
          'away, depending on the preposition that follows.',
      whyUsed:
          'God is "Walī of those who believe" — the same word used for a legal '
          'guardian, implying responsibility, not just friendship.',
      family: ['ولي', 'أولياء', 'مولى', 'تولى', 'ولاية'],
    ),
    'ن ص ر': RootEntry(
      root: 'ن ص ر',
      transliteration: 'N-Ṣ-R',
      coreSense: 'Aid given to someone under attack; hence victory',
      deepMeaning:
          'Naṣr is specifically help extended to the wronged or the besieged — '
          'Arabs used it of rain coming to parched land. Victory is the outcome, '
          'but the word\'s centre of gravity is the *helping*, not the winning.',
      whyUsed:
          '"If you help God, He will help you" trades on this sense: aiding His '
          'cause when it is the weaker side.',
      family: ['نصر', 'انصرنا', 'ناصر', 'أنصار', 'منصور'],
    ),
    'ف ت ح': RootEntry(
      root: 'ف ت ح',
      transliteration: 'F-T-Ḥ',
      coreSense: 'To open what was closed',
      deepMeaning:
          'Opening covers conquest ("fatḥ"), judgement between disputing parties '
          '("fātiḥ" as judge, since a ruling opens a deadlock), and the opening '
          'of provision or understanding. Al-Fātiḥa is the Opener of the Book.',
      whyUsed:
          'Naming conquest "opening" reframes it: something shut is being made '
          'accessible, not something intact being broken.',
      family: ['فتح', 'الفاتحة', 'مفاتح', 'يفتح', 'فتاح'],
    ),
    'ط ه ر': RootEntry(
      root: 'ط ه ر',
      transliteration: 'Ṭ-H-R',
      coreSense: 'Purity — removal of what does not belong',
      deepMeaning:
          'Ṭahāra covers physical cleanliness and moral clearing alike. The '
          'Quran uses the intensive form "muṭahharūn/muṭahhara" for those purified '
          '*by God* — purity received, not achieved.',
      whyUsed:
          'Ritual purification precedes prayer to make an outward act rehearse '
          'an inward one.',
      family: ['طهور', 'تطهير', 'مطهرين', 'يتطهرون', 'طاهر'],
    ),
    'ح ر م': RootEntry(
      root: 'ح ر م',
      transliteration: 'Ḥ-R-M',
      coreSense: 'Inviolability — a boundary that must not be crossed',
      deepMeaning:
          'The root produces both "ḥarām" (forbidden) and "ḥaram" (sanctuary) — '
          'two faces of one idea: something set apart and protected. "Iḥrām" is '
          'entering a state where ordinary permissions are suspended.',
      whyUsed:
          'Calling a sin ḥarām frames it as trespass on a protected space, not '
          'merely as a rule broken.',
      family: ['حرام', 'الحرم', 'حرمات', 'محرم', 'إحرام'],
    ),
    'س م و': RootEntry(
      root: 'س م و',
      transliteration: 'S-M-W',
      coreSense: 'Height, elevation — and the name that marks a thing',
      deepMeaning:
          'From this root come "samāʾ" (the sky, what is above) and "ism" (a '
          'name). Grammarians linked them: a name raises a thing out of '
          'anonymity so it can be pointed to. Beginning "bismillāh" therefore '
          'means acting under a name that is itself elevated above all others.',
      whyUsed:
          'Every surah but one opens by attaching the act of reading to a name '
          '— the deed is placed under authority before it begins.',
      family: ['اسم', 'أسماء', 'سماء', 'سماوات'],
    ),
    'ع و ن': RootEntry(
      root: 'ع و ن',
      transliteration: 'ʿ-W-N',
      coreSense: 'Help given to someone already making an effort',
      deepMeaning:
          '"ʿAwn" is assistance that joins an existing struggle — the helper '
          'does not act instead of you, he acts with you. The form used in '
          'al-Fātiḥa ("nastaʿīn") is the request form: seeking that help, '
          'continuously.',
      whyUsed:
          'Placing "we worship" before "we seek help" teaches the order: effort '
          'first, then the plea for support in it.',
      family: ['نستعين', 'أعان', 'معونة', 'تعاونوا', 'مستعان'],
    ),
    'ي و م': RootEntry(
      root: 'ي و م',
      transliteration: 'Y-W-M',
      coreSense: 'A day; any bounded stretch of time',
      deepMeaning:
          'In Arabic a "yawm" is not fixed at 24 hours — it is a period defined '
          'by an event, which is why the Quran speaks of days of differing '
          'length. Used absolutely with "al-dīn" or "al-qiyāma", it names the '
          'one day that decides all others.',
      whyUsed:
          'The indefinite "yawma" opening many verses drops the listener into '
          'the scene as if it were already happening.',
      family: ['يوم', 'اليوم', 'أيام', 'يومئذ'],
    ),
    'ا خ ر': RootEntry(
      root: 'ا خ ر',
      transliteration: 'ʾ-KH-R',
      coreSense: 'To come last; to be delayed',
      deepMeaning:
          'The "ākhira" is literally "the latter [abode]", always implied '
          'against "al-dunyā" — "the nearer [abode]". The pairing is temporal '
          'and spatial at once: one is close and immediate, the other is last '
          'and lasting.',
      whyUsed:
          'Naming the Hereafter by lateness rather than by reward keeps the '
          'emphasis on sequence: it is what comes after, unavoidably.',
      family: ['الآخرة', 'آخر', 'أخر', 'مؤخر', 'استأخر'],
    ),
    'ي ق ن': RootEntry(
      root: 'ي ق ن',
      transliteration: 'Y-Q-N',
      coreSense: 'Certainty that leaves no room for doubt',
      deepMeaning:
          'Lexicographers describe "yaqīn" as knowledge settled after doubt has '
          'been examined and dismissed — water that has become still and clear. '
          'The Quran ranks it in stages: ʿilm al-yaqīn (certainty by knowing), '
          'ʿayn al-yaqīn (by seeing), ḥaqq al-yaqīn (by experiencing).',
      whyUsed:
          'Certainty is what the Quran asks of belief in the unseen — not '
          'probability, and not blind guessing.',
      family: ['يقين', 'يوقنون', 'موقنين', 'استيقنت'],
    ),
    'ص ل ح': RootEntry(
      root: 'ص ل ح',
      transliteration: 'Ṣ-L-Ḥ',
      coreSense: 'To be sound and fit for purpose; to repair',
      deepMeaning:
          'Ṣalāḥ is the opposite of "fasād" (rot, corruption). A thing is ṣāliḥ '
          'when it works as it was designed to work — so a righteous deed is '
          'simply an act that functions correctly, and "iṣlāḥ" is putting back '
          'into working order what has broken.',
      whyUsed:
          'Rendering "ʿamal ṣāliḥ" as merely "good deed" loses the engineering '
          'sense: it is the deed that actually repairs something.',
      family: ['صالح', 'الصالحات', 'أصلح', 'إصلاح', 'مصلحون'],
    ),
    'ق و ل': RootEntry(
      root: 'ق و ل',
      transliteration: 'Q-W-L',
      coreSense: 'To say; speech as a deliberate act',
      deepMeaning:
          '"Qawl" is speech with content — a statement that can be weighed, '
          'unlike mere sound. The Quran grades it: "qawlan sadīdan" (straight '
          'speech), "qawlan maʿrūfan" (kind speech), "qawlan layyinan" (gentle '
          'speech, commanded even before Pharaoh).',
      whyUsed:
          'The imperative "Qul" — say — appears over three hundred times: '
          'revelation is quoted, not paraphrased, and the Prophet ﷺ is a '
          'transmitter whose very command to speak is preserved in the text.',
      family: ['قل', 'قال', 'يقول', 'قول', 'مقال'],
    ),
    'ا ح د': RootEntry(
      root: 'ا ح د',
      transliteration: 'ʾ-Ḥ-D',
      coreSense: 'Oneness that cannot be divided or duplicated',
      deepMeaning:
          '"Wāḥid" counts one of a series — one of many possible. "Aḥad" '
          'refuses the series altogether: it negates parts, partners and '
          'peers, and in the negative it means "not anyone at all". Surah '
          'al-Ikhlāṣ uses "Aḥad" without the article, which grammarians read '
          'as absolute, unqualified singularity.',
      whyUsed:
          'Choosing Aḥad over Wāḥid answers the question "one of what?" — the '
          'answer is that there is no category He belongs to.',
      family: ['أحد', 'واحد', 'الواحد', 'وحده', 'توحيد'],
    ),
    'ص م د': RootEntry(
      root: 'ص م د',
      transliteration: 'Ṣ-M-D',
      coreSense: 'The One turned to in need; solid, without hollowness',
      deepMeaning:
          'Two classical explanations run together: al-Ṣamad is the master to '
          'whom all creatures turn when they are desperate, and it is that '
          'which is utterly solid — no gap, no cavity, no need to take '
          'anything in. Both meanings converge on independence: everything '
          'needs Him, He needs nothing.',
      whyUsed:
          'It appears exactly once in the Quran, in the surah defining who God '
          'is — a word chosen for its density.',
      family: ['الصمد'],
    ),
    'و ل د': RootEntry(
      root: 'و ل د',
      transliteration: 'W-L-D',
      coreSense: 'To give birth; offspring and parentage',
      deepMeaning:
          'The root covers the whole chain of descent: "walad" (child), '
          '"wālid" (parent), "mawlūd" (the one born). Its denial in Surah '
          'al-Ikhlāṣ moves in both directions — He did not beget, and He was '
          'not begotten — closing off origin as well as continuation.',
      whyUsed:
          'Birth implies need, likeness and succession; denying it removes the '
          'three assumptions most religions of the time built on.',
      family: ['ولد', 'والدين', 'مولود', 'يلد', 'أولاد'],
    ),
    'ا ن س': RootEntry(
      root: 'ا ن س',
      transliteration: 'ʾ-N-S',
      coreSense: 'Human being — from familiarity, or from forgetfulness',
      deepMeaning:
          'Lexicographers derive "insān" either from "uns" (intimacy, '
          'sociability — humans cannot live alone) or from "nisyān" '
          '(forgetting — the creature who forgets his covenant). The Quran '
          'plays on both: humanity is made for companionship and prone to '
          'forgetfulness.',
      whyUsed:
          'Verses that begin "O mankind" (yā ayyuhā al-nās) address the shared '
          'human condition, before belief divides the audience.',
      family: ['إنسان', 'الناس', 'أنس', 'إنس', 'أنيس'],
    ),
    'ر ي ب': RootEntry(
      root: 'ر ي ب',
      transliteration: 'R-Y-B',
      coreSense: 'Unsettling doubt — suspicion that disturbs',
      deepMeaning:
          '"Rayb" is stronger than "shakk": shakk is simple uncertainty '
          'between two options, while rayb is doubt mixed with unease and '
          'accusation. Denying rayb of the Book denies not only uncertainty '
          'but any grounds for suspicion about it.',
      whyUsed:
          'Al-Baqarah opens by removing rayb before making a single claim — '
          'the ground is cleared before the building starts.',
      family: ['ريب', 'مريب', 'ارتاب', 'المرتابين'],
    ),
  };

  /// Verified mapping of common mushaf word-forms (normalised, diacritic-free)
  /// to their root. Anything not listed here falls back to the stemmer and is
  /// clearly labelled as an estimate in the UI.
  static const Map<String, String> surfaceIndex = <String, String>{
    // Al-Fātiḥa, in order
    'بسم': 'س م و', 'الله': 'ا ل ه', 'الرحمن': 'ر ح م', 'الرحيم': 'ر ح م',
    'الحمد': 'ح م د', 'لله': 'ا ل ه', 'رب': 'ر ب ب', 'ربنا': 'ر ب ب',
    'ربك': 'ر ب ب', 'ربي': 'ر ب ب', 'العالمين': 'ع ل م', 'عالمين': 'ع ل م',
    'مالك': 'م ل ك', 'ملك': 'م ل ك', 'الملك': 'م ل ك', 'يوم': 'ي و م',
    'اليوم': 'ي و م', 'الدين': 'د ي ن', 'دين': 'د ي ن', 'نعبد': 'ع ب د',
    'اعبدوا': 'ع ب د', 'عباد': 'ع ب د', 'عبادة': 'ع ب د', 'العبادة': 'ع ب د',
    'نستعين': 'ع و ن', 'اهدنا': 'ه د ي', 'هدي': 'ه د ي', 'هدا': 'ه د ي',
    'الهدي': 'ه د ي', 'يهدي': 'ه د ي', 'المهتدون': 'ه د ي',
    'الصراط': 'ص ر ط', 'صراط': 'ص ر ط', 'المستقيم': 'ق و م',
    'مستقيم': 'ق و م', 'انعمت': 'ن ع م', 'نعمة': 'ن ع م', 'نعمت': 'ن ع م',
    'المغضوب': 'غ ض ب', 'غضب': 'غ ض ب', 'الضالين': 'ض ل ل', 'ضلال': 'ض ل ل',

    // Highest-frequency vocabulary
    'الكتاب': 'ك ت ب', 'كتاب': 'ك ت ب', 'كتب': 'ك ت ب', 'كتابا': 'ك ت ب',
    'القران': 'ق ر ا', 'قران': 'ق ر ا', 'اقرا': 'ق ر ا', 'يقرا': 'ق ر ا',
    'المتقين': 'و ق ي', 'اتقوا': 'و ق ي', 'تقوي': 'و ق ي', 'يتقون': 'و ق ي',
    'المتقون': 'و ق ي', 'الغيب': 'غ ي ب', 'غيب': 'غ ي ب',
    'يومنون': 'ا م ن', 'امنوا': 'ا م ن', 'المومنين': 'ا م ن',
    'المومنون': 'ا م ن', 'ايمان': 'ا م ن', 'الايمان': 'ا م ن',
    'امن': 'ا م ن', 'امنا': 'ا م ن',
    'كفروا': 'ك ف ر', 'الكافرين': 'ك ف ر', 'كافرون': 'ك ف ر', 'كفر': 'ك ف ر',
    'يقيمون': 'ق و م', 'اقيموا': 'ق و م', 'قيوم': 'ق و م', 'القيامة': 'ق و م',
    'قوم': 'ق و م', 'قوما': 'ق و م',
    'الصلاة': 'ص ل و', 'الصلوة': 'ص ل و', 'صلاة': 'ص ل و', 'يصلون': 'ص ل و',
    'رزقناهم': 'ر ز ق', 'رزق': 'ر ز ق', 'الرزق': 'ر ز ق', 'يرزق': 'ر ز ق',
    'ينفقون': 'ن ف ق', 'انفقوا': 'ن ف ق', 'المنافقين': 'ن ف ق',
    'انزل': 'ن ز ل', 'انزلنا': 'ن ز ل', 'نزل': 'ن ز ل', 'تنزيل': 'ن ز ل',
    'الاخرة': 'ا خ ر', 'اخرة': 'ا خ ر',
    'يوقنون': 'ي ق ن', 'يقين': 'ي ق ن',
    'المفلحون': 'ف ل ح', 'افلح': 'ف ل ح', 'تفلحون': 'ف ل ح',
    'رسول': 'ر س ل', 'الرسول': 'ر س ل', 'رسل': 'ر س ل', 'ارسلنا': 'ر س ل',
    'المرسلين': 'ر س ل', 'رسالة': 'ر س ل',
    'خلق': 'خ ل ق', 'الخالق': 'خ ل ق', 'خلقنا': 'خ ل ق', 'مخلوق': 'خ ل ق',
    'علم': 'ع ل م', 'يعلمون': 'ع ل م', 'تعلمون': 'ع ل م', 'عليم': 'ع ل م',
    'العلم': 'ع ل م', 'اعلم': 'ع ل م', 'معلوم': 'ع ل م',
    'الحق': 'ح ق ق', 'حق': 'ح ق ق', 'يحق': 'ح ق ق',
    'النور': 'ن و ر', 'نور': 'ن و ر', 'النار': 'ن و ر', 'نار': 'ن و ر',
    'الظلمات': 'ظ ل م', 'ظلمات': 'ظ ل م', 'الظالمين': 'ظ ل م',
    'ظلم': 'ظ ل م', 'ظلموا': 'ظ ل م',
    'الجنة': 'ج ن ن', 'جنة': 'ج ن ن', 'جنات': 'ج ن ن', 'الجن': 'ج ن ن',
    'رحمة': 'ر ح م', 'رحمت': 'ر ح م', 'يرحم': 'ر ح م',
    'مغفرة': 'غ ف ر', 'الغفور': 'غ ف ر', 'استغفروا': 'غ ف ر', 'يغفر': 'غ ف ر',
    'تاب': 'ت و ب', 'توبة': 'ت و ب', 'التواب': 'ت و ب', 'توبوا': 'ت و ب',
    'عذاب': 'ع ذ ب', 'العذاب': 'ع ذ ب', 'يعذب': 'ع ذ ب',
    'عمل': 'ع م ل', 'اعمال': 'ع م ل', 'يعملون': 'ع م ل', 'تعملون': 'ع م ل',
    'الصالحات': 'ص ل ح', 'صالح': 'ص ل ح', 'اصلح': 'ص ل ح',
    'قلب': 'ق ل ب', 'قلوب': 'ق ل ب', 'قلوبهم': 'ق ل ب',
    'نفس': 'ن ف س', 'انفسهم': 'ن ف س', 'انفسكم': 'ن ف س', 'النفس': 'ن ف س',
    'سميع': 'س م ع', 'السميع': 'س م ع', 'يسمعون': 'س م ع', 'اسمع': 'س م ع',
    'بصير': 'ب ص ر', 'البصير': 'ب ص ر', 'ابصار': 'ب ص ر', 'يبصرون': 'ب ص ر',
    'يعقلون': 'ع ق ل', 'تعقلون': 'ع ق ل',
    'بينات': 'ب ي ن', 'مبين': 'ب ي ن', 'تبيان': 'ب ي ن', 'بين': 'ب ي ن',
    'حكيم': 'ح ك م', 'الحكيم': 'ح ك م', 'حكمة': 'ح ك م', 'يحكم': 'ح ك م',
    'قدير': 'ق د ر', 'قدر': 'ق د ر', 'يقدر': 'ق د ر', 'مقدار': 'ق د ر',
    'العزيز': 'ع ز ز', 'عزيز': 'ع ز ز', 'عزة': 'ع ز ز',
    'صدق': 'ص د ق', 'الصادقين': 'ص د ق', 'صدقة': 'ص د ق', 'صدقات': 'ص د ق',
    'المشركين': 'ش ر ك', 'شرك': 'ش ر ك', 'اشركوا': 'ش ر ك', 'شركاء': 'ش ر ك',
    'خاسرين': 'خ س ر', 'خسر': 'خ س ر', 'الخاسرين': 'خ س ر',
    'الصابرين': 'ص ب ر', 'اصبروا': 'ص ب ر', 'صبر': 'ص ب ر', 'صابرين': 'ص ب ر',
    'تشكرون': 'ش ك ر', 'اشكروا': 'ش ك ر', 'شاكرين': 'ش ك ر', 'شكور': 'ش ك ر',
    'اذكروا': 'ذ ك ر', 'ذكر': 'ذ ك ر', 'الذكر': 'ذ ك ر', 'يذكرون': 'ذ ك ر',
    'الحياة': 'ح ي ي', 'حياة': 'ح ي ي', 'الحي': 'ح ي ي', 'يحيي': 'ح ي ي',
    'الموت': 'م و ت', 'موت': 'م و ت', 'يميت': 'م و ت', 'ميت': 'م و ت',
    'ادعوا': 'د ع و', 'دعاء': 'د ع و', 'يدعون': 'د ع و', 'دعوة': 'د ع و',
    'امر': 'ا م ر', 'الامر': 'ا م ر', 'يامرون': 'ا م ر', 'امره': 'ا م ر',
    'سبحان': 'س ب ح', 'يسبح': 'س ب ح', 'سبح': 'س ب ح',
    'يخشون': 'خ ش ي', 'خشية': 'خ ش ي',
    'ولي': 'و ل ي', 'اولياء': 'و ل ي', 'مولي': 'و ل ي', 'تولي': 'و ل ي',
    'نصر': 'ن ص ر', 'انصار': 'ن ص ر', 'ينصر': 'ن ص ر',
    'فتح': 'ف ت ح', 'الفاتحة': 'ف ت ح', 'مفاتح': 'ف ت ح',
    'طهور': 'ط ه ر', 'يتطهرون': 'ط ه ر', 'مطهرة': 'ط ه ر',
    'حرام': 'ح ر م', 'الحرام': 'ح ر م', 'حرمات': 'ح ر م',
    'اسلام': 'س ل م', 'الاسلام': 'س ل م', 'مسلمين': 'س ل م', 'سلام': 'س ل م',
    'عدل': 'ع د ل', 'اعدلوا': 'ع د ل', 'يعدلون': 'ع د ل',
    'رحيم': 'ر ح م', 'رحمن': 'ر ح م',
    'قل': 'ق و ل', 'قال': 'ق و ل', 'قالوا': 'ق و ل', 'يقول': 'ق و ل',
    'يقولون': 'ق و ل', 'قول': 'ق و ل', 'القول': 'ق و ل',
    'احد': 'ا ح د', 'الاحد': 'ا ح د', 'واحد': 'ا ح د', 'الواحد': 'ا ح د',
    'الصمد': 'ص م د', 'صمد': 'ص م د',
    'يلد': 'و ل د', 'يولد': 'و ل د', 'ولد': 'و ل د', 'والدين': 'و ل د',
    'الانسان': 'ا ن س', 'انسان': 'ا ن س', 'الناس': 'ا ن س', 'ناس': 'ا ن س',
    'ريب': 'ر ي ب', 'مريب': 'ر ي ب',
    'القيوم': 'ق و م',
    'حي': 'ح ي ي',
    'اله': 'ا ل ه', 'الهكم': 'ا ل ه', 'الهة': 'ا ل ه',
    'خسران': 'خ س ر',
    'السماوات': 'س م و', 'السماء': 'س م و', 'سماء': 'س م و',
    'اسم': 'س م و', 'اسماء': 'س م و',
  };

  /// Function words: they carry meaning by role, not by a trilateral root.
  static const Map<String, String> particles = <String, String>{
    'في': 'Preposition "fī" — in, within. Denotes containment, and in Quranic '
        'usage often immersion rather than mere location.',
    'من': 'Either the preposition "min" (from, part of — marks origin or a '
        'portion) or the relative pronoun "man" (whoever). Context decides.',
    'الي': 'Preposition "ilā" — toward, up to. Marks the end point of a motion.',
    'علي': 'Preposition "ʿalā" — upon, over. Often implies obligation or '
        'dominance resting on something.',
    'عن': 'Preposition "ʿan" — away from, about. Carries a sense of departure '
        'or distance.',
    'مع': 'Preposition "maʿa" — with, in company of; togetherness in time or '
        'support.',
    'ان': 'Either "inna" (verily — an emphasis particle), "an" (that), or "in" '
        '(if). One of the most context-sensitive words in the Quran.',
    'لا': 'Negation particle "lā" — no / not. Used for absolute negation and '
        'for prohibition.',
    'ما': 'Either negation ("mā" — not) or the relative "what". Its ambiguity '
        'is often used for rhetorical breadth.',
    'لم': 'Negation "lam" — did not; negates a verb and shifts it to the past.',
    'لن': 'Negation "lan" — will never; emphatic negation of the future.',
    'قد': 'Particle "qad" — with the past tense it confirms ("indeed"), with '
        'the present it means "sometimes / may".',
    'ثم': 'Conjunction "thumma" — then, after an interval. Implies a gap in '
        'time or rank, unlike "fa" which is immediate.',
    'بل': 'Particle "bal" — rather, on the contrary; retracts what preceded.',
    'او': 'Conjunction "aw" — or; presents alternatives.',
    'هل': 'Interrogative "hal" — introduces a yes/no question.',
    'كل': 'Quantifier "kull" — every, all; totality without exception.',
    'الذي': 'Relative pronoun "alladhī" — the one who / which (masc. sing.).',
    'الذين': 'Relative pronoun "alladhīna" — those who (masc. plural).',
    'التي': 'Relative pronoun "allatī" — she who / which (fem. sing.).',
    'ذلك': 'Demonstrative "dhālika" — that (distant). Distance can signal '
        'elevation and honour, not just remoteness.',
    'هذا': 'Demonstrative "hādhā" — this (near).',
    'هو': 'Pronoun "huwa" — he / it.',
    'هي': 'Pronoun "hiya" — she / it.',
    'هم': 'Pronoun "hum" — they (masc. plural).',
    'نحن': 'Pronoun "naḥnu" — we. Used of God as the plural of majesty.',
    'انت': 'Pronoun "anta / anti" — you (singular).',
    'اياك': 'Detached object pronoun "iyyāka" — "You alone". Fronting it before '
        'the verb creates exclusivity: You, and no one else.',
    'الا': 'Exceptive "illā" — except, unless. Together with a preceding '
        'negation it forms the strongest affirmation in Arabic.',
    'حتي': 'Particle "ḥattā" — until, even; marks a limit or an extreme case.',
    'لو': 'Conditional "law" — if (counterfactual); supposes what did not '
        'happen.',
    'اذا': 'Conditional "idhā" — when (for what is expected to occur).',
    'كان': 'Verb "kāna" — was / used to be; often expresses a permanent '
        'attribute rather than a past event.',
    'غير': 'Noun "ghayr" — other than; excludes what follows it.',
    'بعد': 'Adverb "baʿd" — after; also "distance" from the same letters.',
    'قبل': 'Adverb "qabl" — before.',
    'عند': 'Adverb "ʿinda" — with, in the presence of; implies proximity and '
        'possession.',
    'مما': 'Contraction of "min" + "mā" — "from that which". Marks a part '
        'taken out of a whole.',
    'كما': 'Particle "kamā" — just as, in the same way that; draws a '
        'comparison.',
    'لكن': 'Particle "lākin" — but, however; corrects the expectation raised '
        'by what came before.',
    'اذ': 'Particle "idh" — when, at the time that (for past events); often '
        'opens a scene the listener is asked to recall.',
    'لما': 'Particle "lammā" — when / not yet, depending on what follows.',
    'ايها': 'Vocative "ayyuhā" — O! Used with "yā" to call an audience '
        'directly.',
    'يا': 'Vocative particle "yā" — O; opens direct address.',
    'وما': 'Conjunction "wa" + "mā" — and what / and not.',
    'انما': 'Particle "innamā" — restrictive: "none other than", "only".',
    'الم': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'الر': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'المص': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'المر': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'كهيعص': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'طه': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'طسم': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'طس': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'يس': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'حم': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'عسق': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'ص': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'ق': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
    'ن': 'Ḥurūf muqaṭṭaʿāt — one of the disconnected letter-openings of certain '
        'surahs. They are recited as individual letter names. The majority of '
        'the salaf held their full meaning to be known to Allah alone; many '
        'scholars note they draw attention to the very letters Arabic itself '
        'is built from, immediately before the challenge to produce its like.',
  };

  static RootEntry? entryForRoot(String root) => roots[root];

  static String? rootForSurface(String normalizedSurface) =>
      surfaceIndex[normalizedSurface];

  static String? particleNote(String normalizedSurface) =>
      particles[normalizedSurface];

  static int get rootCount => roots.length;
}
