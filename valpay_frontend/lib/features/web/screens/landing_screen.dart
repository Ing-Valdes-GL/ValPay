import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isWide = w > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, isMobile),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(context, isWide, isMobile),
            _buildFeatures(isMobile),
            _buildPricingSection(isMobile),
            _buildFooter(context, isMobile),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isMobile) {
    return AppBar(
      backgroundColor: AppColors.primary,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('VP',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('ValPay',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      actions: [
        if (!isMobile) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/privacy'),
            child: const Text('Confidentialité',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          const SizedBox(width: 4),
        ],
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Connexion',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, bool isWide, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 48 : 80,
        horizontal: isMobile ? 20 : 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2247), Color(0xFF1A3A6B), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: _heroText(context, isMobile)),
                const SizedBox(width: 60),
                _heroVisual(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroText(context, isMobile),
                if (!isMobile) ...[
                  const SizedBox(height: 40),
                  Center(child: _heroVisual()),
                ],
              ],
            ),
    );
  }

  Widget _heroText(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Le portefeuille digital\ndu Cameroun',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 30 : 42,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Rechargez, transférez et retirez via Orange Money, MTN MoMo et Express Union.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isMobile ? 14 : 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: isMobile ? 14 : 16,
              ),
            ),
            child: Text(
              'Créer un compte gratuit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 15 : 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroVisual() {
    return Container(
      width: 260,
      height: 300,
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
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          ...[
            ('Recharge Orange', '+50 000 FCFA', true),
            ('Transfert vers Jean', '-10 100 FCFA', false),
            ('Retrait MTN', '-5 050 FCFA', false),
          ].map((tx) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(tx.$1,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(tx.$2,
                        style: TextStyle(
                            color: tx.$3
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFF87171),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFeatures(bool isMobile) {
    final features = [
      (Icons.account_balance_wallet_outlined, 'Portefeuille Sécurisé',
          'PIN et authentification requis pour chaque transaction.'),
      (Icons.send_outlined, 'Transferts Instantanés',
          'Envoyez de l\'argent à n\'importe quel compte ValPay en secondes.'),
      (Icons.qr_code_outlined, 'Paiement par QR',
          'Générez votre QR code pour recevoir de l\'argent en un scan.'),
      (Icons.shield_outlined, 'Chiffrement TLS',
          'Toutes vos données sont protégées par chiffrement TLS 256-bit.'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: isMobile ? 40 : 64,
          horizontal: isMobile ? 20 : 32),
      child: Column(
        children: [
          Text('Pourquoi ValPay ?',
              style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          SizedBox(height: isMobile ? 32 : 48),
          isMobile
              ? Column(
                  children: features
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _featureCard(f),
                          ))
                      .toList(),
                )
              : Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: features
                      .map((f) => SizedBox(width: 260, child: _featureCard(f)))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _featureCard((IconData, String, String) f) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(f.$1, color: AppColors.primaryLight, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.$2,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(f.$3,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection(bool isMobile) {
    final rows = [
      ('Recharge (CamPay)', 'Gratuit — 0%', true),
      ('Transfert P2P', '1% à la charge de l\'envoyeur', false),
      ('Retrait Mobile Money', '1% sur le montant retiré', false),
    ];

    return Container(
      color: AppColors.accentLight,
      padding: EdgeInsets.symmetric(
          vertical: isMobile ? 40 : 64,
          horizontal: isMobile ? 20 : 32),
      child: Column(
        children: [
          Text('Tarification transparente',
              style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Pas de frais cachés. Pas de surprises.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 15),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 560),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: rows.asMap().entries.map((e) {
                final isLast = e.key == rows.length - 1;
                final row = e.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(row.$1,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14)),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              row.$2,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: row.$3
                                    ? AppColors.success
                                    : AppColors.primaryLight,
                              ),
                              textAlign: TextAlign.end,
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

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.symmetric(
          vertical: 24, horizontal: isMobile ? 20 : 32),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('© 2025 ValPay. Tous droits réservés.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/privacy'),
                      child: const Text('Confidentialité',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/terms'),
                      child: const Text('CGU',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('© 2025 ValPay. Tous droits réservés.',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/privacy'),
                      child: const Text('Confidentialité',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/terms'),
                      child: const Text('CGU',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
