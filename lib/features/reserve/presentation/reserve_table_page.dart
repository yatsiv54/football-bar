import 'dart:math';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/confirm_button.dart';
import '../../layout/custom_appbar.dart';
import '../../../core/validation/validator.dart';
import '../../qr/data/qr_repository.dart';
import '../../qr/domain/saved_qr.dart';
import '../domain/entities/reservation_details.dart';
import 'reservation_qr_page.dart';
import '../../layout/side_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReserveTablePage extends StatefulWidget {
  const ReserveTablePage({super.key});

  @override
  State<ReserveTablePage> createState() => _ReserveTablePageState();
}

class _ReserveTablePageState extends State<ReserveTablePage> {
  final List<_TableSpot> _tables = const [
    _TableSpot(id: '01', available: true, dx: 0.1, dy: 0.22),
    _TableSpot(id: '02', available: true, dx: 0.37, dy: 0.3),
    _TableSpot(id: '03', available: false, dx: 0.63, dy: 0.3),
    _TableSpot(id: '04', available: true, dx: 0.9, dy: 0.22),
    _TableSpot(id: '05', available: false, dx: 0.22, dy: 0.57),
    _TableSpot(id: '06', available: false, dx: 0.5, dy: 0.64),
    _TableSpot(id: '07', available: true, dx: 0.77, dy: 0.57),
    _TableSpot(id: '08', available: false, dx: 0.05, dy: 0.8),
    _TableSpot(id: '09', available: false, dx: 0.95, dy: 0.8),
  ];

  String? _selectedTable;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  int _guests = 5;
  late final List<DateTime> _dates;
  late final List<DateTime> _timeSlots;
  int? _selectedDateIndex;
  int? _timeIndex;
  final Map<ValidatorType, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _dates = _buildDates();
    _timeSlots = _buildTimeSlots();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<DateTime> _buildDates() {
    final now = DateTime.now();
    return List.generate(7, (i) => DateTime(now.year, now.month, now.day + i));
  }

  List<DateTime> _buildTimeSlots() {
    final now = DateTime.now();
    final nextMinuteBlock = ((now.minute + 29) ~/ 30) * 30;
    final start = nextMinuteBlock == 60
        ? DateTime(now.year, now.month, now.day, now.hour + 1)
        : DateTime(now.year, now.month, now.day, now.hour, nextMinuteBlock);
    return List.generate(9, (i) => start.add(Duration(minutes: i * 30)));
  }

