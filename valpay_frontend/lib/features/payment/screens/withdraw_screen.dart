import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants.dart';
import '../../../core/api/api_client.dart';
import 'package:intl/intl.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+237');
  final _amountCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  bool _pinObscure = true;

  final _fmt = NumberFormat('#,###', 'fr_FR');

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;
  double get _fee => _amount * AppConstants.withdrawFeeRate;
  double get _total => _amount + _fee;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.dio.post('/payments/withdraw', data: {
        'phone': _phoneCtrl.text.trim(),
        'amount': _amount,
        'pin': _pinCtrl.text,
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8F5E9),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 44),
                ),
                const SizedBox(height: 16),
                const Text('Retrait initié !',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${_fmt.format(_amount.toInt())} FCFA vers ${_phoneCtrl.text.trim()}.\nLes fonds seront crédités sous quelques minutes.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Réf: ${response.data['transaction']?['reference'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      String msg = 'Une erreur est survenue';
      try {
        // Extract actual server message from DioException
        final dioErr = e as dynamic;
        final data = dioErr.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'] as String;
        } else if (data is Map && data['errors'] != null) {
          final errors = data['errors'] as Map;
          msg = errors.values.first.first as String;
        }
      } catch (_) {
        msg = e.toString().replaceAll('Exception: ', '');
      }
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
      appBar: AppBar(
        title: const Text('Retrait Mobile Money'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info frais
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Frais de retrait : 1% déduit de votre portefeuille.',
                        style: TextStyle(color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Numéro
              const Text('Numéro Mobile Money destinataire',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+237 6XX XXX XXX',
                ),
                validator: (v) =>
                    v == null || !RegExp(r'^\+237[0-9]{9}$').hasMatch(v)
                        ? 'Format invalide'
                        : null,
              ),
              const SizedBox(height: 20),

              // Montant
              const Text('Montant à retirer (FCFA)',
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
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final a = double.tryParse(v ?? '');
                  if (a == null || a < AppConstants.minWithdrawalAmount) {
                    return 'Minimum ${AppConstants.minWithdrawalAmount.toInt()} FCFA';
                  }
                  return null;
                },
              ),

              // Récapitulatif frais
              if (_amount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _feeRow('Montant envoyé', '${_fmt.format(_amount.toInt())} FCFA'),
                      const SizedBox(height: 6),
                      _feeRow('Frais (1%)', '${_fmt.format(_fee.toInt())} FCFA',
                          color: AppColors.error),
                      const Divider(height: 16),
                      _feeRow('Total débité', '${_fmt.format(_total.toInt())} FCFA',
                          bold: true),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // PIN
              const Text('Code PIN de transaction',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pinCtrl,
                obscureText: _pinObscure,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  counterText: '',
                  hintText: '••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _pinObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _pinObscure = !_pinObscure),
                  ),
                ),
                validator: (v) =>
                    v == null || v.length != 4 ? 'PIN à 4 chiffres requis' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.arrow_circle_down_outlined),
                  label: const Text('Retirer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feeRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}
