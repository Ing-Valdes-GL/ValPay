import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';

class TelecomScreen extends StatefulWidget {
  const TelecomScreen({super.key});

  @override
  State<TelecomScreen> createState() => _TelecomScreenState();
}

class _TelecomScreenState extends State<TelecomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedOperator = 'orange_cm';
  List<dynamic> _plans = [];
  bool _loading = false;

  final _operators = [
    {'slug': 'orange_cm', 'name': 'Orange', 'color': const Color(0xFFFF6600)},
    {'slug': 'mtn_cm', 'name': 'MTN', 'color': const Color(0xFFFFCC00)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.dio
          .get('/telecom/plans', queryParameters: {'operator': _selectedOperator});
      setState(() => _plans = response.data['plans'] ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forfaits Télécom'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Internet'), Tab(text: 'Appels')],
        ),
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Sélecteur opérateur
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _operators
                  .map((op) => Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedOperator = op['slug'] as String);
                            _loadPlans();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedOperator == op['slug']
                                  ? (op['color'] as Color).withOpacity(0.15)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedOperator == op['slug']
                                    ? op['color'] as Color
                                    : AppColors.divider,
                                width: _selectedOperator == op['slug'] ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: op['color'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (op['name'] as String)[0],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(op['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Liste des forfaits
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _plans.isEmpty
                    ? const Center(
                        child: Text('Aucun forfait disponible',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _plans.length,
                        itemBuilder: (context, i) => _buildPlanCard(_plans[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final fmt = NumberFormat('#,##0', 'fr_CM');
    final price = double.tryParse(plan['localAmount']?.toString() ?? '0') ?? 0;
    final op = _operators.firstWhere((o) => o['slug'] == _selectedOperator);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (op['color'] as Color).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.signal_cellular_alt, color: op['color'] as Color),
        ),
        title: Text(plan['description'] ?? 'Forfait',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          plan['validity'] != null ? 'Validité: ${plan['validity']}' : '',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${fmt.format(price)} FCFA',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 15),
            ),
            GestureDetector(
              onTap: () => _showPurchaseDialog(plan, price),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Acheter',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDialog(Map<String, dynamic> plan, double price) {
    final phoneCtrl = TextEditingController(text: '+237');
    final pinCtrl = TextEditingController();
    final fmt = NumberFormat('#,##0', 'fr_CM');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Acheter "${plan['description']}"',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${fmt.format(price)} FCFA',
                style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro à créditer',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Code PIN',
                prefixIcon: Icon(Icons.lock_outline),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ApiClient.instance.dio.post('/telecom/purchase', data: {
                      'operator': _selectedOperator,
                      'operator_id': plan['id'] ?? plan['operatorId'],
                      'amount': price,
                      'phone': phoneCtrl.text,
                      'pin': pinCtrl.text,
                      'plan_name': plan['description'],
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Forfait activé avec succès !'),
                            backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: const Text('Confirmer l\'achat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
