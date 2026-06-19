import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dossiers/data/remote_datasource.dart';
import '../../../../core/network/dio_client.dart';

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  try {
    final client = ref.read(dioClientProvider);
    final ds = DossiersRemoteDatasource(client: client);
    final dossiers = await ds.getDossiers();
    final enCours = dossiers.where((d) =>
        d.status != 'pret' && d.status != 'rejete').length;
    return HomeStats(dossiersEnCours: enCours, totalDossiers: dossiers.length);
  } catch (_) {
    return const HomeStats(dossiersEnCours: 0, totalDossiers: 0);
  }
});

class HomeStats {
  final int dossiersEnCours;
  final int totalDossiers;
  const HomeStats({required this.dossiersEnCours, required this.totalDossiers});
}
