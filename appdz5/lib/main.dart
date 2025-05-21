import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dztrainfay/CreatePasswordScreen.dart';
import 'package:dztrainfay/ForgotPasswordScreen.dart';
import 'package:dztrainfay/PasswordChangedScreen.dart';
import 'package:dztrainfay/SignInScreen.dart';
import 'package:dztrainfay/SignUpScreen.dart';
import 'package:dztrainfay/VerifyEmailScreen.dart';
import 'package:dztrainfay/onboarding_screen.dart';
import 'package:dztrainfay/HomePage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:dztrainfay/locale_provider.dart';

// Définition des couleurs et gradient demandés
const LinearGradient backgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFE3F2FD), // bleu très clair
    Color(0xFFB3E5FC), // bleu ciel
    Color(0xFF7986CB), // indigo moyen
  ],
);

const Color primaryColor = Color(0xFF7986CB); // Indigo moyen
const Color cardColor = Colors.white;         // Fond des champs de texte
const Color textColor = Colors.black87;       // Texte principal
const Color subtitleColor = Colors.grey;      // Texte secondaire

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();

  // Chargement des préférences locales
  final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
  final bool isLoggedInPref = prefs.getBool('isLoggedIn') ?? false; // pas utilisé dans ta logique
  final String username = prefs.getString('username') ?? 'Utilisateur';
  final bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  bool loggedIn = false;

  // Sauvegarde du username dans prefs (peut-être redondant)
  await prefs.setString('username', username);

  // Vérification login en base Firestore pour ce username
  if (username.isNotEmpty) {
    final doc = await FirebaseFirestore.instance
        .collection('CompteUser')
        .doc(username)
        .get();

    if (doc.exists) {
      loggedIn = doc['loggedIn'] ?? false;
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: MyApp(
        onboardingSeen: onboardingSeen,
        isLoggedIn: loggedIn,
        username: username,
        isDarkMode: isDarkMode,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool onboardingSeen;
  final bool isLoggedIn;
  final String username;
  final bool isDarkMode;

  const MyApp({
    Key? key,
    required this.onboardingSeen,
    required this.isLoggedIn,
    required this.username,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget startScreen;
    final provider = Provider.of<LocaleProvider>(context);

    // Logique de navigation initiale
    if (!onboardingSeen) {
      startScreen = OnboardingScreen();
    } else if (isLoggedIn) {
      startScreen = HomePage(username: username);
    } else {
      startScreen = SignInScreen();
    }

    return MaterialApp(
      title: AppLocalizations.of(context)?.app_title ?? 'DzTrain',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: provider.locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      theme: ThemeData.light().copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: cardColor,
        ),
        cardColor: cardColor,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: textColor),
          bodySmall: TextStyle(color: subtitleColor),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardColor,
          labelStyle: TextStyle(color: textColor),
          hintStyle: TextStyle(color: subtitleColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: cardColor,
        ),
        cardColor: const Color(0xFF1E1E2E),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.blueGrey),
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.purpleAccent,
          textColor: Colors.white,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStatePropertyAll(Colors.purpleAccent),
          trackColor: MaterialStatePropertyAll(Colors.purpleAccent),
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Container(
        decoration: const BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: startScreen,
      ),
      routes: {
        '/login': (context) => SignInScreen(),
        '/signup': (context) => RegisterPage(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/password-changed': (context) => PasswordChangedScreen(),
      },
    );
  }
}

// Fonction pour déconnexion complète
Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final String username = prefs.getString('username') ?? '';

  try {
    if (username.isNotEmpty) {
      // Met à jour le statut loggedIn dans Firestore
      await FirebaseFirestore.instance
          .collection('CompteUser')
          .doc(username)
          .set({'loggedIn': false}, SetOptions(merge: true));

      print("✅ loggedIn mis à false pour $username");
    }
  } catch (e) {
    print("${AppLocalizations.of(context)?.error_prefix ?? '❌ Erreur :'} $e");
  }

  // Nettoyage prefs et déconnexion Firebase et Google
  await prefs.clear();
  await FirebaseAuth.instance.signOut();
  await GoogleSignIn().signOut();

  // Redirection vers l'écran de login en supprimant l'historique de navigation
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}

// Fonction optionnelle pour suppression de compte
Future<void> deleteAccount(BuildContext context, String userId) async {
  try {
    // Suppression document utilisateur Firestore
    await FirebaseFirestore.instance.collection('User').doc(userId).delete();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)?.account_deleted_success ?? 'Compte supprimé avec succès'),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)?.account_deletion_error ?? 'Erreur lors de la suppression du compte'),
      ),
    );
  }
}
