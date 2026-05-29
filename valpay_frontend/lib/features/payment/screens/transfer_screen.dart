import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants.dart';
import '../../../core/api/api_client.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+237');
  final _amountCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  bool _pinObscure = true;

  double get _fee {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    return (amount * AppConstants.transferFeeRate);
  }

  double get _total => (double.tryParse(_amountCtrl.text) ?? 0) + _fee;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.dio.post('/payments/transfer', data: {
        'recipient_phone': _phoneCtrl.text.trim(),
        'amount': double.parse(_amountCtrl.text),
        'pin': _pinCtrl.text,
      });
      if (mounted) {
        final fmt = NumberFormat('#,##0', 'fr_CM');
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('Transfert réussi'),
              ],
            ),
            content: Text(
              'Transfert de ${fmt.format(double.parse(_amountCtrl.text))} FCFA effectué avec succès.\n\nRéférence: ${response.data['transaction']['reference']}',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
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
    final fmt = NumberFormat('#,##0', 'fr_CM');

    return Scaffold(
      appBar: AppBar(title: const Text('Envoyer de l\'argent')),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Numéro du destinataire',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: '+237 6XX XXX XXX',
                ),
                validator: (v) => v == null || !RegExp(r'^\+237[0-9]{9}$').hasMatch(v)
                    ? 'Numéro invalide (+237...)'
                    : null,
              ),
              const SizedBox(height: 20),
              const Text('Montant (FCFA)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  suffixText: 'FCFA',
                ),
                validator: (v) {
                  final amount = double.tryParse(v ?? '');
                  if (amount == null || amount < AppConstants.minTransactionAmount) {
                    return 'Minimum ${AppConstants.minTransactionAmount.toInt()} FCFA';
                  }
                  return null;
                },
              ),
              if (_amountCtrl.text.isNotEmpty && double.tryParse(_amountCtrl.text) != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _FeeRow('Montant envoyé', '${fmt.format(double.parse(_amountCtrl.text))} FCFA'),
                      _FeeRow('Frais (1%)', '${fmt.format(_fee)} FCFA'),
                      const Divider(height: 12),
                      _FeeRow(
                        'Total débité',
                        '${fmt.format(_total)} FCFA',
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text('Code PIN', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pinCtrl,
                obscureText: _pinObscure,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: '••••',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(_pinObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _pinObscure = !_pinObscure),
                  ),
                ),
                validator: (v) =>
                    v == null || v.length != 4 ? 'Code PIN à 4 chiffres requis' : null,
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
                      : const Icon(Icons.send),
                  label: const Text('Confirmer le transfert'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _FeeRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: bold ? AppColors.primary : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
