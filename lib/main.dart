import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'HomeScreen.dart';
import 'ProfileScreen.dart';
import '404NotFound.dart';
import 'AuthService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      // TODO: These will be filled in by you with your Firebase config
      apiKey: "todo",
      appId: "todo",
      messagingSenderId: "todo",
      projectId: "todo",
    ),
  );

  runApp(MyTopFive());
}

class MyTopFive extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: Consumer<AuthService>(
          builder: (context, authService, _) {
            return MaterialApp(
              title: 'My Top Five',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
                fontFamily: 'Roboto',
              ),
              initialRoute: '/',
              onGenerateRoute: (settings) {
                // Handle URL routing
                if (settings.name == '/') {
                  return MaterialPageRoute(builder: (_) => HomeScreen());
                }

                // Handle profile routes (my-top-five.com/username-hash)
                var uri = Uri.parse(settings.name!);
                var segments = uri.pathSegments;

                if (segments.length == 1 && segments[0].contains('-')) {
                  // This is a profile URL
                  String profileId = segments[0];
                  return MaterialPageRoute(
                    builder: (_) => ProfileScreen(profileId: profileId),
                  );
                }

                // Handle 404
                return MaterialPageRoute(builder: (_) => NotFoundScreen());
              },
            );
          }
      ),
    );
  }
}