enum ValidatorType { table, name, phoneNumber, guests, date, time }

class Validator {
  const Validator._();

  static String? validate({
    required ValidatorType type,
    required dynamic value,
  }) {
    switch (type) {
      case ValidatorType.table:
        return (value as String?) == null
            ? 'Please select a table on the map.'
            : null;
      case ValidatorType.name:
        final name = (value as String?)?.trim() ?? '';
        return name.isEmpty ? 'Please enter your name.' : null;
      case ValidatorType.phoneNumber:
        final phone = (value as String?) ?? '';
        if (phone.trim().isEmpty) return '';

        final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
        final phoneRegex = RegExp(r'^\d{8,15}$');
        if (!phoneRegex.hasMatch(cleaned)) return '';
        return null;
      case ValidatorType.guests:
        final guests = (value as int?) ?? 0;
        return guests <= 0 ? 'Please select the number of guests.' : null;
      case ValidatorType.date:
        return value == null ? 'Please select date.' : null;
      case ValidatorType.time:
        return value == null ? 'Please select time.' : null;
    }
  }
}
