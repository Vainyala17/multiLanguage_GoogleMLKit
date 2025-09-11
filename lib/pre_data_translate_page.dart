import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:provider/provider.dart';

class TranslationProvider extends ChangeNotifier {
  TranslateLanguage _selectedLanguage = TranslateLanguage.english;
  OnDeviceTranslator? _currentTranslator;
  bool _isTranslating = false;

  TranslateLanguage get selectedLanguage => _selectedLanguage;
  final Map<String, String> _languages = {
    "English": "en",
    "Hindi": "hi",
    "Malay": "ms",
    "Tamil": "ta",
    "Telugu": "te",
    "Bengali": "bn",
    "Gujarati": "gu",
    "Marathi": "mr",
    "Urdu": "ur",
    "Persian": "fa",
    "Spanish": "es",
    "French": "fr",
    "German": "de",
    "Italian": "it",
    "Portuguese": "pt",
    "Russian": "ru",
    "Chinese": "zh",
    "Japanese": "ja",
    "Korean": "ko",
    "Arabic": "ar",
    "Dutch": "nl",
    "Polish": "pl",
    "Turkish": "tr",
    "Swedish": "sv",
    "Norwegian": "no",
    "Danish": "da",
    "Finnish": "fi",
    "Greek": "el",
    "Hebrew": "he",
    "Thai": "th",
    "Vietnamese": "vi",
    "Indonesian": "id",
    "Ukrainian": "uk",
    "Czech": "cs",
    "Slovak": "sk",
    "Hungarian": "hu",
    "Romanian": "ro",
    "Bulgarian": "bg",
    "Croatian": "hr",
    "Slovenian": "sl",
    "Estonian": "et",
    "Latvian": "lv",
    "Lithuanian": "lt",
    "Macedonian": "mk",
    "Albanian": "sq",
    "Maltese": "mt",
    "Irish": "ga",
    "Welsh": "cy",
    "Icelandic": "is",
    "Catalan": "ca",
    "Galician": "gl",
    "Afrikaans": "af",
    "Swahili": "sw",
  };

  Map<String, String> get languages => _languages;

  // Cache for storing translations: text -> language_code -> translated_text
  final Map<String, Map<String, String>> _translationCache = {};

  // Set of texts currently being translated (to avoid duplicate API calls)
  final Set<String> _translatingTexts = {};

  Future<void> setLanguage(String languageCode) async {
    final TranslateLanguage? translateLanguage = _getTranslateLanguage(languageCode);
    if (translateLanguage == null) return;

    if (_selectedLanguage == translateLanguage) return;

    // Set loading state
    _isTranslating = true;
    notifyListeners();

    _selectedLanguage = translateLanguage;

    // Close previous translator
    await _currentTranslator?.close();
    _currentTranslator = null;

    if (translateLanguage != TranslateLanguage.english) {
      _currentTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: translateLanguage,
      );
    }

