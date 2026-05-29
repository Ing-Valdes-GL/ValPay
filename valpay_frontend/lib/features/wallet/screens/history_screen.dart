import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Map<String, dynamic>> _transactions = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _selectedType;
  final _scrollCtrl = ScrollController();

  static const _typeFilters = <String?, String>{
    null: 'Tout',
    'deposit': 'Recharge',
    'withdrawal': 'Retrait',
    'p2p_transfer': 'Transfert',
    'airtime_purchase': 'Forfait',
  };

  static const _typeLabels = {
    'deposit': 'Recharge',
    'withdrawal': 'Retrait',
    'p2p_transfer': 'Transfert',
    'airtime_purchase': 'Forfait',
  };

  static const _statusColors = {
    'completed': AppColors.success,
    'pending': AppColors.warning,
    'failed': AppColors.error,
  };

  static const _statusLabels = {
    'completed': 'Complété',
    'pending': 'En cours',
    'failed': 'Échoué',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120) {
        if (!_loading && _hasMore) _load();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _page = 1;
      _transactions.clear();
      _hasMore = true;
    }
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{'page': _page};
      if (_selectedType != null) params['type'] = _selectedType;
      final resp = await ApiClient.instance.dio.get('/wallet/transactions', queryParameters: params);
      final data = resp.data as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(data['data'] ?? []);
      if (mounted) {
        setState(() {
          _transactions.addAll(items);
          _hasMore = data['next_page_url'] != null;
          _page++;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _typeFilters.entries.map((e) {
          final selected = _selectedType == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(e.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  )),
              selected: selected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.background,
              checkmarkColor: Colors.white,
              side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.divider),
              onSelected: (_) {
                setState(() => _selectedType = e.key);
                _load(reset: true);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Aucune transaction',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _transactions.length + (_hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _transactions.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildTile(_transactions[i]);
        },
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> tx) {
    final fmt = NumberFormat('#,##0', 'fr_CM');
    final dateFmt = DateFormat('dd/MM/yy HH:mm');
    final isDebit = tx['type'] != 'deposit';
    final status = tx['status'] as String? ?? 'pending';
    final statusColor = _statusColors[status] ?? AppColors.textSecondary;
    final createdAt = tx['created_at'] != null
        ? DateTime.tryParse(tx['created_at'].toString())?.toLocal()
        : null;
    final amount = double.tryParse(tx['amount'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        title: Row(
          children: [
            Text(_typeLabels[tx['type']] ?? (tx['type'] ?? ''),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _statusLabels[status] ?? status,
                style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(tx['reference'] ?? '',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            if (createdAt != null)
              Text(dateFmt.format(createdAt),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
        trailing: Text(
          '${isDebit ? '-' : '+'} ${fmt.format(amount)} FCFA',
          style: TextStyle(
            color: isDebit ? AppColors.error : AppColors.success,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
