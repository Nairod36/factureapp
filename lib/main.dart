import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'models/user.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserState(),
      child: MaterialApp(
        title: 'Facture USDC',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: Consumer<UserState>(
          builder: (context, userState, child) {
            return userState.isAuthenticated 
                ? HomeScreen(user: userState.currentUser!)
                : const AuthScreen();
          },
        ),
        // Utilisation d'un générateur de route personnalisé
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/auth':
              return MaterialPageRoute(builder: (context) => const AuthScreen());
            case '/home':
              final User user = settings.arguments as User;
              return MaterialPageRoute(
                builder: (context) => HomeScreen(user: user),
              );
            case '/create-invoice':
              final User user = settings.arguments as User;
              return MaterialPageRoute(
                builder: (context) => CreateInvoiceScreen(user: user),
              );
            default:
              return MaterialPageRoute(
                builder: (context) => const AuthScreen(),
              );
          }
        },
      ),
    );
  }
}