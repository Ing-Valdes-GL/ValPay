import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

enum _Status { checking, pending, completed, failed, timeout }

class PaymentStatusScreen extends StatefulWidget {
  final String reference;
  final double amount;

  const PaymentStatusScreen({
    super.key,
    required this.reference,
    required this.amount,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen>
    with SingleTickerProviderStateMixin {
  _Status _status = _Status.checking;
  late AnimationController _pulseCtrl;
  Timer? _pollTimer;
  int _attempts = 0;
  static const _maxAttempts = 24; // 2 min @ 5s intervals

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    _checkStatus(); // immediate first check
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkStatus());
  }

  int _failedCount = 0;

  Future<void> _checkStatus() async {
    if (_attempts >= _maxAttempts) {
      _pollTimer?.cancel();
      setState(() => _status = _Status.timeout);
      return;
    }
    _attempts++;

    try {
      final response = await ApiClient.instance.dio
          .get('/wallet/transactions/${widget.reference}');
      final status = response.data['status'] as String?;

      if (status == 'completed') {
        _pollTimer?.cancel();
        _failedCount = 0;
        setState(() => _status = _Status.completed);
      } else if (status == 'failed') {
        // CamPay sometimes sends 'failed' then 'successful' — keep polling
        // for up to 4 more cycles before giving up
        _failedCount++;
        if (_failedCount >= 4) {
          _pollTimer?.cancel();
          setState(() => _status = _Status.failed);
        } else {
          setState(() => _status = _Status.pending);
        }
      } else {
        setState(() => _status = _Status.pending);
      }
    } catch (e) {
      // 404 = transitioning between pending→completed, keep polling
      setState(() => _status = _Status.pending);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _status != _Status.pending && _status != _Status.checking,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Vérification du paiement'),
          automaticallyImplyLeading: _status == _Status.completed ||
              _status == _Status.failed ||
              _status == _Status.timeout,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _Status.checking:
      case _Status.pending:
        return _buildPending();
      case _Status.completed:
        return _buildCompleted();
      case _Status.failed:
        return _buildFailed();
      case _Status.timeout:
        return _buildTimeout();
    }
  }

  Widget _buildPending() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing circle
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1 + _pulseCtrl.value * 0.1),
            ),
            child: const Icon(Icons.mobile_friendly,
                color: AppColors.primary, size: 56),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'En attente de confirmation',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          'Composez le code USSD sur votre téléphone et validez le paiement de ${widget.amount.toInt()} FCFA.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tag, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                widget.reference,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Vérification automatique...',
          style: TextStyle(
              fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildCompleted() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE8F5E9),
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        ),
        const SizedBox(height: 28),
        const Text(
          'Paiement confirmé !',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          '${widget.amount.toInt()} FCFA ont été ajoutés à votre portefeuille.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.settings.name == '/dashboard');
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Retour au tableau de bord'),
          ),
        ),
      ],
    );
  }

  Widget _buildFailed() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withOpacity(0.1),
          ),
          child: const Icon(Icons.cancel, color: AppColors.error, size: 60),
        ),
        const SizedBox(height: 28),
        const Text(
          'Paiement non confirmé',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        const Text(
          'Nous n\'avons pas reçu de confirmation. Si votre téléphone a été débité, le crédit arrivera sous peu.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        // Allow user to manually re-check in case webhook was delayed
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _status = _Status.checking;
              _attempts = 0;
              _failedCount = 0;
            });
            _startPolling();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Vérifier à nouveau'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.settings.name == '/dashboard');
            },
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Voir mon solde'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Réessayer le dépôt'),
        ),
      ],
    );
  }

  Widget _buildTimeout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(0.1),
          ),
          child: const Icon(Icons.timer_off_outlined,
              color: Colors.orange, size: 56),
        ),
        const SizedBox(height: 28),
        const Text(
          'Délai expiré',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        const Text(
          'Nous n\'avons pas reçu de confirmation dans les 2 minutes. Vérifiez votre historique pour voir si le paiement a abouti.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.settings.name == '/dashboard');
            },
            icon: const Icon(Icons.history),
            label: const Text('Voir l\'historique'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _status = _Status.checking;
              _attempts = 0;
            });
            _startPolling();
          },
          child: const Text('Vérifier à nouveau'),
        ),
      ],
    );
  }
}
