/// Implémentation de repli (plateforme non supportée).
Future<String> savePdf(List<int> bytes, String filename) async {
  throw UnsupportedError('Téléchargement PDF non supporté sur cette plateforme.');
}
