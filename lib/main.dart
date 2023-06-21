import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/user_profile_page.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import './services/firestore_service.dart';
import 'main_navigation_controller.dart';

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
    Provider<FirebaseStorage>(
      create: (_) => FirebaseStorage.instance,
    ),
    ProxyProvider<FirebaseFirestore, FirestoreService>(
      update: (_, firestore, __) => FirestoreService(firestore: firestore),
    ),
    ProxyProvider<FirebaseAuth, AuthService>(
      update: (_, auth, __) => AuthService(auth: auth),
    ),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/profile': (context) => const UserProfilePage(),
      },
      debugShowCheckedModeBanner: false,
      title: 'St James Park',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Typography.material2018(platform: TargetPlatform.android)
            .black
            .apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
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
      home: const MainNavigationController(),
    );
  }
}
