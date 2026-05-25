class FormValidators {
  static final RegExp _nameLettersOnly = RegExp(r"^[\p{L}\s'.-]+$", unicode: true);

  static String sanitizeFullName(String value) {
    return value.replaceAll(RegExp(r'[0-9]'), '');
  }

  static String sanitizePhoneDigitsFixed(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length > 11 ? digits.substring(0, 11) : digits;
  }

  static String? validateFullName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Full name is required.';
    if (RegExp(r'[0-9]').hasMatch(v)) return 'Full name cannot contain numbers.';
    if (!_nameLettersOnly.hasMatch(v)) return 'Use letters and spaces only.';
    if (v.length < 2) return 'Enter your full name.';
    return null;
  }

  static String? validatePhone11(String? value) {
    final v = sanitizePhoneDigitsFixed(value ?? '');
    if (v.isEmpty) return 'Phone number is required.';
    if (v.length != 11) return 'Phone number must be exactly 11 digits.';
    return null;
  }

  /// Matches backend rules: at least 8 chars, one uppercase letter,
  /// and one special (non-alphanumeric) character.
  static String? validatePasswordStrength(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Password must include at least one uppercase letter.';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
      return 'Password must include at least one special character.';
    }
    return null;
  }
}
