import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _qrData;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadQrData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadQrData() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.dio.get('/qr/data');
      setState(() => _qrData = response.data);
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2), text: 'Mon QR'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scanner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildMyQrTab(),
          kIsWeb ? _buildWebNoCamera() : _buildScannerTab(),
        ],
      ),
    );
  }

  Widget _buildMyQrTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_qrData == null) {
      return const Center(child: Text('Impossible de charger le QR code'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: QrImageView(
              data: _qrData!['qr_payload'] ?? '',
              version: QrVersions.auto,
              size: 250,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _qrData!['name'] ?? '',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            _qrData!['phone'] ?? '',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Montrez ce QR code pour recevoir un paiement',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (_qrData!['payment_link'] != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: AppColors.primaryLight, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _qrData!['payment_link'],
                      style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return MobileScanner(
      onDetect: (capture) {
        final barcode = capture.barcodes.firstOrNull;
        if (barcode?.rawValue != null) {
          _handleScannedData(barcode!.rawValue!);
        }
      },
    );
  }

  Widget _buildWebNoCamera() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_photography_outlined, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('Le scanner QR n\'est pas disponible sur Web',
              style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 8),
          Text('Utilisez l\'application mobile pour scanner',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  void _handleScannedData(String data) {
    try {
      final payload = Map<String, dynamic>.from(
        (data.startsWith('{')) ? _parseJson(data) : {'raw': data},
      );
      if (payload['type'] == 'valpay_payment') {
        Navigator.of(context).pushNamed('/transfer',
            arguments: {'recipient_phone': payload['phone']});
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code non reconnu')),
      );
    }
  }

  Map<String, dynamic> _parseJson(String data) {
    return Map<String, dynamic>.from(
      (data.replaceAll('{', '').replaceAll('}', '').split(',').fold(
          <String, dynamic>{},
          (map, pair) {
            final parts = pair.split(':');
            if (parts.length >= 2) {
              final key = parts[0].trim().replaceAll('"', '');
              final val = parts.sublist(1).join(':').trim().replaceAll('"', '');
              map[key] = val;
            }
            return map;
          })),
    );
  }
}
