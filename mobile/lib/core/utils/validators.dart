class Validators {
  Validators._();

  static final _cedulaRegex = RegExp(r'^[VEJPG]-?\d{6,9}$', caseSensitive: false);
  static final _phoneRegex = RegExp(
    r'^(\+58\s?)?0?4[0-9]{2}[\s-]?\d{7}$' // Venezuela: 04XX-XXXXXXX
    r'|^(\+57\s?)?3\d{9}$', // Colombia: 3XX XXXXXXX
  );
  static final _plateRegex = RegExp(r'^[A-Z]{2,3}\d{2,3}[A-Z]{2,3}$', caseSensitive: false);
  static final _referenceRegex = RegExp(r'^\d{8,20}$');
  static final _bankCodeRegex = RegExp(r'^\d{4}$');
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');

  static bool isValidCedula(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return _cedulaRegex.hasMatch(value.trim());
  }

  static bool isValidPhone(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return _phoneRegex.hasMatch(value.trim());
  }

  static bool isValidPlate(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return _plateRegex.hasMatch(value.trim().replaceAll(RegExp(r'[\s-]'), ''));
  }

  static bool isValidReference(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return _referenceRegex.hasMatch(value.trim());
  }

  static bool isValidBankCode(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return _bankCodeRegex.hasMatch(value.trim());
  }

  static bool isValidPassword(String? value) {
    if (value == null || value.length < 8) return false;
    return value.contains(RegExp(r'\d'));
  }

  static bool isValidEmail(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return _emailRegex.hasMatch(value.trim());
  }

  static bool isAdult(DateTime? dob) {
    if (dob == null) return false;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age >= 18;
  }

  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