    _isTranslating = false;
    notifyListeners();
  }

  TranslateLanguage? _getTranslateLanguage(String languageCode) {
    switch (languageCode) {
      case "en": return TranslateLanguage.english;
      case "hi": return TranslateLanguage.hindi;
      case "ms": return TranslateLanguage.malay;
      case "ta": return TranslateLanguage.tamil;
      case "te": return TranslateLanguage.telugu;
      case "bn": return TranslateLanguage.bengali;
      case "gu": return TranslateLanguage.gujarati;
      case "mr": return TranslateLanguage.marathi;
      case "ur": return TranslateLanguage.urdu;
      case "fa": return TranslateLanguage.persian;
      case "es": return TranslateLanguage.spanish;
      case "fr": return TranslateLanguage.french;
      case "de": return TranslateLanguage.german;
      case "it": return TranslateLanguage.italian;
      case "pt": return TranslateLanguage.portuguese;
      case "ru": return TranslateLanguage.russian;
      case "zh": return TranslateLanguage.chinese;
      case "ja": return TranslateLanguage.japanese;
      case "ko": return TranslateLanguage.korean;
      case "ar": return TranslateLanguage.arabic;
      case "nl": return TranslateLanguage.dutch;
      case "pl": return TranslateLanguage.polish;
      case "tr": return TranslateLanguage.turkish;
      case "sv": return TranslateLanguage.swedish;
      case "no": return TranslateLanguage.norwegian;
      case "da": return TranslateLanguage.danish;
      case "fi": return TranslateLanguage.finnish;
      case "el": return TranslateLanguage.greek;
      case "he": return TranslateLanguage.hebrew;
      case "th": return TranslateLanguage.thai;
      case "vi": return TranslateLanguage.vietnamese;
      case "id": return TranslateLanguage.indonesian;
      case "uk": return TranslateLanguage.ukrainian;
      case "cs": return TranslateLanguage.czech;
      case "sk": return TranslateLanguage.slovak;
      case "hu": return TranslateLanguage.hungarian;
      case "ro": return TranslateLanguage.romanian;
      case "bg": return TranslateLanguage.bulgarian;
      case "hr": return TranslateLanguage.croatian;
      case "sl": return TranslateLanguage.slovenian;
      case "et": return TranslateLanguage.estonian;
      case "lv": return TranslateLanguage.latvian;
      case "lt": return TranslateLanguage.lithuanian;
      case "mk": return TranslateLanguage.macedonian;
      case "sq": return TranslateLanguage.albanian;
      case "mt": return TranslateLanguage.maltese;
      case "ga": return TranslateLanguage.irish;
      case "cy": return TranslateLanguage.welsh;
      case "is": return TranslateLanguage.icelandic;
      case "ca": return TranslateLanguage.catalan;
      case "gl": return TranslateLanguage.galician;
      case "af": return TranslateLanguage.afrikaans;
      case "sw": return TranslateLanguage.swahili;
      default: return null;
    }
  }

  String _getLanguageCode(TranslateLanguage language) {
    return _languages.entries
        .firstWhere((entry) => _getTranslateLanguage(entry.value) == language)
        .value;
  }

  // Dynamic translation method
  String translateText(String text) {
    if (_selectedLanguage == TranslateLanguage.english || text.trim().isEmpty) {
      return text;
    }

    final languageCode = _getLanguageCode(_selectedLanguage);

    // Return cached translation if available
    if (_translationCache.containsKey(text) &&
        _translationCache[text]!.containsKey(languageCode)) {
      return _translationCache[text]![languageCode]!;
    }

    // Start translation if not already translating this text
    if (!_translatingTexts.contains(text)) {
      _translateTextAsync(text, languageCode);
    }

    return text; // Return original text while translation is in progress
  }

  // Asynchronous translation for any text
  Future<void> _translateTextAsync(String text, String languageCode) async {
    if (_selectedLanguage == TranslateLanguage.english ||
        _currentTranslator == null ||
        text.trim().isEmpty) {
      return;
    }

    _translatingTexts.add(text);

    try {
      // Initialize cache for this text if not exists
      if (!_translationCache.containsKey(text)) {
        _translationCache[text] = {};
      }

      // Translate the text
      final translated = await _currentTranslator!.translateText(text);
      _translationCache[text]![languageCode] = translated;

      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      print('Translation error for "$text": $e');
      // Store original text as fallback
      _translationCache[text] ??= {};
      _translationCache[text]![languageCode] = text;
    } finally {
      _translatingTexts.remove(text);
    }
  }

  bool get isTranslating => _isTranslating;

  // Check if a specific text is being translated
  bool isTextTranslating(String text) {
    return _translatingTexts.contains(text);
  }

  void clearCache() {
    _translationCache.clear();
    _translatingTexts.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _currentTranslator?.close();
    super.dispose();
  }
}

