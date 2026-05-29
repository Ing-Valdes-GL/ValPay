import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

enum _Mode { loading, set, change, success }

class _PinSetupScreenState extends State<PinSetupScreen> {
  _Mode _mode = _Mode.loading;
  bool _loading = false;
  String? _error;

  // Contrôleurs pour les 3 champs PIN (actuel / nouveau / confirmation)
  final _currentCtrl  = TextEditingController();
  final _newCtrl      = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  // Focus
  final _currentFocus  = FocusNode();
  final _newFocus      = FocusNode();
  final _confirmFocus  = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final resp = await ApiClient.instance.dio.get('/auth/me');
      final hasPin = resp.data['has_pin'] == true;
      setState(() => _mode = hasPin ? _Mode.change : _Mode.set);
    } catch (_) {
      setState(() => _mode = _Mode.set);
    }
  }

  Future<void> _submit() async {
    setState(() { _error = null; _loading = true; });

    final newPin     = _newCtrl.text;
    final confirmPin = _confirmCtrl.text;
    final currentPin = _currentCtrl.text;

    // Validations locales
    if (_mode == _Mode.change && currentPin.length != 4) {
      setState(() { _error = 'Saisissez votre PIN actuel (4 chiffres)'; _loading = false; });
      return;
    }
    if (newPin.length != 4) {
      setState(() { _error = 'Le nouveau PIN doit contenir 4 chiffres'; _loading = false; });
      return;
    }
    if (newPin != confirmPin) {
      setState(() { _error = 'Les deux PIN ne correspondent pas'; _loading = false; });
      return;
    }
    if (_mode == _Mode.change && newPin == currentPin) {
      setState(() { _error = 'Le nouveau PIN doit être différent de l\'actuel'; _loading = false; });
      return;
    }

    try {
      if (_mode == _Mode.set) {
        await ApiClient.instance.dio.post('/auth/pin/set', data: {
          'pin': newPin,
          'pin_confirmation': confirmPin,
        });
      } else {
        await ApiClient.instance.dio.put('/auth/pin/update', data: {
          'current_pin': currentPin,
          'pin': newPin,
          'pin_confirmation': confirmPin,
        });
      }
      setState(() { _mode = _Mode.success; _loading = false; });
    } catch (e) {
      String msg = 'Une erreur est survenue. Réessayez.';
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'] as String;
        } else if (data is Map && data['errors'] != null) {
          final errors = data['errors'] as Map;
          msg = errors.values.first.first as String;
        }
      } catch (_) {}
      setState(() { _error = msg; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_mode == _Mode.change ? 'Modifier le PIN' : 'Code PIN'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case _Mode.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(64),
            child: CircularProgressIndicator(),
          ),
        );
      case _Mode.success:
        return _buildSuccess();
      case _Mode.set:
      case _Mode.change:
        return _buildForm();
    }
  }

  Widget _buildForm() {
    final isChange = _mode == _Mode.change;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isChange ? Icons.lock_reset_outlined : Icons.lock_outline,
              color: AppColors.primary, size: 36,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            isChange ? 'Modifier votre code PIN' : 'Définir votre code PIN',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            isChange
                ? 'Entrez votre PIN actuel puis définissez le nouveau.'
                : 'Le PIN sécurise vos virements et retraits.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        const SizedBox(height: 36),

        if (isChange) ...[
          _pinField(
            label: 'PIN actuel',
            controller: _currentCtrl,
            focusNode: _currentFocus,
            nextFocus: _newFocus,
          ),
          const SizedBox(height: 24),
        ],

        _pinField(
          label: 'Nouveau PIN',
          controller: _newCtrl,
          focusNode: _newFocus,
          nextFocus: _confirmFocus,
        ),
        const SizedBox(height: 24),

        _pinField(
          label: 'Confirmer le nouveau PIN',
          controller: _confirmCtrl,
          focusNode: _confirmFocus,
          nextFocus: null,
          onComplete: _submit,
        ),

        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    isChange ? 'Modifier le PIN' : 'Définir mon PIN',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le PIN est chiffré et jamais stocké en clair. '
                  'Il sera demandé à chaque virement et retrait.',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pinField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? nextFocus,
    VoidCallback? onComplete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        // Rangée de 4 cases OTP
        GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(focusNode),
          child: Stack(
            children: [
              // Champ caché qui reçoit la saisie
              SizedBox(
                height: 0,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    setState(() => _error = null);
                    if (v.length == 4) {
                      if (nextFocus != null) {
                        FocusScope.of(context).requestFocus(nextFocus);
                      } else {
                        focusNode.unfocus();
                        onComplete?.call();
                      }
                    }
                  },
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                ),
              ),
              // Affichage des 4 cases
              ListenableBuilder(
                listenable: controller,
                builder: (_, __) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (i) {
                      final filled = i < controller.text.length;
                      final isCurrent = i == controller.text.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 68,
                        height: 64,
                        decoration: BoxDecoration(
                          color: filled
                              ? AppColors.primary.withOpacity(0.08)
                              : AppColors.surface,
                          border: Border.all(
                            color: isCurrent && focusNode.hasFocus
                                ? AppColors.primary
                                : filled
                                    ? AppColors.primary.withOpacity(0.4)
                                    : AppColors.divider,
                            width: isCurrent && focusNode.hasFocus ? 2 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: filled
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : isCurrent && focusNode.hasFocus
                                  ? Container(
                                      width: 2,
                                      height: 24,
                                      color: AppColors.primary,
                                    )
                                  : null,
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final isChange = _currentCtrl.text.isNotEmpty;
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
          child: const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          isChange ? 'PIN modifié !' : 'PIN défini !',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
              color: AppColors.success),
        ),
        const SizedBox(height: 10),
        Text(
          isChange
              ? 'Votre code PIN a été mis à jour avec succès.'
              : 'Votre compte est maintenant sécurisé.\nVous pouvez effectuer des virements et retraits.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Retour au tableau de bord',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        if (!isChange)
          OutlinedButton(
            onPressed: () => setState(() {
              _mode = _Mode.change;
              _currentCtrl.clear();
              _newCtrl.clear();
              _confirmCtrl.clear();
            }),
            child: const Text('Modifier le PIN'),
          ),
      ],
    );
  }
}
