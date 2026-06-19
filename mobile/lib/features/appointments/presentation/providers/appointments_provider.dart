import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/remote_datasource.dart';
import '../../data/models/appointment_model.dart';

final appointmentsDsProvider = Provider<AppointmentsRemoteDatasource>((ref) =>
    AppointmentsRemoteDatasource(client: ref.read(dioClientProvider)));

/// Liste des rendez-vous du citoyen connecté.
final appointmentsListProvider =
    FutureProvider.autoDispose<List<AppointmentModel>>((ref) async {
  return ref.read(appointmentsDsProvider).getAppointments();
});
