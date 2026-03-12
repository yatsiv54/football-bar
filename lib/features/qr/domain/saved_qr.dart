import '../../reserve/presentation/reservation_qr_page.dart';
import 'package:flutter/material.dart';

enum SavedQrType { reservation, order }

class SavedQr {
  final String id;
  final SavedQrType type;
  final DateTime created;
  final QrConfirmData data;

  SavedQr({
    required this.id,
    required this.type,
    required this.created,
    required this.data,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'created': created.toIso8601String(),
    'data': {
      'qrData': data.qrData,
      'title': data.title,
      'highlight': data.highlight,
      'subtitlePrimary': data.subtitlePrimary,
      'subtitleSecondary': data.subtitleSecondary,
      'subtitlePrimaryColor': data.subtitlePrimaryColor?.value,
      'subtitleSecondaryColor': data.subtitleSecondaryColor?.value,
      'buttonLabel': data.buttonLabel,
      'details': data.details
          .map((d) => {'label': d.label, 'value': d.value})
          .toList(),
      'orderTotal': data.orderTotal,
      'orderItemsCount': data.orderItemsCount,
    },
  };

  factory SavedQr.fromMap(Map<String, dynamic> map) {
    final dataMap = map['data'] as Map<String, dynamic>? ?? {};
    final details = (dataMap['details'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (d) => QrDetailItem(
            label: d['label'] as String? ?? '',
            value: d['value'] as String? ?? '',
          ),
        )
        .toList();

    return SavedQr(
      id: map['id'] as String? ?? '',
      type: SavedQrType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => SavedQrType.reservation,
      ),
      created:
          DateTime.tryParse(map['created'] as String? ?? '') ?? DateTime.now(),
      data: QrConfirmData(
        qrData: dataMap['qrData'] as String? ?? '',
        title: dataMap['title'] as String?,
        highlight: dataMap['highlight'] as String?,
        subtitlePrimary: dataMap['subtitlePrimary'] as String?,
        subtitleSecondary: dataMap['subtitleSecondary'] as String?,
        subtitlePrimaryColor: dataMap['subtitlePrimaryColor'] != null
            ? Color(dataMap['subtitlePrimaryColor'] as int)
            : null,
        subtitleSecondaryColor: dataMap['subtitleSecondaryColor'] != null
            ? Color(dataMap['subtitleSecondaryColor'] as int)
            : null,
        buttonLabel: dataMap['buttonLabel'] as String? ?? 'Return Home',
        details: details,
        orderTotal: (dataMap['orderTotal'] as num?)?.toDouble(),
        orderItemsCount: dataMap['orderItemsCount'] as int?,
      ),
    );
  }
}
