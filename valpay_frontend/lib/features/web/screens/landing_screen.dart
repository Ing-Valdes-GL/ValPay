import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Row(
          children: [
            Text('VP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(width: 8),
            Text('ValPay', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/pricing'),
            child: const Text('Tarifs', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/privacy'),
            child: const Text('Confidentialité', style: TextStyle(color: Colors.white70)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: AppColors.primary),
              child: const Text('Connexion'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: isWide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: _heroText(context)),
                        const SizedBox(width: 60),
                        _heroVisual(),
                      ],
                    )
                  : Column(
                      children: [_heroText(context), const SizedBox(height: 40), _heroVisual()],
                    ),
            ),
            // Features
            _buildFeatures(),
            // Pricing table
            _buildPricingSection(),
            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _heroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Le portefeuille digital\ndu Cameroun',
          style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              height: 1.2),
        ),
        const SizedBox(height: 16),
        const Text(
          'Rechargez, transférez et retirez via Orange Money, MTN MoMo et Express Union. Achetez vos forfaits Internet et Appels directement depuis votre solde.',
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed('/register'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Créer un compte gratuit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _heroVisual() {
    return Container(
      width: 260,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Solde disponible',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('125 000 FCFA',
              style: TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const Spacer(),
          ...[
            ('Recharge Orange', '+50 000 FCFA', true),
            ('Transfert vers Jean', '-10 100 FCFA', false),
            ('Forfait Internet', '-5 000 FCFA', false),
          ].map((tx) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tx.$1,
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(tx.$2,
                        style: TextStyle(
                            color: tx.$3 ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      (Icons.account_balance_wallet_outlined, 'Portefeuille Sécurisé',
          'Stockez votre argent en toute sécurité. PIN et authentification requis pour chaque transaction.'),
      (Icons.send_outlined, 'Transferts Instantanés',
          'Envoyez de l\'argent à n\'importe quel numéro ValPay en quelques secondes.'),
      (Icons.phone_android_outlined, 'Forfaits Télécom',
          'Achetez vos forfaits Orange et MTN directement depuis votre solde, sans frais supplémentaires.'),
      (Icons.qr_code_outlined, 'Paiement par QR',
          'Générez votre QR code ou lien de paiement unique pour recevoir de l\'argent en un scan.'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        children: [
          const Text('Pourquoi ValPay ?',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: features
                .map((f) => SizedBox(
                      width: 260,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(f.$1, color: AppColors.primaryLight, size: 26),
                          ),
                          const SizedBox(height: 12),
                          Text(f.$2,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(f.$3,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.5)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    final rows = [
      ('Recharge (CamPay)', 'Gratuit — 0%', true),
      ('Transfert P2P', '1% à la charge de l\'envoyeur', false),
      ('Retrait vers Mobile Money', '1% sur le montant retiré', false),
      ('Achat forfait télécom', 'Gratuit — 0%', true),
    ];

    return Container(
      color: AppColors.accentLight,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        children: [
          const Text('Tarification transparente',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Pas de frais cachés. Pas de surprises.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: rows.asMap().entries.map((e) {
                final isLast = e.key == rows.length - 1;
                final row = e.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(row.$1, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            row.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: row.$3 ? AppColors.success : AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('© 2025 ValPay. Tous droits réservés.',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/privacy'),
                child: const Text('Confidentialité',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/terms'),
                child: const Text('CGU',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
