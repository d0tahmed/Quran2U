// lib/data/quran_theme_index.dart
//
// Concept index for offline meaning-based search.
//
// Each entry maps a human theme to the ayat the tradition most consistently
// cites for it, plus the vocabulary a person might actually type. The index
// stores *verse keys only* — the Arabic and translation are fetched (and
// cached) by QuranSearchService, so a debatable thematic grouping can never
// cause the wrong text to be displayed.
//
// This is a curated starting point, not an exhaustive concordance. Extending
// it is purely additive: append a QuranTheme and it becomes searchable.

import 'package:flutter/foundation.dart';

@immutable
class QuranTheme {
  final String id;
  final String title;

  /// One line shown under the title in results.
  final String blurb;

  /// Words and phrases a user might type. Lowercase, no punctuation.
  final List<String> keywords;

  /// Verse keys, "surah:ayah". Ranges are written out individually.
  final List<String> verses;

  const QuranTheme({
    required this.id,
    required this.title,
    required this.blurb,
    required this.keywords,
    required this.verses,
  });
}

const List<QuranTheme> kQuranThemes = <QuranTheme>[
  QuranTheme(
    id: 'patience',
    title: 'Patience in hardship',
    blurb: 'Ṣabr — restraint and endurance when tested',
    keywords: [
      'patience', 'patient', 'sabr', 'endure', 'endurance', 'hardship',
      'difficulty', 'difficult', 'struggle', 'suffering', 'trial', 'test',
      'tested', 'persevere', 'perseverance', 'hold on', 'tough times',
      'going through', 'pain',
    ],
    verses: ['2:153', '2:155', '2:156', '2:157', '2:286', '3:200', '39:10',
      '94:5', '94:6', '65:2', '65:3'],
  ),
  QuranTheme(
    id: 'anxiety',
    title: 'Anxiety and peace of heart',
    blurb: 'Stillness of the heart, and relief from worry',
    keywords: [
      'anxiety', 'anxious', 'worry', 'worried', 'stress', 'stressed',
      'depression', 'depressed', 'sad', 'sadness', 'grief', 'grieve',
      'overwhelmed', 'peace', 'calm', 'comfort', 'heart at rest', 'panic',
      'fear of future', 'lonely', 'loneliness',
    ],
    verses: ['13:28', '2:286', '65:3', '94:5', '94:6', '9:40', '3:139'],
  ),
  QuranTheme(
    id: 'forgiveness',
    title: 'Forgiveness and repentance',
    blurb: 'Turning back, and the mercy that meets it',
    keywords: [
      'forgive', 'forgiveness', 'forgiven', 'repent', 'repentance', 'tawbah',
      'sin', 'sins', 'sinner', 'guilt', 'guilty', 'mistake', 'mistakes',
      'regret', 'ashamed', 'shame', 'second chance', 'started over',
      'astaghfirullah', 'mercy for sinners',
    ],
    verses: ['39:53', '3:135', '2:222', '66:8', '4:110', '24:22', '4:17'],
  ),
  QuranTheme(
    id: 'parents',
    title: 'Parents',
    blurb: 'The duty of kindness to mother and father',
    keywords: [
      'parents', 'parent', 'mother', 'father', 'mum', 'mom', 'dad',
      'family duty', 'respect parents', 'obey parents', 'elderly parents',
      'birr', 'ihsan to parents',
    ],
    verses: ['17:23', '17:24', '31:14', '46:15', '4:36'],
  ),
  QuranTheme(
    id: 'charity',
    title: 'Charity and spending',
    blurb: 'What is given away, and what it grows into',
    keywords: [
      'charity', 'sadaqah', 'zakat', 'giving', 'give', 'donate', 'donation',
      'spend', 'spending', 'generous', 'generosity', 'help the poor', 'alms',
      'wealth sharing',
    ],
    verses: ['2:261', '2:267', '2:274', '57:18', '63:10', '2:177'],
  ),
  QuranTheme(
    id: 'gratitude',
    title: 'Gratitude',
    blurb: 'Shukr — and the increase promised to it',
    keywords: [
      'gratitude', 'grateful', 'thankful', 'thanks', 'shukr', 'blessings',
      'count blessings', 'appreciate', 'ungrateful', 'alhamdulillah',
    ],
    verses: ['14:7', '2:152', '27:40', '31:12', '16:18'],
  ),
  QuranTheme(
    id: 'prayer',
    title: 'Prayer',
    blurb: 'Ṣalāh as help, as remembrance, as a shield',
    keywords: [
      'prayer', 'pray', 'salah', 'salat', 'namaz', 'worship', 'establish prayer',
      'khushu', 'concentration in prayer', 'missed prayers', 'five prayers',
    ],
    verses: ['2:45', '20:14', '29:45', '4:103', '23:1', '23:2', '107:4', '107:5'],
  ),
  QuranTheme(
    id: 'dua',
    title: 'Supplication',
    blurb: 'Calling on God, and the promise to answer',
    keywords: [
      'dua', 'supplication', 'ask allah', 'asking god', 'invocation', 'pray for',
      'answered prayer', 'unanswered', 'call upon', 'beg',
    ],
    verses: ['2:186', '40:60', '7:55', '21:87', '21:88'],
  ),
  QuranTheme(
    id: 'dhikr',
    title: 'Remembrance of God',
    blurb: 'Dhikr — the hearts find rest in it',
    keywords: [
      'dhikr', 'zikr', 'remembrance', 'remember allah', 'tasbih', 'meditation',
      'mindfulness', 'presence of god',
    ],
    verses: ['13:28', '33:41', '2:152', '3:191'],
  ),
  QuranTheme(
    id: 'trust',
    title: 'Trust in God',
    blurb: 'Tawakkul — acting, then relying',
    keywords: [
      'trust', 'tawakkul', 'rely', 'reliance', 'depend on god', 'surrender',
      'let go', 'leave it to allah', 'sufficient', 'hasbunallah',
      'uncertain future', 'plan',
    ],
    verses: ['65:3', '3:159', '3:173', '8:2', '9:51', '11:88'],
  ),
  QuranTheme(
    id: 'death',
    title: 'Death and the Hereafter',
    blurb: 'Every soul shall taste it',
    keywords: [
      'death', 'die', 'died', 'dying', 'dead', 'mortality', 'afterlife',
      'hereafter', 'akhirah', 'grave', 'soul leaves', 'lost someone',
      'passed away', 'bereavement', 'funeral', 'temporary world', 'mourning',
      'loss of a loved one',
    ],
    verses: ['3:185', '21:35', '67:2', '62:8', '29:57'],
  ),
  QuranTheme(
    id: 'judgment',
    title: 'The Day of Judgement',
    blurb: 'The reckoning, weighed to the atom',
    keywords: [
      'judgement', 'judgment', 'day of judgement', 'qiyamah', 'resurrection',
      'reckoning', 'accountability', 'accounted', 'scales', 'weighed',
      'end of the world', 'last day',
    ],
    verses: ['99:1', '99:7', '99:8', '101:6', '101:7', '82:1', '17:13', '17:14'],
  ),
  QuranTheme(
    id: 'paradise',
    title: 'Paradise',
    blurb: 'Jannah and what is promised in it',
    keywords: [
      'paradise', 'jannah', 'heaven', 'gardens', 'reward', 'eternal life',
      'rivers beneath',
    ],
    verses: ['2:25', '13:35', '47:15', '3:133', '9:72'],
  ),
  QuranTheme(
    id: 'hellfire',
    title: 'The Fire',
    blurb: 'Warning, and what it is fuelled by',
    keywords: [
      'hell', 'hellfire', 'jahannam', 'fire', 'punishment', 'torment',
      'consequences of sin',
    ],
    verses: ['2:24', '66:6', '104:4', '104:5'],
  ),
  QuranTheme(
    id: 'justice',
    title: 'Justice',
    blurb: 'Standing firm even against yourself',
    keywords: [
      'justice', 'just', 'fair', 'fairness', 'injustice', 'unjust', 'equity',
      'testimony', 'witness', 'oppression', 'oppressed', 'rights', 'corruption',
      'bias', 'discrimination',
    ],
    verses: ['4:135', '5:8', '16:90', '4:58', '42:42'],
  ),
  QuranTheme(
    id: 'knowledge',
    title: 'Knowledge and learning',
    blurb: 'The command to read, and the rank of the learned',
    keywords: [
      'knowledge', 'learn', 'learning', 'study', 'education', 'science',
      'wisdom', 'read', 'ignorance', 'scholars', 'seek knowledge', 'student',
      'exam', 'understanding',
    ],
    verses: ['20:114', '39:9', '58:11', '96:1', '96:2', '96:3', '96:4', '96:5'],
  ),
  QuranTheme(
    id: 'time',
    title: 'Time and loss',
    blurb: 'By time — humanity is in loss',
    keywords: [
      'time', 'wasting time', 'productivity', 'procrastination', 'life is short',
      'asr', 'hours', 'youth',
    ],
    verses: ['103:1', '103:2', '103:3'],
  ),
  QuranTheme(
    id: 'creation',
    title: 'Creation and the signs',
    blurb: 'The universe as evidence for those who reflect',
    keywords: [
      'creation', 'created', 'universe', 'cosmos', 'sky', 'heavens', 'earth',
      'nature', 'stars', 'science', 'big bang', 'expanding', 'signs',
      'reflect', 'ponder', 'think', 'evidence', 'proof of god',
    ],
    verses: ['3:190', '3:191', '21:30', '51:47', '30:22', '2:164'],
  ),
  QuranTheme(
    id: 'human_origin',
    title: 'The making of the human being',
    blurb: 'From clay, from a drop, in stages',
    keywords: [
      'human', 'humanity', 'mankind', 'embryo', 'womb', 'conception', 'clay',
      'created man', 'biology', 'stages of creation', 'birth',
    ],
    verses: ['23:12', '23:13', '23:14', '32:7', '32:8', '32:9', '96:2'],
  ),
  QuranTheme(
    id: 'tawhid',
    title: 'The oneness of God',
    blurb: 'Tawḥīd — nothing comparable to Him',
    keywords: [
      'oneness', 'tawhid', 'monotheism', 'one god', 'who is allah',
      'who is god', 'what is allah like', 'describe allah', 'ikhlas',
      'ayat al kursi', 'ayatul kursi', 'throne verse', 'attributes of god',
      'names of allah', 'shirk', 'idols',
    ],
    verses: ['112:1', '112:2', '112:3', '112:4', '2:255', '59:22', '59:23',
      '59:24'],
  ),
  QuranTheme(
    id: 'mercy',
    title: 'The mercy of God',
    blurb: 'A mercy that encompasses all things',
    keywords: [
      'mercy', 'merciful', 'rahmah', 'compassion', 'kindness of god',
      'does allah love me', 'hope in allah',
    ],
    verses: ['7:156', '39:53', '6:12', '6:54'],
  ),
  QuranTheme(
    id: 'guidance',
    title: 'Guidance',
    blurb: 'Asking for the straight path',
    keywords: [
      'guidance', 'guide', 'guided', 'straight path', 'sirat', 'lost',
      'direction', 'confused', 'purpose', 'meaning of life', 'why am i here',
      'misguided',
    ],
    verses: ['1:6', '1:7', '2:2', '2:185', '6:125'],
  ),
  QuranTheme(
    id: 'quran',
    title: 'The Quran itself',
    blurb: 'Its preservation, and its ease for remembrance',
    keywords: [
      'quran', 'the quran', 'holy quran', 'about the quran', 'reading quran',
      'book', 'revelation', 'scripture', 'preserved', 'memorise',
      'memorize', 'hifz', 'recite', 'healing', 'guidance book',
    ],
    verses: ['15:9', '54:17', '17:9', '17:82', '2:2'],
  ),
  QuranTheme(
    id: 'speech',
    title: 'Speech and the tongue',
    blurb: 'Say what is best, or stay silent',
    keywords: [
      'speech', 'speak', 'talking', 'tongue', 'words', 'what you say',
      'lying', 'lie', 'truthful', 'honest', 'honesty', 'gossip', 'backbiting',
      'slander', 'mocking', 'insult', 'nickname', 'suspicion', 'rumours',
    ],
    verses: ['33:70', '17:53', '49:11', '49:12', '9:119'],
  ),
  QuranTheme(
    id: 'anger',
    title: 'Anger and restraint',
    blurb: 'Repel with what is better',
    keywords: [
      'anger', 'angry', 'rage', 'temper', 'restrain', 'forgive people',
      'pardon', 'revenge', 'grudge', 'conflict', 'argument', 'fight',
      'enemy became friend',
    ],
    verses: ['3:134', '41:34', '42:37', '7:199'],
  ),
  QuranTheme(
    id: 'humility',
    title: 'Humility and arrogance',
    blurb: 'Walking gently, and the fall of pride',
    keywords: [
      'humility', 'humble', 'arrogance', 'arrogant', 'pride', 'proud',
      'ego', 'showing off', 'boast', 'look down on others', 'kibr',
    ],
    verses: ['31:18', '25:63', '17:37', '7:146', '28:83'],
  ),
  QuranTheme(
    id: 'marriage',
    title: 'Marriage and spouses',
    blurb: 'Tranquillity, affection and mercy between them',
    keywords: [
      'marriage', 'married', 'spouse', 'wife', 'husband', 'nikah', 'love',
      'partner', 'divorce', 'relationship', 'garment for one another',
    ],
    verses: ['30:21', '4:19', '2:187', '4:1'],
  ),
  QuranTheme(
    id: 'children',
    title: 'Children and family',
    blurb: 'An adornment, and a trust',
    keywords: [
      'children', 'child', 'kids', 'son', 'daughter', 'offspring', 'family',
      'raising children', 'protect your family', 'infertility', 'pregnancy',
    ],
    verses: ['18:46', '25:74', '66:6', '42:49', '42:50'],
  ),
  QuranTheme(
    id: 'orphans',
    title: 'Orphans and the vulnerable',
    blurb: 'Do not repel the one who asks',
    keywords: [
      'orphan', 'orphans', 'vulnerable', 'weak', 'poor', 'needy', 'homeless',
      'beggar', 'destitute', 'refugee', 'helping others',
    ],
    verses: ['93:9', '93:10', '4:2', '107:2', '107:3', '2:177'],
  ),
  QuranTheme(
    id: 'provision',
    title: 'Provision and sustenance',
    blurb: 'Rizq — apportioned, and sought',
    keywords: [
      'provision', 'rizq', 'sustenance', 'money', 'income', 'job', 'work',
      'unemployed', 'poverty', 'poor', 'rich', 'wealth', 'salary', 'business',
      'financial', 'debt', 'bills', 'struggling financially',
    ],
    verses: ['51:22', '65:7', '42:27', '17:31', '11:6'],
  ),
  QuranTheme(
    id: 'riba',
    title: 'Interest and unjust gain',
    blurb: 'The prohibition of ribā',
    keywords: [
      'interest', 'riba', 'usury', 'loan', 'mortgage', 'bank', 'haram money',
      'debt contract', 'lending',
    ],
    verses: ['2:275', '2:276', '2:278', '2:279', '2:282'],
  ),
  QuranTheme(
    id: 'intoxicants',
    title: 'Intoxicants and gambling',
    blurb: 'Defilement from the work of Satan',
    keywords: [
      'alcohol', 'wine', 'drink', 'drunk', 'intoxicant', 'khamr', 'gambling',
      'bet', 'betting', 'lottery', 'drugs', 'addiction',
    ],
    verses: ['5:90', '5:91', '2:219'],
  ),
  QuranTheme(
    id: 'modesty',
    title: 'Modesty',
    blurb: 'Lowering the gaze, guarding oneself',
    keywords: [
      'modesty', 'modest', 'hijab', 'veil', 'cover', 'lower gaze', 'chastity',
      'zina', 'temptation', 'dress', 'awrah', 'haya',
    ],
    verses: ['24:30', '24:31', '33:59', '17:32'],
  ),
  QuranTheme(
    id: 'satan',
    title: 'Satan and temptation',
    blurb: 'A clear enemy — take him as one',
    keywords: [
      'satan', 'shaytan', 'devil', 'iblis', 'whispers', 'waswas', 'temptation',
      'evil thoughts', 'tempted', 'seek refuge',
    ],
    verses: ['2:168', '35:6', '7:200', '14:22', '114:1', '114:4'],
  ),
  QuranTheme(
    id: 'hypocrisy',
    title: 'Hypocrisy',
    blurb: 'A sickness in the heart',
    keywords: [
      'hypocrisy', 'hypocrite', 'munafiq', 'two faced', 'fake', 'insincere',
      'pretending', 'riya', 'showing off worship',
    ],
    verses: ['2:8', '2:9', '2:10', '4:142', '107:4', '107:6'],
  ),
  QuranTheme(
    id: 'brotherhood',
    title: 'Unity and brotherhood',
    blurb: 'Hold fast together, and do not divide',
    keywords: [
      'unity', 'united', 'brotherhood', 'community', 'ummah', 'division',
      'sect', 'sectarianism', 'reconcile', 'reconciliation', 'making peace',
      'friendship', 'friends',
    ],
    verses: ['3:103', '49:10', '49:13', '8:46'],
  ),
  QuranTheme(
    id: 'fasting',
    title: 'Fasting and Ramadan',
    blurb: 'Prescribed so that you may attain taqwā',
    keywords: [
      'fasting', 'fast', 'ramadan', 'sawm', 'roza', 'iftar', 'suhoor',
      'laylatul qadr', 'night of decree', 'taraweeh',
    ],
    verses: ['2:183', '2:184', '2:185', '2:187', '97:1', '97:3'],
  ),
  QuranTheme(
    id: 'hajj',
    title: 'Hajj and pilgrimage',
    blurb: 'The house, and the call to it',
    keywords: [
      'hajj', 'pilgrimage', 'umrah', 'kaaba', 'makkah', 'mecca', 'tawaf',
      'ihram', 'arafah',
    ],
    verses: ['2:197', '3:97', '22:27', '2:127'],
  ),
  QuranTheme(
    id: 'struggle',
    title: 'Striving in God’s cause',
    blurb: 'Those who strive — He guides to His ways',
    keywords: [
      'struggle', 'strive', 'striving', 'jihad', 'effort', 'sacrifice',
      'giving up comfort', 'discipline', 'self control', 'nafs',
    ],
    verses: ['29:69', '22:78', '9:20', '79:40', '79:41'],
  ),
  QuranTheme(
    id: 'hope',
    title: 'Hope and despair',
    blurb: 'Never despair of the mercy of God',
    keywords: [
      'hope', 'hopeless', 'despair', 'give up', 'gave up', 'no way out',
      'rock bottom', 'suicidal thoughts', 'darkness', 'nothing left',
    ],
    verses: ['39:53', '12:87', '15:56', '94:5', '94:6', '65:2', '65:3'],
  ),
  QuranTheme(
    id: 'healing',
    title: 'Illness and healing',
    blurb: 'And when I am ill, it is He who cures me',
    keywords: [
      'sick', 'sickness', 'illness', 'ill', 'disease', 'cancer', 'pain',
      'hospital', 'heal', 'healing', 'cure', 'shifa', 'recovery', 'health',
    ],
    verses: ['26:80', '17:82', '10:57', '21:83', '21:84'],
  ),
  QuranTheme(
    id: 'prophet_muhammad',
    title: 'The Prophet Muhammad ﷺ',
    blurb: 'An excellent example, a mercy to the worlds',
    keywords: [
      'prophet', 'muhammad', 'messenger', 'rasul', 'sunnah', 'example',
      'mercy to the worlds', 'character of the prophet', 'follow the prophet',
    ],
    verses: ['33:21', '21:107', '68:4', '3:31'],
  ),
  QuranTheme(
    id: 'musa',
    title: 'Musa (Moses)',
    blurb: 'Pharaoh, the staff, and the parting of the sea',
    keywords: [
      'musa', 'moses', 'pharaoh', 'firaun', 'egypt', 'staff', 'sea parted',
      'expand my chest', 'rabbi shrah',
    ],
    verses: ['20:25', '20:26', '20:27', '20:28', '28:24', '26:62'],
  ),
  QuranTheme(
    id: 'yusuf',
    title: 'Yusuf (Joseph)',
    blurb: 'The well, the prison, the reunion',
    keywords: [
      'yusuf', 'joseph', 'brothers betrayed', 'jealousy', 'dream',
      'interpretation', 'prison', 'beautiful patience', 'reunion',
    ],
    verses: ['12:18', '12:87', '12:90', '12:101'],
  ),
  QuranTheme(
    id: 'yunus',
    title: 'Yunus (Jonah)',
    blurb: 'The call from within the darknesses',
    keywords: [
      'yunus', 'jonah', 'whale', 'fish', 'darkness', 'la ilaha illa anta',
      'dua of yunus', 'trapped',
    ],
    verses: ['21:87', '21:88', '37:143', '37:144'],
  ),
  QuranTheme(
    id: 'ibrahim',
    title: 'Ibrahim (Abraham)',
    blurb: 'The friend of God, and the building of the House',
    keywords: [
      'ibrahim', 'abraham', 'idols', 'fire cool', 'sacrifice', 'ismail',
      'building the kaaba', 'khalil',
    ],
    verses: ['2:127', '14:35', '14:37', '14:40', '21:69'],
  ),
  QuranTheme(
    id: 'maryam',
    title: 'Maryam (Mary)',
    blurb: 'Chosen and purified above the women of the worlds',
    keywords: [
      'maryam', 'mary', 'virgin', 'birth of isa', 'palm tree', 'chosen woman',
      'women in the quran',
    ],
    verses: ['19:16', '19:19', '19:23', '19:25', '3:42'],
  ),
  QuranTheme(
    id: 'isa',
    title: 'Isa (Jesus)',
    blurb: 'A servant of God, given the Scripture',
    keywords: [
      'isa', 'jesus', 'christ', 'messiah', 'christians', 'son of mary',
      'crucifixion', 'trinity',
    ],
    verses: ['19:30', '19:31', '19:32', '19:33', '3:45', '4:171'],
  ),
  QuranTheme(
    id: 'people_of_book',
    title: 'Other faiths and dialogue',
    blurb: 'No compulsion, and arguing in the best way',
    keywords: [
      'christian', 'christians', 'jew', 'jews', 'people of the book',
      'other religions', 'non muslim', 'interfaith', 'dialogue', 'tolerance',
      'no compulsion', 'freedom of religion', 'dawah',
    ],
    verses: ['2:256', '29:46', '16:125', '109:6', '5:48'],
  ),
  QuranTheme(
    id: 'travel',
    title: 'Travel and migration',
    blurb: 'The earth is spacious — migrate in it',
    keywords: [
      'travel', 'journey', 'migration', 'hijrah', 'move abroad', 'emigrate',
      'immigrant', 'leaving home', 'expatriate', 'refugee',
    ],
    verses: ['4:100', '29:56', '39:10', '2:184'],
  ),
  QuranTheme(
    id: 'night',
    title: 'Night, sleep and rest',
    blurb: 'Sleep as rest, night as a covering',
    keywords: [
      'night', 'sleep', 'sleeping', 'asleep', 'insomnia', 'rest', 'resting',
      'tired', 'exhausted', 'nap', 'dreams', 'restless', 'tahajjud', 'qiyam',
      'dawn', 'wake up', 'cannot sleep', 'day and night',
      'night rest', 'sleep is a sign',
    ],
    verses: ['78:9', '78:10', '78:11', '25:47', '17:79', '73:6', '30:23',
      '39:42', '6:60', '8:11', '3:154'],
  ),
  QuranTheme(
    id: 'envy',
    title: 'Envy and comparison',
    blurb: 'Do not wish for what others were given',
    keywords: [
      'envy', 'envious', 'jealous', 'jealousy', 'hasad', 'comparison',
      'social media', 'others have more', 'evil eye', 'resentment',
      'contentment', 'content',
    ],
    verses: ['4:32', '113:5', '20:131', '15:88'],
  ),
  QuranTheme(
    id: 'world',
    title: 'This world and its distractions',
    blurb: 'Play and amusement, and the abode that lasts',
    keywords: [
      'dunya', 'worldly', 'materialism', 'distraction', 'entertainment',
      'wealth and children', 'competition', 'status', 'fame', 'temporary',
      'chasing money',
    ],
    verses: ['57:20', '102:1', '102:2', '18:45', '29:64'],
  ),
  QuranTheme(
    id: 'oppression',
    title: 'Oppression and tyranny',
    blurb: 'God is not unaware of what the wrongdoers do',
    keywords: [
      'oppression', 'oppressor', 'tyrant', 'tyranny', 'genocide', 'war',
      'persecution', 'injustice of rulers', 'palestine', 'occupied',
      'wrongdoers', 'zalim',
    ],
    verses: ['14:42', '42:42', '4:75', '22:39', '28:5'],
  ),
  QuranTheme(
    id: 'promise',
    title: 'Promises, contracts and trust',
    blurb: 'Fulfil the covenant — it will be asked about',
    keywords: [
      'promise', 'contract', 'agreement', 'covenant', 'trust', 'amanah',
      'betrayal', 'keeping your word', 'oath', 'business deal', 'honesty at work',
    ],
    verses: ['17:34', '5:1', '4:58', '23:8', '83:1', '83:3'],
  ),
  // ── Marriage, family and the body ─────────────────────────────────────────
  //
  // A note on scope, because these are the themes people search when they need
  // a real answer: the Qur'an addresses some of this directly and leaves much
  // of the detail to hadith and fiqh. Menstruation, for instance, is named in
  // exactly one passage (2:222) plus two places where the cycle appears in a
  // ruling — everything about prayer and fasting during it comes from the
  // Sunnah, not from these ayat. The index points at the text; it is not a
  // fatwa, and the disclaimer in the results list says so.

  QuranTheme(
    id: 'menstruation',
    title: 'Menstruation and the monthly cycle',
    blurb: 'The one passage that addresses it, and where the cycle appears in rulings',
    keywords: [
      'menstruation', 'menstrual', 'menses', 'period', 'periods', 'monthly cycle',
      'my cycle', 'on my period', 'time of the month', 'haid', 'haidh', 'hayd',
      'haiz', 'bleeding', 'women impurity', 'during menses', 'intimacy during period',
    ],
    verses: ['2:222', '2:223', '2:228', '65:4'],
  ),
  QuranTheme(
    id: 'purity',
    title: 'Purity, wudu and ghusl',
    blurb: 'Washing before prayer, and what to do when there is no water',
    keywords: [
      'wudu', 'wudhu', 'ablution', 'ghusl', 'purity', 'purification', 'purify',
      'clean', 'cleanliness', 'taharah', 'tayammum', 'janabah', 'ritual bath',
      'shower before prayer', 'no water', 'broke my wudu', 'washing',
    ],
    verses: ['5:6', '4:43', '2:222', '9:108', '74:4', '8:11'],
  ),
  QuranTheme(
    id: 'marital_love',
    title: 'Love between husband and wife',
    blurb: 'Sakinah, mawaddah and rahmah — and living together in kindness',
    keywords: [
      'husband and wife', 'marital love', 'love my wife', 'love my husband',
      'how to treat my wife', 'how to treat my husband', 'be a good husband',
      'be a good wife', 'good spouse', 'treat', 'affection', 'intimacy',
      'romance', 'tenderness', 'marriage advice', 'rights of a wife',
      'rights of a husband', 'sakinah', 'mawaddah', 'garment for one another',
      'tranquility in marriage', 'kindness to spouse', 'married life',
    ],
    verses: ['30:21', '2:187', '4:19', '4:21', '2:228', '25:74', '7:189',
      '9:71', '24:32'],
  ),
  QuranTheme(
    id: 'marital_conflict',
    title: 'When a marriage is strained',
    blurb: 'Arbitration, reconciliation, and parting without cruelty',
    keywords: [
      'marriage problems', 'marital conflict', 'fighting with my wife',
      'fighting with my husband', 'argument with my spouse', 'reconcile',
      'reconciliation', 'save my marriage', 'thinking of divorce', 'arbitration',
      'unhappy marriage', 'separation', 'trouble at home', 'nushuz',
      'falling apart', 'growing apart', 'drifting apart', 'we keep fighting',
    ],
    verses: ['4:35', '4:128', '4:19', '2:229', '2:231', '4:130', '65:2'],
  ),
  QuranTheme(
    id: 'divorce',
    title: 'Divorce done with dignity',
    blurb: 'Retain in kindness or release with good treatment',
    keywords: [
      'divorce', 'divorced', 'divorcing', 'talaq', 'khula', 'iddah',
      'waiting period', 'ending a marriage', 'ex wife', 'ex husband',
      'remarry', 'maintenance', 'mahr after divorce', 'custody', 'split up',
    ],
    verses: ['2:229', '2:231', '2:232', '2:236', '2:237', '2:241', '65:1',
      '65:2', '65:6', '65:7', '33:49', '4:130'],
  ),
  QuranTheme(
    id: 'pregnancy',
    title: 'Pregnancy, birth and nursing',
    blurb: 'Carried in weakness upon weakness',
    keywords: [
      'pregnant', 'pregnancy', 'expecting', 'expecting a baby', 'giving birth',
      'childbirth', 'labour', 'labor', 'in the womb', 'womb', 'newborn', 'baby',
      'breastfeeding', 'nursing', 'weaning', 'two years', 'stages of creation',
      'morning sickness', 'due date',
    ],
    verses: ['31:14', '46:15', '2:233', '22:5', '23:12', '23:13', '23:14',
      '39:6', '16:78', '19:23', '65:6'],
  ),
  QuranTheme(
    id: 'infertility',
    title: 'Longing for a child',
    blurb: 'The prayers of those who waited, and the One who gives or withholds',
    keywords: [
      'infertility', 'infertile', 'cannot have children', 'no children',
      'childless', 'barren', 'trying to conceive', 'trying for a baby',
      'want a baby', 'ivf', 'miscarriage', 'dua for a child',
      'waiting for a child', 'cannot get pregnant', 'cant get pregnant',
      'not getting pregnant', 'struggling to conceive',
      'still no children',
    ],
    verses: ['42:49', '42:50', '3:38', '3:39', '3:40', '19:4', '19:5', '19:8',
      '21:89', '21:90', '11:72', '51:29'],
  ),
  QuranTheme(
    id: 'women',
    title: 'Women, dignity and rights',
    blurb: 'Named alongside men in reward, and defended where they were wronged',
    keywords: [
      'women', 'woman', 'women rights', 'rights of women', 'status of women',
      'girls', 'daughters', 'female', 'equality', 'men and women', 'sisters',
      'baby girl', 'daughters are a blessing', 'how islam sees women',
    ],
    verses: ['4:1', '4:19', '4:32', '4:124', '9:71', '16:97', '33:35', '49:13',
      '16:58', '16:59', '81:8', '81:9', '60:12'],
  ),
  QuranTheme(
    id: 'chastity',
    title: 'Chastity and lowering the gaze',
    blurb: 'Guarding oneself, and the story of the one who refused',
    keywords: [
      'chastity', 'chaste', 'zina', 'adultery', 'fornication', 'lower the gaze',
      'lust', 'desire', 'temptation', 'pornography', 'haram relationship',
      'girlfriend', 'boyfriend', 'dating', 'affair', 'cheating on my spouse',
      'guard yourself', 'resist',
    ],
    verses: ['17:32', '24:2', '24:30', '24:31', '24:33', '25:68', '23:5',
      '23:6', '23:7', '33:35', '70:29', '70:30', '12:23', '12:24', '12:33'],
  ),
  QuranTheme(
    id: 'privacy',
    title: 'Privacy in the home',
    blurb: 'Ask permission and greet before you enter',
    keywords: [
      'privacy', 'private', 'permission', 'knock', 'entering a house',
      'someone else house', 'personal space', 'bedroom', 'spying', 'puberty',
      'teenager', 'coming of age', 'maturity', 'boundaries at home',
    ],
    verses: ['24:27', '24:28', '24:58', '24:59', '33:53', '49:12', '4:6'],
  ),

  // ── Everyday life ─────────────────────────────────────────────────────────

  QuranTheme(
    id: 'inheritance',
    title: 'Inheritance and wills',
    blurb: 'Fixed shares, and a bequest made before they are counted',
    keywords: [
      'inheritance', 'inherit', 'inherited', 'estate', 'heirs', 'my will',
      'a will', 'last will', 'write a will', 'leaving a will', 'his will',
      'faraid', 'wirathah', 'dividing property', 'my share', 'left behind',
      'bequest', 'testament',
    ],
    verses: ['4:7', '4:8', '4:11', '4:12', '4:33', '4:176', '2:180', '5:106'],
  ),
  QuranTheme(
    id: 'debt',
    title: 'Debt, lending and writing it down',
    blurb: 'Give time to one in difficulty — and put the agreement in writing',
    keywords: [
      'debt', 'debts', 'loan', 'loans', 'borrow', 'borrowing', 'lend', 'lending',
      'owe', 'owed', 'repay', 'cannot pay', 'in debt', 'write it down',
      'witness', 'mortgage', 'credit', 'goodly loan', 'qard hasan',
    ],
    verses: ['2:280', '2:282', '2:283', '2:245', '4:29', '57:11', '64:17'],
  ),
  QuranTheme(
    id: 'food',
    title: 'What is lawful to eat',
    blurb: 'Eat of the good and lawful, and do not be excessive',
    keywords: [
      'halal', 'haram', 'food', 'eat', 'eating', 'meat', 'pork', 'pig', 'blood',
      'slaughter', 'dhabiha', 'zabiha', 'lawful food', 'forbidden food',
      'what can i eat', 'is it halal', 'gelatin', 'diet', 'overeating',
    ],
    verses: ['2:168', '2:172', '2:173', '5:3', '5:4', '5:5', '5:88', '5:96',
      '6:145', '16:114', '16:115', '7:31'],
  ),
  QuranTheme(
    id: 'work',
    title: 'Work and earning a living',
    blurb: 'Disperse through the land and seek of His bounty',
    keywords: [
      'work', 'working', 'job', 'jobs', 'career', 'earning', 'earn', 'income',
      'livelihood', 'business', 'trade', 'employment', 'employer', 'salary',
      'unemployed', 'looking for work', 'halal income', 'honest work',
      'fair measure', 'boss', 'colleague',
    ],
    verses: ['62:10', '2:198', '4:29', '28:26', '78:11', '67:15', '73:20',
      '83:1', '83:2', '83:3'],
  ),
  QuranTheme(
    id: 'backbiting',
    title: 'Backbiting, suspicion and gossip',
    blurb: 'Avoid much assumption, do not spy, do not backbite',
    keywords: [
      'backbiting', 'backbite', 'gheebah', 'ghibah', 'gossip', 'gossiping',
      'slander', 'rumour', 'rumor', 'talking behind my back', 'suspicion',
      'assumption', 'spying', 'mocking', 'making fun', 'nicknames', 'defame',
      'reputation', 'bad talk',
    ],
    verses: ['49:11', '49:12', '24:11', '24:12', '24:15', '24:19', '104:1',
      '68:11', '33:58'],
  ),
  QuranTheme(
    id: 'neighbours',
    title: 'Neighbours and guests',
    blurb: 'The neighbour who is kin and the neighbour who is a stranger',
    keywords: [
      'neighbour', 'neighbours', 'neighbor', 'neighbors', 'guest', 'guests',
      'hospitality', 'host', 'visitor', 'next door', 'community', 'welcome',
      'feeding people', 'inviting',
    ],
    verses: ['4:36', '51:24', '51:25', '51:26', '51:27', '11:69', '76:8', '107:7'],
  ),
  QuranTheme(
    id: 'doubt',
    title: 'Doubt and a weak heart',
    blurb: 'Even Ibrahim asked to be shown — and was not rebuked for it',
    keywords: [
      'doubt', 'doubting', 'doubts', 'questioning faith', 'weak iman',
      'weak faith', 'lost faith', 'losing faith', 'waswas', 'whispers',
      'is god real', 'does allah exist', 'far from allah', 'empty inside',
      'spiritually dry', 'why does god allow', 'unanswered prayer',
    ],
    verses: ['2:260', '6:76', '6:77', '6:78', '6:79', '29:2', '29:3', '2:186',
      '50:16', '3:8', '2:214'],
  ),
];
