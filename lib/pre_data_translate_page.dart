
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:provider/provider.dart';

class TranslationProvider extends ChangeNotifier {
  TranslateLanguage _selectedLanguage = TranslateLanguage.english;
  OnDeviceTranslator? _currentTranslator;

  TranslateLanguage get selectedLanguage => _selectedLanguage;

  // Available languages
  final Map<TranslateLanguage, String> _languages = {
    TranslateLanguage.english: 'English',
    TranslateLanguage.spanish: 'Spanish',
    TranslateLanguage.french: 'French',
    TranslateLanguage.german: 'German',
    TranslateLanguage.hindi: 'Hindi',
  };

  Map<TranslateLanguage, String> get languages => _languages;

  // IMPROVED: Single cache for all translations
  final Map<String, String> _translationCache = {};

  String _getCacheKey(String text, TranslateLanguage targetLanguage) {
    return '${text}_${targetLanguage.name}';
  }

  Future<void> setLanguage(TranslateLanguage language) async {
    if (_selectedLanguage == language) return;

    _selectedLanguage = language;

    // FIXED: Close previous translator before creating new one
    await _currentTranslator?.close();
    _currentTranslator = null;

    if (language != TranslateLanguage.english) {
      _currentTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: language,
      );
    }

    notifyListeners();
  }

  Future<String> translateText(String text) async {
    if (_selectedLanguage == TranslateLanguage.english || text.isEmpty) {
      return text;
    }

    final cacheKey = _getCacheKey(text, _selectedLanguage);

    // IMPROVED: Return cached translation immediately
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    // FIXED: Prevent multiple simultaneous translations
    if (_isTranslating) {
      return text;
    }

    try {
      _isTranslating = true;

      if (_currentTranslator == null) {
        _currentTranslator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.english,
          targetLanguage: _selectedLanguage,
        );
      }

      final translatedText = await _currentTranslator!.translateText(text);

      // Cache the translation
      _translationCache[cacheKey] = translatedText;

      return translatedText;
    } catch (e) {
      print('Translation error: $e');
      return text;
    } finally {
      _isTranslating = false;
    }
  }

  void clearCache() {
    _translationCache.clear();
  }

  @override
  void dispose() {
    _currentTranslator?.close();
    super.dispose();
  }
}

// OPTIMIZED: TranslatedText widget
class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  const TranslatedText(
      this.text, {
        Key? key,
        this.style,
        this.textAlign,
        this.maxLines,
      }) : super(key: key);

  @override
  _TranslatedTextState createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _translatedText = '';
  TranslateLanguage? _lastLanguage;
  String? _lastText;

  @override
  void initState() {
    super.initState();
    _translatedText = widget.text;
    _translateTextIfNeeded();
  }

  Future<void> _translateTextIfNeeded() async {
    final provider = Provider.of<TranslationProvider>(context, listen: false);

    // FIXED: Only translate if language or text changed
    if (_lastLanguage == provider.selectedLanguage && _lastText == widget.text) {
      return;
    }

    _lastLanguage = provider.selectedLanguage;
    _lastText = widget.text;

    final translated = await provider.translateText(widget.text);

    if (mounted) {
      setState(() {
        _translatedText = translated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {
        // OPTIMIZED: Only retranslate when necessary
        if (_lastLanguage != provider.selectedLanguage || _lastText != widget.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _translateTextIfNeeded();
          });
        }

        return Text(
          _translatedText,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.maxLines != null ? TextOverflow.ellipsis : null,
        );
      },
    );
  }
}

// SIMPLIFIED: Language Selector
class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {
        return DropdownButton<TranslateLanguage>(
          value: provider.selectedLanguage,
          icon: Icon(Icons.language),
          underline: Container(),
          items: provider.languages.entries.map((entry) {
            return DropdownMenuItem<TranslateLanguage>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (TranslateLanguage? language) {
            if (language != null) {
              provider.setLanguage(language);
            }
          },
        );
      },
    );
  }
}

// OPTIMIZED: Home Screen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText('Home'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            SizedBox(height: 16),
            _buildFeaturesCard(),
            SizedBox(height: 16),
            _buildNavigationButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  Widget _buildFeaturesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  Widget _buildNavigationButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            child: TranslatedText('Profile'),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            child: TranslatedText('Settings'),
          ),
        ),
      ],
    );
  }
}

// OPTIMIZED: Profile Screen
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText('Profile'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            SizedBox(height: 20),
            _buildInfoCard(),
            SizedBox(height: 16),
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'User Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow('Name', 'John Doe'),
            _buildInfoRow('Email', 'john.doe@example.com'),
            _buildInfoRow('Location', 'New York, USA'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
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

  Widget _buildAboutCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

// OPTIMIZED: Settings Screen
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText('Settings'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSettingsCard(context),
          SizedBox(height: 8),
          _buildAppCard(context),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Choose language',
            onTap: () => _showLanguageDialog(context),
          ),
          Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notifications',
            onTap: () {},
          ),
          Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.storage,
            title: 'Storage',
            subtitle: 'Manage storage',
            onTap: () => _showClearCacheDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.help,
            title: 'Help',
            subtitle: 'Get help',
            onTap: () {},
          ),
          Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App information',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: TranslatedText(title, maxLines: 1),
      subtitle: TranslatedText(subtitle, maxLines: 1),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: TranslatedText('Select Language'),
        content: Consumer<TranslationProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: provider.languages.entries.map((entry) {
                return RadioListTile<TranslateLanguage>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: provider.selectedLanguage,
                  onChanged: (value) {
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
        title: TranslatedText('Clear Cache'),
        content: TranslatedText('This will clear all cached translations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TranslatedText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<TranslationProvider>(context, listen: false).clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: TranslatedText('Cache cleared')),
              );
            },
            child: TranslatedText('Clear'),
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
      children: [
        TranslatedText('Google ML Kit Translation Demo'),
      ],
    );
  }
}