// Dynamic TranslatedText widget that works with any text
class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool showLoadingIndicator;

  const TranslatedText(
      this.text, {
        Key? key,
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.showLoadingIndicator = false,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {

        final translatedText = provider.translateText(text);
        final isOriginalText = translatedText == text;
        final isTranslating = provider.isTextTranslating(text);

        // Show loading indicator for individual text if requested and translating
        if (showLoadingIndicator &&
            isTranslating &&
            provider.selectedLanguage != TranslateLanguage.english) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                text,
                style: style?.copyWith(color: Colors.grey),
                textAlign: textAlign,
                maxLines: maxLines,
                overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
              ),
            ],
          );
        }

        return Text(
          translatedText,
          style: isOriginalText && isTranslating
              ? style?.copyWith(color: Colors.grey.shade600)
              : style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
        );
      },
    );
  }
}

// Language Selector with simplified language codes
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.isTranslating)
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            DropdownButton<String>(
              value: provider._getLanguageCode(provider.selectedLanguage),
              icon: const Icon(Icons.language),
              underline: Container(),
              items: provider.languages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
              onChanged: provider.isTranslating ? null : (String? languageCode) {
                if (languageCode != null) {
                  provider.setLanguage(languageCode);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// Home Screen - No changes needed, will automatically translate
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Home'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeCard(),
            SizedBox(height: 16),
            _FeaturesCard(),
            SizedBox(height: 16),
            _NavigationButtons(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            TranslatedText(
              'Welcome to Our App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TranslatedText(
              'This app demonstrates translation using Google ML Kit.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            TranslatedText(
              'Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TranslatedText('• Real-time translation'),
            SizedBox(height: 4),
            TranslatedText('• Multiple language support'),
            SizedBox(height: 4),
            TranslatedText('• Offline capability'),
          ],
        ),
      ),
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            child: const TranslatedText('Profile'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            child: const TranslatedText('Settings'),
          ),
        ),
      ],
    );
  }
}

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Profile'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            SizedBox(height: 20),
            _InfoCard(),
            SizedBox(height: 16),
            _AboutCard(),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TranslatedText(
              'User Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Name', value: 'John Doe'),
            _InfoRow(label: 'Email', value: 'john.doe@example.com'),
            _InfoRow(label: 'Location', value: 'New York, USA'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: TranslatedText('$label:', maxLines: 1),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            TranslatedText(
              'About Me',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TranslatedText(
              'I am a software developer passionate about mobile applications.',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// Settings Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Settings'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: Column(
        children: [
          _SettingsCard(),
          const SizedBox(height: 8),
          _AppCard(),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Choose language',
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: TranslatedText('Coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.storage,
            title: 'Storage',
            subtitle: 'Manage storage',
            onTap: () => _showClearCacheDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const TranslatedText('Select Language'),
        content: Consumer<TranslationProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: provider.languages.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.key),
                  value: entry.value,
                  groupValue: provider._getLanguageCode(provider.selectedLanguage),
                  onChanged: provider.isTranslating ? null : (value) {
                    if (value != null) {
                      provider.setLanguage(value);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const TranslatedText('Clear Cache'),
        content: const TranslatedText('This will clear all cached translations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<TranslationProvider>(context, listen: false).clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: TranslatedText('Cache cleared')),
              );
            },
            child: const TranslatedText('Clear'),
          ),
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.help,
            title: 'Help',
            subtitle: 'Get help',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: TranslatedText('Help coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App information',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Translation App',
      applicationVersion: '1.0.0',
      children: const [
        TranslatedText('Google ML Kit Translation Demo'),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: TranslatedText(title, maxLines: 1),
      subtitle: TranslatedText(subtitle, maxLines: 1),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

// Main App class with proper routing
class TranslationApp extends StatelessWidget {
  const TranslationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TranslationProvider(),
      child: MaterialApp(
        title: 'Translation App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
        routes: {
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}