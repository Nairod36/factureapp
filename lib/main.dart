import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'services/wallet_connect_interface.dart';
import 'services/wallet_connect_factory.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Utiliser un Provider qui gère automatiquement les erreurs WalletConnect
        ChangeNotifierProvider<WalletConnectServiceInterface>(
          create: (context) => _createWalletConnectService(),
        ),
      ],
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
        home: const LoginScreen(),
        // Utilisation d'un générateur de route personnalisé
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/auth':
              return MaterialPageRoute(builder: (context) => const LoginScreen());
            case '/home':
              final String userAddress = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => HomeScreen(userAddress: userAddress),
              );
            case '/create-invoice':
              final String userAddress = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => CreateInvoiceScreen(userAddress: userAddress),
              );
            default:
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              );
          }
        },
      ),
    );
  }

  // Créer le service WalletConnect approprié
  WalletConnectServiceInterface _createWalletConnectService() {
    // Utiliser la factory pour créer le service approprié
    return WalletConnectServiceFactory.createService();
  }
}
