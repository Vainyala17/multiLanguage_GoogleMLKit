import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Model class for KaraSahayak data
class KaraSahayakOption {
  final String displayOptions;
  final List<String> keywordsGlossary;
  final String actionToPerform;
  final String appMethodToCall;

  KaraSahayakOption({
    required this.displayOptions,
    required this.keywordsGlossary,
    required this.actionToPerform,
    required this.appMethodToCall,
  });

  factory KaraSahayakOption.fromJson(Map<String, dynamic> json) {
    return KaraSahayakOption(
      displayOptions: json['display_options'] ?? '',
      keywordsGlossary: List<String>.from(json['keywords_glossary'] ?? []),
      actionToPerform: json['action_to_perform'] ?? '',
      appMethodToCall: json['app_method_to_call'] ?? '',
    );
  }
}

class KaraSahayakResponse {
  final List<KaraSahayakOption> karasahayakOptions;

  KaraSahayakResponse({required this.karasahayakOptions});

  factory KaraSahayakResponse.fromJson(Map<String, dynamic> json) {
    var karasahayakList = json['karasahayak'] as List;
    List<KaraSahayakOption> options = karasahayakList
        .map((option) => KaraSahayakOption.fromJson(option))
        .toList();

    return KaraSahayakResponse(karasahayakOptions: options);
  }
}

// Enhanced Translation Provider
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
  };

  Map<String, String> get languages => _languages;

  // Cache for storing translations
  final Map<String, Map<String, String>> _translationCache = {};
  final Set<String> _translatingTexts = {};
  bool _isBatchTranslating = false;

  Future<void> setLanguage(String languageCode) async {
    final TranslateLanguage? translateLanguage = _getTranslateLanguage(languageCode);
    if (translateLanguage == null) return;
    if (_selectedLanguage == translateLanguage) return;

    _isTranslating = true;
    notifyListeners();

    _selectedLanguage = translateLanguage;

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
      default: return null;
    }
  }

  String _getLanguageCode(TranslateLanguage language) {
    return _languages.entries
        .firstWhere((entry) => _getTranslateLanguage(entry.value) == language)
        .value;
  }

  /// SINGLE TEXT TRANSLATION (for static UI text)
  String translateText(String text) {
    if (_selectedLanguage == TranslateLanguage.english || text.trim().isEmpty) {
      return text;
    }

    final languageCode = _getLanguageCode(_selectedLanguage);

    if (_translationCache.containsKey(text) &&
        _translationCache[text]!.containsKey(languageCode)) {
      return _translationCache[text]![languageCode]!;
    }

    if (!_translatingTexts.contains(text)) {
      _translateTextAsync(text, languageCode);
    }

    return text;
  }

  Future<void> _translateTextAsync(String text, String languageCode) async {
    if (_selectedLanguage == TranslateLanguage.english ||
        _currentTranslator == null ||
        text.trim().isEmpty) {
      return;
    }

    _translatingTexts.add(text);

    try {
      if (!_translationCache.containsKey(text)) {
        _translationCache[text] = {};
      }

      final translated = await _currentTranslator!.translateText(text);
      _translationCache[text]![languageCode] = translated;

      notifyListeners();
    } catch (e) {
      print('Translation error for "$text": $e');
      _translationCache[text] ??= {};
      _translationCache[text]![languageCode] = text;
    } finally {
      _translatingTexts.remove(text);
    }
  }

  // BATCH TRANSLATION for API data
  Future<void> translateApiData(List<String> texts, String identifier) async {
    if (_selectedLanguage == TranslateLanguage.english ||
        _currentTranslator == null ||
        texts.isEmpty) {
      return;
    }

    final languageCode = _getLanguageCode(_selectedLanguage);

    // Filter texts that need translation
    final textsToTranslate = texts.where((text) =>
    text.trim().isNotEmpty &&
        (!_translationCache.containsKey(text) ||
            !_translationCache[text]!.containsKey(languageCode))
    ).toList();

    if (textsToTranslate.isEmpty) return;

    _isBatchTranslating = true;
    notifyListeners();

    try {
      // Translate in smaller batches to avoid overwhelming the API
      const batchSize = 10;
      for (int i = 0; i < textsToTranslate.length; i += batchSize) {
        final batch = textsToTranslate.skip(i).take(batchSize).toList();

        await Future.wait(
            batch.map((text) => _translateSingleTextForBatch(text, languageCode))
        );

        // Small delay between batches to respect API limits
        if (i + batchSize < textsToTranslate.length) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      print('Batch translation error: $e');
    } finally {
      _isBatchTranslating = false;
      notifyListeners();
    }
  }

  Future<void> _translateSingleTextForBatch(String text, String languageCode) async {
    try {
      if (!_translationCache.containsKey(text)) {
        _translationCache[text] = {};
      }

      final translated = await _currentTranslator!.translateText(text);
      _translationCache[text]![languageCode] = translated;
    } catch (e) {
      print('Batch translation error for "$text": $e');
      _translationCache[text] ??= {};
      _translationCache[text]![languageCode] = text;
    }
  }

  // Get translated text for API data (non-blocking)
  String getTranslatedText(String text) {
    if (_selectedLanguage == TranslateLanguage.english || text.trim().isEmpty) {
      return text;
    }

    final languageCode = _getLanguageCode(_selectedLanguage);

    if (_translationCache.containsKey(text) &&
        _translationCache[text]!.containsKey(languageCode)) {
      return _translationCache[text]![languageCode]!;
    }
    return text; // Return original if not translated yet
  }

  bool get isTranslating => _isTranslating;
  bool get isBatchTranslating => _isBatchTranslating;
  bool isTextTranslating(String text) => _translatingTexts.contains(text);

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

class KaraSahayakApiService {
  static const String baseUrl = 'https://259f74902f0a.ngrok-free.app';  //'http://192.168.0.106:5000';

  /// 1️⃣ Login -> get token
  static Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'), // adjust if backend uses different route
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["accessToken"]; // ✅ backend must return accessToken
      } else {
        print("❌ Login failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Error during login: $e");
      return null;
    }
  }

  /// 2️⃣ Fetch KaraSahayak options with token
  static Future<KaraSahayakResponse> fetchKaraSahayakOptions(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/kskeywords'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ✅ attach token
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return KaraSahayakResponse.fromJson(data);
      } else {
        throw Exception("Failed to fetch KaraSahayak options: "
            "${response.statusCode} ${response.body}");
      }
    } catch (e) {
      throw Exception("⚠️ API error: $e");
    }
  }
}



