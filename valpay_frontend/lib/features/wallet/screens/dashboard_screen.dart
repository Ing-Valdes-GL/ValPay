import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants.dart';
import '../bloc/wallet_bloc.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(WalletLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async => context.read<WalletBloc>().add(WalletLoadRequested()),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildBalanceCard(state),
                  ),
                ),
                SliverToBoxAdapter(child: _buildQuickActions(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transactions récentes',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/history'),
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state is WalletLoaded)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildTransactionTile(state.transactions[i]),
                      childCount: state.transactions.take(5).length,
                    ),
                  )
                else
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(WalletState state) {
    final balance = state is WalletLoaded ? state.balance : 0.0;
    final fmt = NumberFormat('#,##0', 'fr_CM');

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              const Text('Solde disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                child: Icon(
                  _balanceHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _balanceHidden ? '••••••' : '${fmt.format(balance)} FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionItem(icon: Icons.add_circle_outline, label: 'Recharger', color: AppColors.success, route: '/deposit'),
      _ActionItem(icon: Icons.send_outlined, label: 'Envoyer', color: AppColors.primaryLight, route: '/transfer'),
      _ActionItem(icon: Icons.download_outlined, label: 'Retirer', color: AppColors.warning, route: '/withdraw'),
      _ActionItem(icon: Icons.signal_cellular_alt, label: 'Forfaits', color: AppColors.accent, route: '/telecom'),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions
            .map((a) => GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(a.route),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: a.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(a.icon, color: a.color, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(a.label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final fmt = NumberFormat('#,##0', 'fr_CM');
    final isDebit = tx['type'] != 'deposit';
    final typeLabels = {
      'deposit': 'Recharge',
      'withdrawal': 'Retrait',
      'p2p_transfer': 'Transfert',
      'airtime_purchase': 'Forfait',
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (isDebit ? AppColors.error : AppColors.success).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
          color: isDebit ? AppColors.error : AppColors.success,
          size: 20,
        ),
      ),
      title: Text(typeLabels[tx['type']] ?? tx['type'],
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(
        tx['reference'] ?? '',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        '${isDebit ? '-' : '+'} ${fmt.format(double.parse(tx['amount'].toString()))} FCFA',
        style: TextStyle(
          color: isDebit ? AppColors.error : AppColors.success,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _ActionItem({required this.icon, required this.label, required this.color, required this.route});
}
