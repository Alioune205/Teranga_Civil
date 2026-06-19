import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Suivi local et persistant des documents déjà téléchargés.
///
/// Le backend n'enregistre aucun suivi de téléchargement (téléchargements
/// illimités côté serveur). Règle métier appliquée côté mobile : un document
/// prêt ne se télécharge qu'**une seule fois**. On mémorise donc les `id` de
/// dossiers déjà téléchargés dans SharedPreferences.
class DownloadedDocsNotifier extends StateNotifier<Set<String>> {
  DownloadedDocsNotifier() : super(<String>{}) {
    _load();
  }

  static const _key = 'downloaded_dossiers';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_key) ?? const []).toSet();
  }

  bool isDownloaded(String dossierId) => state.contains(dossierId);

  Future<void> markDownloaded(String dossierId) async {
    if (state.contains(dossierId)) return;
    state = {...state, dossierId};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }
}

final downloadedDocsProvider =
    StateNotifierProvider<DownloadedDocsNotifier, Set<String>>(
        (ref) => DownloadedDocsNotifier());
