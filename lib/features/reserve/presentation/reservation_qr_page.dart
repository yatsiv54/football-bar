import 'dart:math';

import '../../../core/di/injection.dart';
import '../../../core/theme/colors.dart';
import '../../menu/domain/services/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrConfirmData {
  final String qrData;
  final String? title;
  final String? highlight;
  final String? subtitlePrimary;
  final String? subtitleSecondary;
  final Color? subtitlePrimaryColor;
  final Color? subtitleSecondaryColor;
  final List<QrDetailItem> details;
  final String buttonLabel;
  final double? orderTotal;
  final int? orderItemsCount;

  const QrConfirmData({
    required this.qrData,
    this.title,
    this.highlight,
    this.subtitlePrimary,
    this.subtitleSecondary,
    this.subtitlePrimaryColor,
    this.subtitleSecondaryColor,
    this.details = const [],
    this.buttonLabel = 'Return Home',
    this.orderTotal,
    this.orderItemsCount,
  });

  Map<String, dynamic> toMap() => {
    'qrData': qrData,
    'title': title,
    'highlight': highlight,
    'subtitlePrimary': subtitlePrimary,
    'subtitleSecondary': subtitleSecondary,
    'subtitlePrimaryColor': subtitlePrimaryColor?.value,
    'subtitleSecondaryColor': subtitleSecondaryColor?.value,
    'buttonLabel': buttonLabel,
    'details': details.map((e) => e.toMap()).toList(),
    'orderTotal': orderTotal,
    'orderItemsCount': orderItemsCount,
  };

  factory QrConfirmData.fromMap(Map<String, dynamic> map) {
    return QrConfirmData(
      qrData: map['qrData'] as String? ?? '',
      title: map['title'] as String?,
      highlight: map['highlight'] as String?,
      subtitlePrimary: map['subtitlePrimary'] as String?,
      subtitleSecondary: map['subtitleSecondary'] as String?,
      subtitlePrimaryColor: map['subtitlePrimaryColor'] != null
          ? Color(map['subtitlePrimaryColor'] as int)
          : null,
      subtitleSecondaryColor: map['subtitleSecondaryColor'] != null
          ? Color(map['subtitleSecondaryColor'] as int)
          : null,
      buttonLabel: map['buttonLabel'] as String? ?? 'Return Home',
      details: (map['details'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(QrDetailItem.fromMap)
          .toList(),
      orderTotal: (map['orderTotal'] as num?)?.toDouble(),
      orderItemsCount: map['orderItemsCount'] as int?,
    );
  }
}

class QrDetailItem {
  final String label;
  final String value;
  const QrDetailItem({required this.label, required this.value});

  Map<String, dynamic> toMap() => {'label': label, 'value': value};

  factory QrDetailItem.fromMap(Map<String, dynamic> map) =>
      QrDetailItem(label: map['label'] ?? '', value: map['value'] ?? '');
}

class QrConfirmPage extends StatelessWidget {
  const QrConfirmPage({super.key, required this.data});

  final QrConfirmData data;

  @override
  Widget build(BuildContext context) {
    final isOrder =
        data.orderItemsCount != null || data.qrData.contains('"type":"order"');

    void goHome() {
      if (isOrder) {
        getIt<CartService>().clear();
      }
      context.go('/home');
    }

    return Scaffold(
      backgroundColor: MyColors.bgPrimary,
      body: Stack(
        children: [
          const _BackgroundBubbles(),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 80),
                        _QrCard(
                          data: data,
                          details: data.details,
                          onHome: goHome,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 35,
                  left: 20,
                  child: IconButton(
                    onPressed: goHome,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 40,
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
}

class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.data,
    required this.onHome,
    this.details = const [],
  });

  final QrConfirmData data;
  final List<QrDetailItem> details;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(22),
        border: BoxBorder.all(color: MyColors.primaryBlue, width: 0.4),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          if (data.title != null || data.highlight != null) ...[
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: data.title ?? '',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                children: data.highlight != null
                    ? [
                        TextSpan(
                          text: ' ${data.highlight}',
                          style: const TextStyle(
                            color: MyColors.primaryLightBlue,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 20),
              child: Stack(
                children: [
                  Image.asset('assets/images/ramka.png'),
                  Positioned(
                    top: 15,
                    left: 15,
                    right: 15,
                    bottom: 15,
                    child: QrImageView(
                      data: _getId(),
                      size: 160,
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
            ),
          ),
          if (data.subtitlePrimary != null || data.subtitleSecondary != null)
            const SizedBox(height: 12),
          if (data.subtitlePrimary != null || data.subtitleSecondary != null)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: data.subtitlePrimary ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: data.subtitlePrimaryColor ?? MyColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  if (data.subtitleSecondary != null)
                    TextSpan(
                      text:
                          '${data.subtitlePrimary != null ? '\n' : ''}${data.subtitleSecondary}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: data.subtitleSecondaryColor ?? Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(height: 20),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DetailsCard(details: details),
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            child: _PrimaryButton(label: data.buttonLabel, onTap: onHome),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.details});

  final List<QrDetailItem> details;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: MyColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 14,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < details.length; i++) ...[
            _DetailRow(
              label: details[i].label,
              value: details[i].value,
              textTheme: textTheme,
            ),
            if (i != details.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.displaySmall?.copyWith(color: MyColors.primaryGrey2),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: textTheme.displaySmall?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(200),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: onTap,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003A99), Color(0xFF006BFF), Color(0xFF00A5FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(200)),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundBubbles extends StatelessWidget {
  const _BackgroundBubbles();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -220,
            top: 30,
            child: _Bubble(
              width: 400,
              height: 400,
              colors: const [
                Color(0xFF003A99),
                Color(0xFF006BFF),
                Color(0xFF00A5FF),
              ],
            ),
          ),
          Positioned(
            left: -140,
            bottom: -70,
            child: _Bubble(
              width: 300,
              height: 300,
              colors: const [
                Color(0xFF003A99),
                Color(0xFF006BFF),
                Color(0xFF00A5FF),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.width,
    required this.height,
    required this.colors,
  });

  final double width;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

String _getId() {
  var res = Random().nextInt(9999) + 1000;
  return res.toString();
}
