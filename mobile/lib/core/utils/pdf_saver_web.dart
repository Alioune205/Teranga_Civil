// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web : crée un Blob PDF et déclenche le téléchargement via un lien <a>.
///
/// Le lien est **ajouté au DOM** avant le clic (sinon Firefox ne déclenche
/// rien), puis retiré ; l'URL du blob est révoquée **après un délai** (la
/// révoquer immédiatement après `click()` annule le téléchargement sur
/// certains navigateurs).
Future<String> savePdf(List<int> bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  Future.delayed(const Duration(seconds: 2), () => html.Url.revokeObjectUrl(url));
  return filename;
}
