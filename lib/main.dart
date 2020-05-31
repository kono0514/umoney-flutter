import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umoney_flutter/screens/intentScanner.dart';
import 'package:umoney_flutter/models/app.dart';
import 'package:umoney_flutter/models/card.dart';
import 'package:flutter/services.dart';
import 'package:umoney_flutter/screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => CardModel()),
          ChangeNotifierProvider(create: (context) => AppModel()),
        ],
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U Money NFC scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (_) => Home(),
        '/intentScanner': (_) => IntentScanner(),
      },
    );
  }
}

