import 'package:flutter/material.dart';
import 'package:translation_gmlkit/pre_data_translate_page.dart';
import 'package:translation_gmlkit/translate_page.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: "Multi-Language Translation",
//       theme: ThemeData(primarySwatch: Colors.blue),
//       //home: TranslatePage(),
//       home: PreDataTranslatePage(),
//     );
//   }
// }
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TranslationProvider(),
      child: MaterialApp(
        title: 'ML Kit Translation App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomeScreen(),
        routes: {
          '/profile': (context) => ProfileScreen(),
          '/settings': (context) => SettingsScreen(),
        },
      ),
    );
  }
}