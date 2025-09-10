import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslatePage extends StatefulWidget {
  @override
  _TranslatePageState createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  final _controller = TextEditingController();
  Map<String, String> _translations = {};
  bool _isTranslating = false;

  // Selected source language (default English)
  String _selectedSourceLanguage = "English";

  // Available languages mapping
  final Map<String, TranslateLanguage> _languageMap = {
    "English": TranslateLanguage.english,
    "Hindi": TranslateLanguage.hindi,
    "Malay": TranslateLanguage.malay,
    "Tamil": TranslateLanguage.tamil,
    "Telugu": TranslateLanguage.telugu,
    "Bengali": TranslateLanguage.bengali,
    "Gujarati": TranslateLanguage.gujarati,
    "Marathi": TranslateLanguage.marathi,
    "Urdu": TranslateLanguage.urdu,
    "Persian": TranslateLanguage.persian,
    "Spanish": TranslateLanguage.spanish,
    "French": TranslateLanguage.french,
    "German": TranslateLanguage.german,
    "Italian": TranslateLanguage.italian,
    "Portuguese": TranslateLanguage.portuguese,
    "Russian": TranslateLanguage.russian,
    "Chinese": TranslateLanguage.chinese,
    "Japanese": TranslateLanguage.japanese,
    "Korean": TranslateLanguage.korean,
    "Arabic": TranslateLanguage.arabic,
    "Dutch": TranslateLanguage.dutch,
    "Polish": TranslateLanguage.polish,
    "Turkish": TranslateLanguage.turkish,
    "Swedish": TranslateLanguage.swedish,
    "Norwegian": TranslateLanguage.norwegian,
    "Danish": TranslateLanguage.danish,
    "Finnish": TranslateLanguage.finnish,
    "Greek": TranslateLanguage.greek,
    "Hebrew": TranslateLanguage.hebrew,
    "Thai": TranslateLanguage.thai,
    "Vietnamese": TranslateLanguage.vietnamese,
    "Indonesian": TranslateLanguage.indonesian,
    "Ukrainian": TranslateLanguage.ukrainian,
    "Czech": TranslateLanguage.czech,
    "Slovak": TranslateLanguage.slovak,
    "Hungarian": TranslateLanguage.hungarian,
    "Romanian": TranslateLanguage.romanian,
    "Bulgarian": TranslateLanguage.bulgarian,
    "Croatian": TranslateLanguage.croatian,
    "Persian": TranslateLanguage.persian,
    "Slovenian": TranslateLanguage.slovenian,
    "Estonian": TranslateLanguage.estonian,
    "Latvian": TranslateLanguage.latvian,
    "Lithuanian": TranslateLanguage.lithuanian,
    "Macedonian": TranslateLanguage.macedonian,
    "Albanian": TranslateLanguage.albanian,
    "Maltese": TranslateLanguage.maltese,
    "Irish": TranslateLanguage.irish,
    "Welsh": TranslateLanguage.welsh,
    "Icelandic": TranslateLanguage.icelandic,
    "Catalan": TranslateLanguage.catalan,
    "Galician": TranslateLanguage.galician,
    "Afrikaans": TranslateLanguage.afrikaans,
    "Swahili": TranslateLanguage.swahili,
  };

  Future<void> _translateToAllLanguages() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter text to translate')),
      );
      return;
    }

    setState(() {
      _isTranslating = true;
      _translations.clear();
    });

    try {
      final sourceLanguageCode = _languageMap[_selectedSourceLanguage]!;

      // Get all languages except the selected source language
      final targetLanguages = _languageMap.entries
          .where((entry) => entry.key != _selectedSourceLanguage)
          .toList();

      for (final targetLang in targetLanguages) {
        try {
          final translator = OnDeviceTranslator(
            sourceLanguage: sourceLanguageCode,
            targetLanguage: targetLang.value,
          );

          final translation = await translator.translateText(input);

          setState(() {
            _translations[targetLang.key] = translation;
          });

          await translator.close();
        } catch (e) {
          print('Error translating to ${targetLang.key}: $e');
          setState(() {
            _translations[targetLang.key] = 'Translation failed';
          });
        }

        // Small delay to prevent overwhelming the device
        await Future.delayed(Duration(milliseconds: 100));
      }
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Multi-Language Translation"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedSourceLanguage,
              icon: Icon(Icons.language, color: Colors.black),
              dropdownColor: Colors.blue[700],
              style: TextStyle(color: Colors.black),
              underline: Container(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSourceLanguage = newValue;
                    _translations.clear();
                  });
                }
              },
              items: _languageMap.keys.map<DropdownMenuItem<String>>(
                    (String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(
                      language,
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Enter text in $_selectedSourceLanguage",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isTranslating ? null : _translateToAllLanguages,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isTranslating
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text("Translating..."),
                ],
              )
                  : Text("Translate to All Languages", style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 16),
            if (_translations.isNotEmpty) ...[
              Text(
                "Translations:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _translations.length,
                  itemBuilder: (context, index) {
                    final language = _translations.keys.elementAt(index);
                    final translation = _translations[language]!;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            language.substring(0, 2).toUpperCase(),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          language,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          translation,
                          style: TextStyle(fontSize: 16),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () {
                            // Copy to clipboard functionality would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied $language translation')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (!_isTranslating && _controller.text.isNotEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.translate, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Tap the translate button to see translations in all available languages",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (!_isTranslating) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Enter text and choose your source language from the dropdown above",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
