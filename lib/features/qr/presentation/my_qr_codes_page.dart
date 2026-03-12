import 'dart:math';

import '../../../core/theme/colors.dart';
import '../../layout/custom_appbar.dart';
import '../data/qr_repository.dart';
import '../domain/saved_qr.dart';
import '../../reserve/presentation/reservation_qr_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyQrCodesPage extends StatefulWidget {
  const MyQrCodesPage({super.key});

  @override
  State<MyQrCodesPage> createState() => _MyQrCodesPageState();
}

class _MyQrCodesPageState extends State<MyQrCodesPage> {
  final QrRepository _storage = QrRepository();
  List<SavedQr> _entries = [];
  SavedQrType _filter = SavedQrType.reservation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _storage.fetchAll();
    setState(() {
      _entries = items;
      if (items.isNotEmpty) _filter = items.first.type;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _entries
        .where((e) => e.type == _filter)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: MyColors.bgPrimary,
      appBar: CustomAppbar(
        needElevation: false,
        color: MyColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My QR Codes',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 26,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeChips(
              selected: _filter,
              onSelect: (t) => setState(() => _filter = t),
            ),
            const SizedBox(height: 100),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: MyColors.primaryBlue),
              )
            else if (filtered.isEmpty)
              Center(
                child: Text(
                  'No QR codes yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _QrCard(entry: filtered[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({required this.selected, required this.onSelect});

  final SavedQrType selected;
  final ValueChanged<SavedQrType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      mainAxisAlignment: MainAxisAlignment.center,
      children: SavedQrType.values.map((type) {
        final isSelected = type == selected;
        final label = type == SavedQrType.reservation ? 'Reservation' : 'Order';
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onSelect(type),
            child: Container(
              width: 140,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? MyColors.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(142),
                border: Border.all(color: MyColors.primaryBlue, width: 0.4),
              ),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontSize: 16,
                    color: isSelected ? Colors.white : MyColors.primaryGrey,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.entry});

  final SavedQr entry;

  @override
  Widget build(BuildContext context) {
    final isReservation = entry.type == SavedQrType.reservation;
    final dateLabel = isReservation
        ? _formatDateDetail(entry.data.details)
        : DateFormat('MMM dd').format(entry.created);
    final tableDetail = entry.data.details.firstWhere(
      (d) => d.label.toLowerCase().contains('table'),
      orElse: () => const QrDetailItem(label: '', value: ''),
    );
    final itemsCount = entry.data.orderItemsCount ?? 0;
    final total = entry.data.orderTotal ?? 0;
    final titleText = isReservation
        ? 'Table: ${tableDetail.value}'
        : 'Items: $itemsCount';
    final subtitleOrder = 'Total: \$${total.toStringAsFixed(2)}  $dateLabel';

    return Container(
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(right: 10, top: 10, child: _StatusChip(entry: entry)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: MyColors.primaryLightBlue,
                  ),
                ),
                const SizedBox(height: 6),
                if (isReservation)
                  RichText(
                    text: TextSpan(
                      text: 'Date & time: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MyColors.primaryGrey,
                      ),
                      children: [
                        TextSpan(
                          text: dateLabel,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    subtitleOrder,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MyColors.primaryGrey,
                    ),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 200,
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () => _showQrDialog(context, entry),
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF003A99), Color(0xFF5F3AFF)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(23)),
                      ),
                      child: Center(
                        child: Text(
                          isReservation
                              ? 'View Reservation QR'
                              : 'View Order QR',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateDetail(List<QrDetailItem> details) {
    final item = details.firstWhere(
      (d) => d.label.toLowerCase().contains('date'),
      orElse: () => const QrDetailItem(label: '', value: ''),
    );
    if (item.value.isEmpty) return '';
    if (item.value.contains(',')) {
      final parts = item.value.split(',');
      if (parts.length >= 2) {
        final left = parts[0].trim();
        final right = parts.sublist(1).join(',').trim();
        return '$left · $right';
      }
    }
    return item.value;
  }

  Future<void> _showQrDialog(BuildContext context, SavedQr entry) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                padding: const EdgeInsets.fromLTRB(30, 45, 30, 20),
                decoration: BoxDecoration(
                  color: MyColors.bgSecondary,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: MyColors.primaryBlue, width: 0.4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 240,
                          child: Image.asset('assets/images/ramka.png'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: QrImageView(
                            data: _getId(),
                            size: 210,
                            backgroundColor: Colors.transparent,
                            version: QrVersions.auto,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.white,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 41),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Ink(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(118),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF003A99),
                                Color(0xFF006BFF),
                                Color(0xFF00A5FF),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Back',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge!.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.entry});

  final SavedQr entry;

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatus(entry);
    final config = _mapStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        config.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: config.textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

enum QrStatus { active, upcoming, expired, pending, inProgress, completed }

DateTime? _parseReservationDate(SavedQr entry) {
  try {
    final dateItem = entry.data.details.firstWhere(
      (d) => d.label.toLowerCase().contains('date'),
    );

    return DateFormat('MMM dd, HH:mm').parse(dateItem.value);
  } catch (_) {
    return null;
  }
}

({String label, Color bgColor, Color textColor}) _mapStatus(QrStatus status) {
  switch (status) {
    case QrStatus.active:
      return (
        label: 'Active',
        bgColor: MyColors.success,
        textColor: Colors.black,
      );

    case QrStatus.upcoming:
      return (
        label: 'Upcoming',
        bgColor: Color(0xFFFF9A3E),
        textColor: Colors.black,
      );

    case QrStatus.expired:
      return (
        label: 'Expired',
        bgColor: MyColors.redError,
        textColor: Colors.white,
      );

    case QrStatus.pending:
      return (
        label: 'Pending',
        bgColor: const Color(0xFFFF9A3E),
        textColor: Colors.black,
      );

    case QrStatus.inProgress:
      return (
        label: 'In progress',
        bgColor: const Color(0xFF5F3AFF),
        textColor: Colors.white,
      );

    case QrStatus.completed:
      return (
        label: 'Completed',
        bgColor: MyColors.primaryGrey2,
        textColor: Colors.white,
      );
  }
}

QrStatus _resolveStatus(SavedQr entry) {
  final now = DateTime.now();

  if (entry.type == SavedQrType.reservation) {
    final dateTime = _parseReservationDate(entry);

    if (dateTime == null) return QrStatus.expired;

    if (dateTime.isAfter(now)) return QrStatus.upcoming;

    final diff = now.difference(dateTime);
    if (diff.inHours < 2) return QrStatus.active;

    return QrStatus.expired;
  }

  final created = entry.created;
  final diff = now.difference(created);
  if (diff.inMinutes < 5) return QrStatus.pending;
  if (diff.inMinutes < 30) return QrStatus.active;
  if (diff.inHours < 2) return QrStatus.inProgress;

  return QrStatus.completed;
}

String _getId() {
  var res = Random().nextInt(9999) + 1000;
  return res.toString();
}
