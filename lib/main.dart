import 'package:location_web/location_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart'
    if (dart.library.html) 'package:image_picker/image_picker.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import './services/firestore_service.dart';
import 'my_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MultiProvider(providers: [
    Provider<FirebaseFirestore>(
      create: (_) => FirebaseFirestore.instance,
    ),
    Provider<FirebaseAuth>(
      create: (_) => FirebaseAuth.instance,
    ),
    ProxyProvider<FirebaseFirestore, FirestoreService>(
      update: (_, firestore, __) => FirestoreService(firestore: firestore),
    ),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'St James Park',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Typography.material2018(platform: TargetPlatform.android)
            .white
            .apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Colors.white,
          selectionHandleColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.white),
          labelStyle: TextStyle(color: Colors.white),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
      ),
      home: MyHomePage(),
    );
  }
}
