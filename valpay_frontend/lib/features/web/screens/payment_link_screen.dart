import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants.dart';

class PaymentLinkScreen extends StatefulWidget {
  final String walletId;
  const PaymentLinkScreen({super.key, required this.walletId});

  @override
  State<PaymentLinkScreen> createState() => _PaymentLinkScreenState();
}

enum _Step { loading, form, processing, success, error }

class _PaymentLinkScreenState extends State<PaymentLinkScreen> {
  final _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  _Step _step = _Step.loading;
  String? _errorMsg;
  String? _reference;
  String? _ussdCode;

  Map<String, dynamic> _recipient = {};

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+237');
  final _amountCtrl = TextEditingController();

  Timer? _pollTimer;
  int _pollCount = 0;
  static const _maxPolls = 36; // 3 minutes @ 5s

  final _fmt = NumberFormat('#,##0', 'fr_CM');

  @override
  void initState() {
    super.initState();
    _loadRecipient();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecipient() async {
    try {
      final resp = await _dio.get('/pay/${widget.walletId}');
      setState(() {
        _recipient = Map<String, dynamic>.from(resp.data);
        _step = _Step.form;
      });
    } catch (_) {
      setState(() {
        _step = _Step.error;
        _errorMsg = 'Lien de paiement invalide ou expiré.';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = _Step.processing);
    try {
      final resp = await _dio.post('/pay/${widget.walletId}', data: {
        'payer_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'amount': double.parse(_amountCtrl.text.trim()),
      });
      _reference = resp.data['reference'] as String?;
      _ussdCode = resp.data['ussd_code'] as String?;
      _startPolling();
    } catch (e) {
      String msg = 'Une erreur est survenue.';
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map && data['message'] != null) msg = data['message'] as String;
      } catch (_) {}
      setState(() {
        _step = _Step.error;
        _errorMsg = msg;
      });
    }
  }

  void _startPolling() {
    _pollCount = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_reference == null) return;
    _pollCount++;
    try {
      final resp = await _dio.get('/pay/${widget.walletId}/status/$_reference');
      final status = resp.data['status'] as String?;
      if (status == 'completed') {
        _pollTimer?.cancel();
        if (mounted) setState(() => _step = _Step.success);
      } else if (status == 'failed') {
        _pollTimer?.cancel();
        if (mounted) setState(() {
          _step = _Step.error;
          _errorMsg = 'Le paiement a échoué. Vérifiez votre solde Mobile Money et réessayez.';
        });
      } else if (_pollCount >= _maxPolls) {
        _pollTimer?.cancel();
        if (mounted) setState(() {
          _step = _Step.error;
          _errorMsg = 'Délai dépassé. Si vous avez validé le paiement, il sera traité sous quelques minutes.';
        });
      }
    } catch (_) {}
  }

  Future<void> _downloadReceipt() async {
    if (_reference == null) return;
    final url = Uri.parse('${AppConstants.baseUrl}/pay/receipt/$_reference');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Text('Val', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            Text('Pay', style: TextStyle(fontWeight: FontWeight.w300, fontSize: 20)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(64),
            child: CircularProgressIndicator(),
          ),
        );
      case _Step.form:
        return _buildForm();
      case _Step.processing:
        return _buildProcessing();
      case _Step.success:
        return _buildSuccess();
      case _Step.error:
        return _buildError();
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipient card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payer',
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(
                        _recipient['recipient_name'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      if (_recipient['recipient_phone'] != null)
                        Text(_recipient['recipient_phone'],
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.verified_user, color: Colors.white54, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.success, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Frais : 0% — Gratuit. Vous recevrez un push USSD pour valider.',
                    style: TextStyle(color: AppColors.success, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Payer name
          const Text('Votre nom', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Jean Dupont',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Entrez votre nom' : null,
          ),
          const SizedBox(height: 16),

          // Phone
          const Text('Votre numéro Mobile Money',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: '+237 6XX XXX XXX',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Entrez votre numéro';
              final reg = RegExp(r'^\+237[0-9]{9}$');
              if (!reg.hasMatch(v.replaceAll(' ', '')))
                return 'Format requis : +237XXXXXXXXX';
              return null;
            },
            onChanged: (v) {
              if (!v.startsWith('+237')) {
                _phoneCtrl.text = '+237';
                _phoneCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: _phoneCtrl.text.length));
              }
            },
          ),
          const SizedBox(height: 16),

          // Amount
          const Text('Montant (FCFA)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payments_outlined),
              suffixText: 'FCFA',
              hintText: '1000',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Entrez un montant';
              final amount = double.tryParse(v);
              if (amount == null || amount < 100) return 'Montant minimum : 100 FCFA';
              return null;
            },
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Envoyer le paiement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessing() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.warning, strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Paiement en cours…',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_ussdCode != null) ...[
          const Text('Code USSD pour valider manuellement :',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(_ussdCode!,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Validez le push USSD sur votre téléphone.\nNous attendons la confirmation…',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 8),
        if (_reference != null)
          Text('Réf : $_reference',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildSuccess() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
        ),
        const SizedBox(height: 24),
        const Text('Paiement confirmé !',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success)),
        const SizedBox(height: 8),
        Text(
          '${_fmt.format(amount)} FCFA envoyés à ${_recipient['recipient_name'] ?? ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _infoRow('Référence', _reference ?? ''),
              _infoRow('Payeur', _nameCtrl.text),
              _infoRow('Téléphone', _phoneCtrl.text),
              _infoRow('Montant', '${_fmt.format(amount)} FCFA'),
              _infoRow('Bénéficiaire', _recipient['recipient_name'] ?? ''),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _downloadReceipt,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Télécharger le reçu PDF',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ce reçu constitue une preuve de paiement valide.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(Icons.error_outline, color: AppColors.error, size: 48),
        ),
        const SizedBox(height: 24),
        const Text('Échec du paiement',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          _errorMsg ?? 'Une erreur est survenue.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _step = _Step.form;
            _errorMsg = null;
          }),
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
      ],
    );
  }
}