// Enhanced TranslatedText widget
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
        final isTranslating = provider.isTextTranslating(text);

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
              Flexible(
                child: Text(
                  text,
                  style: style?.copyWith(color: Colors.grey),
                  textAlign: textAlign,
                  maxLines: maxLines,
                  overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
                ),
              ),
            ],
          );
        }

        return Text(
          translatedText,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
        );
      },
    );
  }
}

// Widget for displaying API text that can be translated
class ApiTranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ApiTranslatedText(
      this.text, {
        Key? key,
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {
        final translatedText = provider.getTranslatedText(text);

        return Text(
          translatedText,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
        );
      },
    );
  }
}

// KaraSahayak Screen - Main screen for displaying options
class KaraSahayakScreen extends StatefulWidget {
  const KaraSahayakScreen({Key? key}) : super(key: key);

  @override
  State<KaraSahayakScreen> createState() => _KaraSahayakScreenState();
}

class _KaraSahayakScreenState extends State<KaraSahayakScreen> {
  List<KaraSahayakOption> options = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKaraSahayakOptions();
  }

  Future<void> _loadKaraSahayakOptions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // 1️⃣ Get token from backend (login)
      final token = await KaraSahayakApiService.login("7702000723", "test1234");

      if (token == null) {
        throw Exception("Login failed: Token is null");
      }

      // 2️⃣ Fetch KaraSahayak options using token
      final response = await KaraSahayakApiService.fetchKaraSahayakOptions(token);

      setState(() {
        options = response.karasahayakOptions;
        isLoading = false;
      });

      // 3️⃣ Extract text that needs translation
      final textsToTranslate = <String>[];
      for (final option in options) {
        textsToTranslate.addAll([
          option.displayOptions,
          option.actionToPerform,
          ...option.keywordsGlossary,
        ]);
      }

      // 4️⃣ Batch translate API data
      final translationProvider = Provider.of<TranslationProvider>(context, listen: false);
      await translationProvider.translateApiData(textsToTranslate, 'karasahayak');

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      print('Error loading KaraSahayak options: $e');
    }
  }


  void _executeAction(KaraSahayakOption option) {
    // Handle the action execution based on app_method_to_call
    print('Executing: ${option.appMethodToCall}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Executing: ${option.displayOptions}'),
        duration: Duration(seconds: 2),
      ),
    );

    // Here you would implement the actual method calls based on appMethodToCall
    switch (option.appMethodToCall) {
      case 'VisitHomeScreen':
      // Navigate to visitor registration
        break;
      case 'GrievanceHomeScreen':
      // Navigate to grievance registration
        break;
      case 'eVisitorPassScreen':
      // Show latest e-gatepass
        break;
      case 'GoogleMapScreen':
      // Open Google Maps
        break;
      case 'HelpDocScreen':
      // Show help documentation
        break;
      case 'ExitApp':
      // Exit the app
        Navigator.of(context).pop();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('KaraSahayak'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          Consumer<TranslationProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  if (provider.isBatchTranslating)
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  DropdownButton<String>(
                    value: provider._getLanguageCode(provider.selectedLanguage),
                    icon: const Icon(Icons.language, color: Colors.white),
                    underline: Container(),
                    dropdownColor: Colors.blue.shade700,
                    style: TextStyle(color: Colors.white),
                    items: provider.languages.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.value,
                        child: Text(
                          entry.key,
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: provider.isTranslating ? null : (String? languageCode) async {
                      if (languageCode != null) {
                        await provider.setLanguage(languageCode);
                        // Re-translate options when language changes
                        if (options.isNotEmpty) {
                          final textsToTranslate = <String>[];
                          for (final option in options) {
                            textsToTranslate.addAll([
                              option.displayOptions,
                              option.actionToPerform,
                              ...option.keywordsGlossary,
                            ]);
                          }
                          await provider.translateApiData(textsToTranslate, 'karasahayak');
                        }
                      }
                    },
                  ),
                  SizedBox(width: 16),
                ],
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadKaraSahayakOptions,
        child: Icon(Icons.refresh),
        tooltip: 'Refresh Options',
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            TranslatedText(
              'Loading KaraSahayak options...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              TranslatedText(
                'Failed to load options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadKaraSahayakOptions,
                child: TranslatedText('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (options.isEmpty) {
      return Center(
        child: TranslatedText(
          'No options available',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadKaraSahayakOptions,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          return KaraSahayakOptionCard(
            option: option,
            onTap: () => _executeAction(option),
          );
        },
      ),
    );
  }
}

class KaraSahayakOptionCard extends StatelessWidget {
  final KaraSahayakOption option;
  final VoidCallback onTap;

  const KaraSahayakOptionCard({
    Key? key,
    required this.option,
    required this.onTap,
  }) : super(key: key);

  IconData _getIconForOption(String appMethod) {
    switch (appMethod) {
      case 'VisitHomeScreen':
        return Icons.person_add;
      case 'GrievanceHomeScreen':
        return Icons.report_problem;
      case 'eVisitorPassScreen':
        return Icons.badge;
      case 'GoogleMapScreen':
        return Icons.map;
      case 'HelpDocScreen':
        return Icons.help;
      case 'ExitApp':
        return Icons.exit_to_app;
      default:
        return Icons.info;
    }
  }

  Color _getColorForOption(String appMethod) {
    switch (appMethod) {
      case 'VisitHomeScreen':
        return Colors.green;
      case 'GrievanceHomeScreen':
        return Colors.orange;
      case 'eVisitorPassScreen':
        return Colors.blue;
      case 'GoogleMapScreen':
        return Colors.red;
      case 'HelpDocScreen':
        return Colors.purple;
      case 'ExitApp':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForOption(option.appMethodToCall);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon + title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    radius: 26,
                    child: Icon(
                      _getIconForOption(option.appMethodToCall),
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ApiTranslatedText(
                      option.displayOptions,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action to perform
              Text(
                "Action:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              ApiTranslatedText(
                option.actionToPerform,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 12),

              // Keywords section
              if (option.keywordsGlossary.isNotEmpty) ...[
                Text(
                  "Keywords:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: option.keywordsGlossary.map((keyword) {
                    return Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: ApiTranslatedText(
                        keyword,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

//
// // Main App
// class KaraSahayakApp extends StatelessWidget {
//   const KaraSahayakApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => TranslationProvider(),
//       child: MaterialApp(
//         title: 'KaraSahayak Translation App',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//           visualDensity: VisualDensity.adaptivePlatformDensity,
//         ),
//         home: const KaraSahayakScreen(),
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }
