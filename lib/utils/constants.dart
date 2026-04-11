class AppConstants {
  static const String supabaseUrl = 'https://jejdynhubeidvtxztuqv.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImplamR5bmh1YmVpZHZ0eHp0dXF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NTQxNzQsImV4cCI6MjA5MDEzMDE3NH0.DDadJNXC1NLny_MoF4XAoYPVEhHZRGclAfFotDdVyvY';
static const String uploadEndpoint =
    'https://marapedia.org/api/upload';
  static const List<String> languagePriority = [
    'mara',
    'english',
    'myanmar',
    'mizo',
  ];
  static const List<Map<String, String>> categories = [
    {'value': 'history', 'label': 'History', 'icon': '📜'},
    {'value': 'songs', 'label': "Songs's Lyrics", 'icon': '🎵'},
    {'value': 'poems', 'label': 'Poems', 'icon': '✍️'},
    {'value': 'stories', 'label': 'Stories', 'icon': '📖'},
    {'value': 'people', 'label': 'Famous People', 'icon': '👤'},
    {'value': 'places', 'label': 'Villages & Places', 'icon': '🏘️'},
    {'value': 'culture', 'label': 'Culture', 'icon': '🎭'},
    {'value': 'religion', 'label': 'Religion', 'icon': '⛪'},
    {'value': 'language', 'label': 'Language', 'icon': '🗣️'},
    {'value': 'photos', 'label': 'Photos', 'icon': '📷'},
    {'value': 'other', 'label': 'Other', 'icon': '📁'},
  ];
  static const Map<String, List<Map<String, String>>> articleTypes = {
    'songs': [
      {'value': 'worship', 'label': '🙏 Worship Song'},
      {'value': 'hymn', 'label': '⛪ Hymn'},
      {'value': 'love', 'label': '❤️ Love Song'},
      {'value': 'folk', 'label': '🎶 Folk Song'},
      {'value': 'childrens', 'label': "🧒 Children's Song"},
      {'value': 'lullaby', 'label': '🌙 Lullaby'},
      {'value': 'patriotic', 'label': '🏔️ Patriotic Song'},
      {'value': 'other', 'label': '📁 Other'},
    ],
    'poems': [
      {'value': 'spiritual', 'label': '✝️ Spiritual / Devotional'},
      {'value': 'nature', 'label': '🌿 Nature'},
      {'value': 'love', 'label': '❤️ Love'},
      {'value': 'cultural', 'label': '🎭 Cultural'},
      {'value': 'lament', 'label': '😔 Lament'},
      {'value': 'praise', 'label': '🙌 Praise'},
      {'value': 'historical', 'label': '📜 Historical'},
      {'value': 'other', 'label': '📁 Other'},
    ],
    'history': [
      {'value': 'village', 'label': '🏘️ Village History'},
      {'value': 'migration', 'label': '🚶 Migration'},
      {'value': 'chin_state', 'label': '🇲🇲 Chin State History'},
      {'value': 'india', 'label': '🇮🇳 India / Mizoram History'},
      {'value': 'war', 'label': '⚔️ War & Conflict'},
      {'value': 'leadership', 'label': '👑 Leadership'},
      {'value': 'church', 'label': '⛪ Church History'},
      {'value': 'other', 'label': '📁 Other'},
    ],
    'stories': [
      {'value': 'folktale', 'label': '🌙 Folktale'},
      {'value': 'legend', 'label': '⚡ Legend'},
      {'value': 'moral', 'label': '📖 Moral Story'},
      {'value': 'creation', 'label': '🌏 Creation Story'},
      {'value': 'other', 'label': '📁 Other'},
    ],
    'people': [
      {'value': 'pastor', 'label': '✝️ Pastor / Church Leader'},
      {'value': 'chief', 'label': '👑 Chief / Village Leader'},
      {'value': 'artist', 'label': '🎵 Artist / Musician'},
      {'value': 'teacher', 'label': '📚 Teacher / Scholar'},
      {'value': 'warrior', 'label': '⚔️ Warrior'},
      {'value': 'missionary', 'label': '🌍 Missionary'},
      {'value': 'other', 'label': '📁 Other'},
    ],
    'places': [
      {'value': 'chin_village', 'label': '🇲🇲 Village in Chin State'},
      {'value': 'india_village', 'label': '🇮🇳 Village in Mizoram / India'},
      {'value': 'sacred', 'label': '✝️ Sacred Site'},
      {'value': 'river', 'label': '🌊 River'},
      {'value': 'mountain', 'label': '⛰️ Mountain'},
      {'value': 'other', 'label': '📁 Other'},
    ],
    'culture': [
      {'value': 'festival', 'label': '🎉 Festival'},
      {'value': 'dance', 'label': '💃 Traditional Dance'},
      {'value': 'food', 'label': '🍽️ Food & Cuisine'},
      {'value': 'clothing', 'label': '👘 Clothing & Dress'},
      {'value': 'ceremony', 'label': '🕯️ Ceremony & Ritual'},
      {'value': 'other', 'label': '📁 Other'},
    ],
    'religion': [
      {'value': 'hymn', 'label': '🎵 Hymn'},
      {'value': 'prayer', 'label': '🙏 Prayer'},
      {'value': 'sermon', 'label': '📖 Sermon'},
      {'value': 'testimony', 'label': '✝️ Testimony'},
      {'value': 'bible', 'label': '📗 Bible Study'},
      {'value': 'church', 'label': '⛪ Church History'},
      {'value': 'other', 'label': '📁 Other'},
    ],
    'language': [
      {'value': 'tlosai', 'label': '🗣️ Tlosai Dialect'},
      {'value': 'vocabulary', 'label': '📝 Vocabulary'},
      {'value': 'proverb', 'label': '💬 Proverb'},
      {'value': 'grammar', 'label': '📖 Grammar'},
      {'value': 'other', 'label': '📁 Other'},
    ],
    'other': [
      {'value': 'general', 'label': '📁 General'},
      {'value': 'other', 'label': '📁 Other'},
    ],
  };
  static const Map<String, String> languageLabels = {
    'mara': 'Mara',
    'english': 'English',
    'myanmar': 'မြန်မာ',
    'mizo': 'Mizo',
  };
}
