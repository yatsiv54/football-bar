import 'dart:convert';

import 'package:intl/intl.dart';

class ReservationDetails {
  final String name;
  final String tableId;
  final int guests;
  final DateTime from;
  final DateTime to;

  const ReservationDetails({
    required this.name,
    required this.tableId,
    required this.guests,
    required this.from,
    required this.to,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'tableId': tableId,
        'guests': guests,
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      };

  factory ReservationDetails.fromMap(Map<String, dynamic> map) {
    return ReservationDetails(
      name: map['name'] as String? ?? '',
      tableId: map['tableId'] as String? ?? '',
      guests: map['guests'] as int? ?? 0,
      from: DateTime.parse(map['from'] as String),
      to: DateTime.parse(map['to'] as String),
    );
  }

  String toQrPayload() => jsonEncode(toMap());

  String get dateLabel => DateFormat('MMM dd, HH:mm').format(from);

  String get timeLabel => DateFormat('HH:mm').format(from);
}
