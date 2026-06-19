/// Sauvegarde d'un PDF, multi-plateforme.
/// - Web : déclenche un téléchargement navigateur (Blob + lien <a>).
/// - Mobile/desktop : écrit le fichier dans le dossier documents de l'app.
///
/// L'implémentation est choisie à la compilation via les imports conditionnels.
library;

export 'pdf_saver_stub.dart'
    if (dart.library.html) 'pdf_saver_web.dart'
    if (dart.library.io) 'pdf_saver_io.dart';
