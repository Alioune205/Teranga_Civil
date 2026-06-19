abstract class Validators {
  Validators._();

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le numéro de téléphone est requis.';
    final cleaned = value.trim().replaceAll(' ', '').replaceAll('-', '');
    final withoutCode = cleaned.replaceFirst('+221', '').replaceFirst('221', '');
    if (withoutCode.length != 9) return 'Entrez un numéro sénégalais valide (9 chiffres).';
    if (!RegExp(r'^[0-9]{9}$').hasMatch(withoutCode)) return 'Le numéro ne doit contenir que des chiffres.';
    if (!RegExp(r'^(7[0-8]|33)').hasMatch(withoutCode)) return 'Préfixe opérateur invalide (70-78 ou 33).';
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.isEmpty) return 'Le code PIN est requis.';
    if (value.length != 6) return 'Le code PIN doit contenir exactement 6 chiffres.';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) return 'Le code PIN ne doit contenir que des chiffres.';
    if (_isTrivialPin(value)) return 'Choisissez un PIN plus sécurisé (évitez 123456, 000000…).';
    return null;
  }

  static String? pinConfirmation(String? value, String originalPin) {
    final pinError = pin(value);
    if (pinError != null) return pinError;
    if (value != originalPin) return 'Les deux codes PIN ne correspondent pas.';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'Le code est requis.';
    if (value.length != 6) return 'Le code doit contenir 6 chiffres.';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) return 'Le code ne doit contenir que des chiffres.';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le nom complet est requis.';
    final trimmed = value.trim();
    if (trimmed.length < 3) return 'Le nom doit contenir au moins 3 caractères.';
    if (trimmed.length > 100) return 'Le nom ne doit pas dépasser 100 caractères.';
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(trimmed)) return 'Le nom ne doit contenir que des lettres.';
    return null;
  }

  static String? registreNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le numéro de registre est requis.';
    final trimmed = value.trim().toUpperCase();
    if (trimmed.length < 5 || trimmed.length > 20) return 'Le numéro doit contenir entre 5 et 20 caractères.';
    if (!RegExp(r'^[A-Z0-9\-\/]+$').hasMatch(trimmed)) return 'Format invalide (lettres, chiffres, - ou /).';
    return null;
  }

  static String? mariageRegistre(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le numéro de registre du mariage est requis.';
    if (value.trim().length < 3) return 'Numéro de registre invalide.';
    return null;
  }

  static String? dateNaissance(DateTime? value) {
    if (value == null) return 'La date de naissance est requise.';
    if (value.isAfter(DateTime.now())) return 'La date ne peut pas être dans le futur.';
    if (DateTime.now().difference(value).inDays ~/ 365 > 120) return 'Date invalide.';
    return null;
  }

  static String? dateDeces(DateTime? value) {
    if (value == null) return 'La date de décès est requise.';
    if (value.isAfter(DateTime.now())) return 'La date ne peut pas être dans le futur.';
    return null;
  }

  static String? anneeMarriage(int? value) {
    if (value == null) return "L'année de mariage est requise.";
    final currentYear = DateTime.now().year;
    if (value < 1900 || value > currentYear) return "L'année doit être entre 1900 et $currentYear.";
    return null;
  }

  static String? region(String? value) => (value == null || value.isEmpty) ? 'Veuillez sélectionner une région.' : null;
  static String? departement(String? value) => (value == null || value.isEmpty) ? 'Veuillez sélectionner un département.' : null;
  static String? commune(String? value) => (value == null || value.isEmpty) ? 'Veuillez sélectionner une commune.' : null;

  static String? required(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName est requis.';
    return null;
  }

  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final v in validators) { final e = v(value); if (e != null) return e; }
      return null;
    };
  }

  static bool _isTrivialPin(String pin) {
    const trivial = ['000000','111111','222222','333333','444444','555555','666666','777777','888888','999999','123456','654321'];
    if (trivial.contains(pin)) return true;
    bool asc = true, desc = true;
    for (int i = 0; i < pin.length - 1; i++) {
      final c = int.parse(pin[i]), n = int.parse(pin[i + 1]);
      if (n != c + 1) asc = false;
      if (n != c - 1) desc = false;
    }
    return asc || desc;
  }
}
