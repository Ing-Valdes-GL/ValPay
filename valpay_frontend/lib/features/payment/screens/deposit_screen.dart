import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants.dart';
import '../../../core/api/api_client.dart';
import 'payment_status_screen.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+237');
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  final _presets = [500.0, 1000.0, 2000.0, 5000.0, 10000.0, 25000.0];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.dio.post('/payments/deposit', data: {
        'phone': _phoneCtrl.text.trim(),
        'amount': double.parse(_amountCtrl.text),
      });
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentStatusScreen(
              reference: response.data['reference'] as String,
              amount: double.parse(_amountCtrl.text),
            ),
          ),
        );
      }
    } catch (e) {
      String msg = 'Une erreur est survenue';
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'] as String;
        } else if (data is Map && data['errors'] != null) {
          final errors = data['errors'] as Map;
          msg = errors.values.first.first as String;
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharger mon compte')),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.success, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Frais de recharge : 0% — Gratuit !',
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Numéro Mobile Money',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+237 6XX XXX XXX',
                ),
                validator: (v) => v == null || !RegExp(r'^\+237[0-9]{9}$').hasMatch(v)
                    ? 'Format invalide'
                    : null,
              ),
              const SizedBox(height: 20),
              const Text('Montant (FCFA)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  suffixText: 'FCFA',
                  hintText: 'ex: 5000',
                ),
                validator: (v) {
                  final amount = double.tryParse(v ?? '');
                  if (amount == null || amount < AppConstants.minDepositAmount) {
                    return 'Minimum ${AppConstants.minDepositAmount.toInt()} FCFA';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Montants rapides
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets
                    .map((p) => GestureDetector(
                          onTap: () => _amountCtrl.text = p.toInt().toString(),
                          child: Chip(
                            label: Text('${p.toInt()} F'),
                            backgroundColor: AppColors.accentLight,
                            labelStyle:
                                const TextStyle(color: AppColors.primaryLight),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.payment),
                  label: const Text('Initier la recharge'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
