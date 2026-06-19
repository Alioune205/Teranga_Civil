import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Mobile/desktop : écrit le PDF puis l'ouvre dans le lecteur du téléphone.
///
/// Sur Android on privilégie le dossier « externe » de l'app (visible dans
/// Fichiers › Android/data/…/files) ; à défaut, le dossier documents privé.
/// Après écriture, on ouvre le fichier (résultat visible immédiat) — sinon le
/// citoyen ne voyait rien malgré un téléchargement réussi.
Future<String> savePdf(List<int> bytes, String filename) async {
  Directory dir;
  try {
    dir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
  } catch (_) {
    dir = await getApplicationDocumentsDirectory();
  }
  final path = '${dir.path}/$filename';
  await File(path).writeAsBytes(bytes, flush: true);

  // Ouvre le PDF avec le lecteur par défaut du téléphone (best-effort).
  try {
    await OpenFilex.open(path);
  } catch (_) {/* l'enregistrement a réussi même si l'ouverture échoue */}

  return path;
}