  DateTime _combineDateTime(DateTime date, DateTime timeSlot) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      timeSlot.hour,
      timeSlot.minute,
    );
  }

  void _selectTable(_TableSpot spot) {
    if (!spot.available) return;
    setState(() {
      _selectedTable = spot.id;
      _errors[ValidatorType.table] = null;
    });
  }

  void _changeGuests(int delta) {
    setState(() {
      _guests = max(1, min(10, _guests + delta));
      _errors[ValidatorType.guests] = null;
    });
  }

  void _selectDate(int index) {
    setState(() {
      _selectedDateIndex = index;
      _errors[ValidatorType.date] = null;
    });
  }

  void _selectTime(int index) {
    setState(() {
      _timeIndex = _timeIndex == index ? null : index;
      _errors[ValidatorType.time] = null;
    });
  }

  Future<void> _validateAndSubmit() async {
    final newErrors = <ValidatorType, String?>{};
    newErrors[ValidatorType.table] = Validator.validate(
      type: ValidatorType.table,
      value: _selectedTable,
    );
    newErrors[ValidatorType.name] = Validator.validate(
      type: ValidatorType.name,
      value: _nameController.text,
    );
    newErrors[ValidatorType.phoneNumber] = Validator.validate(
      type: ValidatorType.phoneNumber,
      value: _phoneController.text,
    );
    newErrors[ValidatorType.guests] = Validator.validate(
      type: ValidatorType.guests,
      value: _guests,
    );
    newErrors[ValidatorType.date] = Validator.validate(
      type: ValidatorType.date,
      value: _selectedDateIndex != null ? _dates[_selectedDateIndex!] : null,
    );
    newErrors[ValidatorType.time] = Validator.validate(
      type: ValidatorType.time,
      value: _timeIndex != null ? _timeSlots[_timeIndex!] : null,
    );

    setState(() {
      _errors
        ..clear()
        ..addAll(newErrors);
    });

    if (_errors.values.any((e) => e != null)) return;

    final date = _dates[_selectedDateIndex!];
    final startSlot = _timeSlots[_timeIndex!];

    final start = _combineDateTime(date, startSlot);
    final end = _combineDateTime(
      date,
      startSlot.add(const Duration(minutes: 30)),
    );

    final details = ReservationDetails(
      name: _nameController.text.trim(),
      tableId: _selectedTable!,
      guests: _guests,
      from: start,
      to: end,
    );

    final qrData = QrConfirmData(
      qrData: details.toQrPayload(),
      title: 'Your reservation is',
      highlight: 'confirmed!',
      subtitleSecondary: 'Show this QR to your server.',
      details: [
        QrDetailItem(label: 'Name:', value: details.name),
        QrDetailItem(label: 'Table:', value: '#${details.tableId}'),
        QrDetailItem(label: 'Guests:', value: '${details.guests}'),
        QrDetailItem(label: 'Date & time:', value: details.dateLabel),
      ],
    );

    await QrRepository().save(
      SavedQr(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: SavedQrType.reservation,
        created: DateTime.now(),
        data: qrData,
      ),
    );

    context.push('/reserve/confirmation', extra: qrData);
  }

  @override
  Widget build(BuildContext context) {
    final showDetails = _selectedTable != null;

    return Scaffold(
      backgroundColor: MyColors.bgPrimary,
      appBar: CustomAppbar(
        leading: const SideNavButton(active: SideNavSection.reserve),
        title: Text(
          'Reserve a table',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Tap on a table to select it.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 14),
            _TableMap(
              tables: _tables,
              selectedId: _selectedTable,
              onTap: _selectTable,
              errorText: _errors[ValidatorType.table],
            ),
            const SizedBox(height: 18),
            if (showDetails) ...[
              RichText(
                text: TextSpan(
                  text: 'Selected table: ',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge!.copyWith(fontSize: 16),
                  children: [
                    TextSpan(
                      text: '#$_selectedTable',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontSize: 16,
                        color: MyColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildLabeledField(
                label: 'Name',
                error: _errors[ValidatorType.name],
                child: _buildTextField(
                  controller: _nameController,
                  hint: 'Your name',
                  onChanged: (_) =>
                      setState(() => _errors[ValidatorType.name] = null),
                ),
              ),
              const SizedBox(height: 12),
              _buildLabeledField(
                label: 'Phone',
                error: _errors[ValidatorType.phoneNumber]?.isEmpty == true
                    ? 'Please enter your phone number.'
                    : _errors[ValidatorType.phoneNumber],
                child: _buildTextField(
                  controller: _phoneController,
                  hint: 'Your phone number',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) =>
                      setState(() => _errors[ValidatorType.phoneNumber] = null),
                ),
              ),
              const SizedBox(height: 12),
              _buildLabeledField(
                label: 'Guests',
                error: _errors[ValidatorType.guests],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 0),
                    _GuestStepper(value: _guests, onChanged: _changeGuests),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildLabeledField(
                label: 'Date',
                error: _errors[ValidatorType.date],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    _DateSelector(
                      dates: _dates,
                      selectedIndex: _selectedDateIndex,
                      onSelect: _selectDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildLabeledField(
                label: 'Time',
                error: _errors[ValidatorType.time],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _TimeSelector(
                      slots: _timeSlots,
                      selectedIndex: _timeIndex,
                      onSelect: _selectTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ConfirmButton(
                title: 'Confirm reservation',
                onPressed: () {
                  _validateAndSubmit();
                },
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    List<TextInputFormatter>? inputFormatters,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      inputFormatters: inputFormatters,
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: MyColors.bgPrimary,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0.4),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    String? error,
  }) {
    final errorText = error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            if (errorText != null)
              Text(
                errorText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MyColors.redError,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _TableMap extends StatelessWidget {
  const _TableMap({
    required this.tables,
    required this.selectedId,
    required this.onTap,
    this.errorText,
  });

  final List<_TableSpot> tables;
  final String? selectedId;
  final ValueChanged<_TableSpot> onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    const mapHeight = 320.0;
    const barHeight = 44.0;
    const topPadding = 12.0;
    const bottomPadding = 12.0;
    const tableSize = 60.0;

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        color: MyColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final usableWidth = width - tableSize;
          final usableHeight = height - tableSize;

          return Stack(
            children: [
              Positioned(
                top: topPadding - 10,
                left: (width - 202) / 2,
                child: const _CenteredBar(width: 202, height: barHeight),
              ),
              Positioned(
                top: height - bottomPadding - barHeight,
                left: (width - 110) / 2,
                child: const _CenteredBar(width: 110, height: barHeight),
              ),
              for (final table in tables)
                Positioned(
                  left: table.dx * usableWidth,
                  top: table.dy * usableHeight,
                  child: _TableCircle(
                    spot: table,
                    isSelected: table.id == selectedId,
                    onTap: () => onTap(table),
                  ),
                ),
              if (errorText != null)
                Positioned(
                  top: barHeight + topPadding + 6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      errorText!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CenteredBar extends StatelessWidget {
  const _CenteredBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: MyColors.primaryGrey),
    );
  }
}

class _TableCircle extends StatelessWidget {
  const _TableCircle({
    required this.spot,
    required this.isSelected,
    required this.onTap,
  });

  final _TableSpot spot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double size = 55;
    Color fill;
    fill = spot.available ? MyColors.success : MyColors.redError;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: BoxBorder.all(
            color: isSelected ? MyColors.primaryLightBlue : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            '#${spot.id}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: spot.available ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestStepper extends StatelessWidget {
  const _GuestStepper({required this.value, required this.onChanged});
  final int value;
  final void Function(int delta) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Row(
        children: [
          _StepperButton(
            icon: 'assets/images/icons/min.png',
            onTap: () => onChanged(-1),
          ),
          const SizedBox(width: 15),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.black),
          ),
          const SizedBox(width: 15),
          _StepperButton(
            icon: 'assets/images/icons/plus.png',
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 12,
        width: 12,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Image.asset(icon),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.dates,
    this.selectedIndex,
    required this.onSelect,
  });

  final List<DateTime> dates;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final monthFmt = DateFormat('MMM');
    return SizedBox(
      height: 57,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = selectedIndex != null && index == selectedIndex;
          final day = DateFormat('dd').format(date);
          final month = monthFmt.format(date).toLowerCase();
          return _SelectablePill(
            isSelected: isSelected,
            onTap: () => onSelect(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
                Text(
                  month,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.slots,
    this.selectedIndex,
    required this.onSelect,
  });

  final List<DateTime> slots;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex != null && index == selectedIndex;
          return _SelectablePill(
            isSelected: isSelected,
            onTap: () => onSelect(index),
            child: Center(
              child: Text(
                timeFmt.format(slots[index]),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectablePill extends StatelessWidget {
  const _SelectablePill({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 51,
        decoration: BoxDecoration(
          color: isSelected ? MyColors.primaryBlue : Colors.grey.shade500,
          borderRadius: BorderRadius.circular(11),
        ),
        child: child,
      ),
    );
  }
}

class _TableSpot {
  final String id;
  final bool available;
  final double dx;
  final double dy;
  final double scale;

  const _TableSpot({
    required this.id,
    required this.available,
    required this.dx,
    required this.dy,
    this.scale = 1,
  });
}
