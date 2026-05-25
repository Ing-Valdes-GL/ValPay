import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/wallet/bloc/wallet_bloc.dart';
import 'features/wallet/screens/dashboard_screen.dart';
import 'features/payment/screens/deposit_screen.dart';
import 'features/payment/screens/transfer_screen.dart';
import 'features/telecom/screens/telecom_screen.dart';
import 'features/qr/screens/qr_screen.dart';
import 'features/web/screens/landing_screen.dart';

void main() {
  runApp(const ValPayApp());
}

class ValPayApp extends StatelessWidget {
  const ValPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(AuthCheckRequested())),
        BlocProvider(create: (_) => WalletBloc()),
      ],
      child: MaterialApp(
        title: 'ValPay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: kIsWeb ? '/landing' : '/splash',
        routes: {
          '/landing': (_) => const LandingScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const _RegisterPlaceholder(),
          '/splash': (_) => const SplashScreen(),
          '/dashboard': (_) => kIsWeb ? const WebDashboardWrapper() : const MobileShell(),
          '/deposit': (_) => const DepositScreen(),
          '/transfer': (_) => const TransferScreen(),
          '/withdraw': (_) => const _WithdrawPlaceholder(),
          '/telecom': (_) => const TelecomScreen(),
          '/qr': (_) => const QrScreen(),
          '/history': (_) => const _HistoryPlaceholder(),
          '/privacy': (_) => const _LegalScreen(title: 'Politique de Confidentialité', isPrivacy: true),
          '/terms': (_) => const _LegalScreen(title: 'Conditions Générales d\'Utilisation', isPrivacy: false),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Auth check is triggered in AuthBloc constructor — listen in build
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('VP',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('ValPay',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w300)),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _selectedIndex = 0;

  final _screens = [
    const DashboardScreen(),
    const QrScreen(),
    const TelecomScreen(),
    const _HistoryPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.qr_code_outlined), selectedIcon: Icon(Icons.qr_code), label: 'QR Code'),
          NavigationDestination(icon: Icon(Icons.signal_cellular_alt_outlined), selectedIcon: Icon(Icons.signal_cellular_alt), label: 'Forfaits'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Historique'),
        ],
      ),
    );
  }
}

class WebDashboardWrapper extends StatelessWidget {
  const WebDashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: AppColors.primary,
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Text('ValPay',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                ...[
                  ('Tableau de bord', Icons.dashboard_outlined, '/dashboard'),
                  ('Transactions', Icons.history_outlined, '/history'),
                  ('Recharger', Icons.add_circle_outline, '/deposit'),
                  ('Envoyer', Icons.send_outlined, '/transfer'),
                  ('Forfaits', Icons.signal_cellular_alt, '/telecom'),
                  ('QR Code', Icons.qr_code_outlined, '/qr'),
                ]
                    .map((item) => ListTile(
                          leading: Icon(item.$2, color: Colors.white70, size: 20),
                          title: Text(item.$1,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          onTap: () => Navigator.of(context).pushNamed(item.$3),
                        ))
                    .toList(),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text('Déconnexion',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Main content
          const Expanded(child: DashboardScreen()),
        ],
      ),
    );
  }
}

// Placeholder screens
class _RegisterPlaceholder extends StatelessWidget {
  const _RegisterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: const Center(child: Text('Écran d\'inscription — à implémenter')),
    );
  }
}

class _WithdrawPlaceholder extends StatelessWidget {
  const _WithdrawPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retirer')),
      body: const Center(child: Text('Écran de retrait — à implémenter')),
    );
  }
}

class _HistoryPlaceholder extends StatelessWidget {
  const _HistoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: const Center(child: Text('Historique des transactions — à implémenter')),
    );
  }
}

class _LegalScreen extends StatelessWidget {
  final String title;
  final bool isPrivacy;
  const _LegalScreen({required this.title, required this.isPrivacy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          isPrivacy
              ? '''POLITIQUE DE CONFIDENTIALITÉ — ValPay

Dernière mise à jour : 25 mai 2025

1. COLLECTE DES DONNÉES
ValPay collecte les informations suivantes lors de l\'inscription : nom, email, numéro de téléphone et mot de passe. Ces données sont nécessaires au fonctionnement du service.

2. UTILISATION DES DONNÉES
Vos données sont utilisées pour : créer et gérer votre compte, traiter vos transactions financières, prévenir la fraude, vous contacter en cas de besoin.

3. PARTAGE DES DONNÉES
ValPay ne vend jamais vos données. Elles peuvent être partagées avec nos partenaires de paiement (CamPay, Reloadly) uniquement pour traiter vos transactions.

4. SÉCURITÉ
Vos données sont protégées par chiffrement SSL/TLS. Votre code PIN est stocké de manière irréversible (hashage bcrypt).

5. VOS DROITS
Vous pouvez demander l\'accès, la rectification ou la suppression de vos données en contactant support@valpay.cm.

6. CONTACT
ValPay — Douala, Cameroun
Email : privacy@valpay.cm'''
              : '''CONDITIONS GÉNÉRALES D\'UTILISATION — ValPay

Dernière mise à jour : 25 mai 2025

1. OBJET
Les présentes CGU régissent l\'utilisation de l\'application ValPay, service de portefeuille électronique disponible sur mobile et web.

2. INSCRIPTION
L\'utilisation de ValPay est réservée aux personnes physiques majeures résidant au Cameroun, disposant d\'un numéro de téléphone valide au format +237.

3. FONCTIONNEMENT DU PORTEFEUILLE
Le solde ValPay est exprimé en Francs CFA (XAF). Les transactions sont soumises aux frais définis dans la grille tarifaire.

4. FRAIS
- Recharge : 0% (gratuit)
- Transfert P2P : 1% à la charge de l\'envoyeur
- Retrait : 1% déduit du portefeuille
- Achats de forfaits : 0% (gratuit)

5. RESPONSABILITÉS
ValPay ne peut être tenu responsable en cas d\'erreur de numéro lors d\'un transfert. Toute transaction validée par code PIN est définitive.

6. RÉSILIATION
ValPay se réserve le droit de suspendre ou clôturer tout compte en cas de fraude ou d\'utilisation abusive.

7. DROIT APPLICABLE
Les présentes CGU sont régies par le droit camerounais.

8. CONTACT
support@valpay.cm''',
          style: const TextStyle(fontSize: 14, height: 1.7, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
