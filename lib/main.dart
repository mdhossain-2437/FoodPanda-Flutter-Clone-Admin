import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodpanda_admin/constants/colors.dart';
import 'package:foodpanda_admin/providers/authentication_provider.dart';
import 'package:foodpanda_admin/providers/internet_provider.dart';
import 'package:foodpanda_admin/router.dart';
import 'package:foodpanda_admin/splash_screen/screens/splash_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBVvoUDdeQlX2N9W_R7IOAZWPZvha1CTv4',
        appId: '1:360679595267:android:93f102c1478d329eba9d36',
        messagingSenderId: '360679595267',
        projectId: 'foodpanda-7ecb8',
        storageBucket: 'foodpanda-7ecb8.appspot.com',
      ),
    );
  } catch (_) {
    // Fallback to local admin store if Firebase is already initialized or offline
  }
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (context) => InternetProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FoodPanda Admin',
        theme: ThemeData(
          colorScheme: scheme,
          scaffoldBackgroundColor: Colors.white,
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        onGenerateRoute: (settings) => generateRoute(settings),
        home: const SplashScreen(),
      ),
    );
  }
}
