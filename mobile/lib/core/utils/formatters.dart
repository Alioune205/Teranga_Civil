import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

abstract class AppFormatters {
  AppFormatters._();

  static String dateToFrench(DateTime date) => DateFormat('d MMMM yyyy', 'fr_FR').format(date);
  static String dateShort(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  static String dateWithTime(DateTime date) => DateFormat("d MMM yyyy 'à' HH'h'mm", 'fr_FR').format(date);
  static String yearOnly(DateTime date) => DateFormat('yyyy').format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'il y a ${diff.inDays ~/ 7} semaine(s)';
    if (diff.inDays < 365) return 'il y a ${diff.inDays ~/ 30} mois';
    return 'il y a ${diff.inDays ~/ 365} an(s)';
  }

  static String amountFCFA(int amount) {
    final f = NumberFormat('#,###', 'fr_FR').format(amount).replaceAll(',', '\u202f');
    return '$f FCFA';
  }

  static String phoneNumber(String phone) {
    String c = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (c.startsWith('221')) c = c.substring(3);
    if (c.length == 9) {
      return '+221 ${c.substring(0,2)} ${c.substring(2,5)} ${c.substring(5,7)} ${c.substring(7,9)}';
    }
    return phone;
  }

  static String maskPhone(String phone) {
    final parts = phoneNumber(phone).split(' ');
    if (parts.length < 5) return phone;
    return '${parts[0]} ${parts[1]} ${parts[2]} XXX XX ${parts[4]}';
  }

  static String initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String titleCase(String text) => text.split(' ').map((w) =>
      w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');

  static String truncate(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max - 3)}...';

  static String statusLabel(String status) {
    const labels = {
      'soumis': 'Soumis', 'en_verification': 'En vérification',
      'valide': 'Validé', 'pret': 'Prêt', 'rejete': 'Rejeté', 'en_cours': 'En cours',
    };
    return labels[status] ?? titleCase(status.replaceAll('_', ' '));
  }

  static String certTypeLabel(String type) {
    const labels = {
      'naissance': 'Certificat de naissance',
      'deces': 'Certificat de décès',
      'mariage': 'Certificat de mariage',
      'residence': 'Certificat de résidence',
      'other': 'Autre demande',
    };
    return labels[type] ?? titleCase(type);
  }

  static String paymentMethodLabel(String method) {
    const labels = {'wave': 'Wave', 'orange_money': 'Orange Money', 'free_money': 'Free Money'};
    return labels[method] ?? method;
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final limited = digits.length > 9 ? digits.substring(0, 9) : digits;
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class NumericInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    return TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: digits.length));
  }
}

class UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
}
