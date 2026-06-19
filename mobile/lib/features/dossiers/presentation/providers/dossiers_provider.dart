import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/remote_datasource.dart';
import '../../data/models/dossier_model.dart';

final dossiersListProvider =
    FutureProvider.autoDispose<List<DossierModel>>((ref) async {
  final ds = DossiersRemoteDatasource(
      client: ref.read(dioClientProvider));
  return ds.getDossiers();
});

final dossierDetailProvider =
    FutureProvider.autoDispose.family<DossierModel, String>((ref, id) async {
  final ds = DossiersRemoteDatasource(
      client: ref.read(dioClientProvider));
  return ds.getDossierById(id);
});

/// Provider pour le téléchargement d'un certificat.
/// Retourne le chemin du fichier téléchargé.
final downloadCertificateProvider = FutureProvider.autoDispose
    .family<String, String>((ref, dossierId) async {
  final ds = DossiersRemoteDatasource(
      client: ref.read(dioClientProvider));
  return ds.downloadCertificate(dossierId);
});
