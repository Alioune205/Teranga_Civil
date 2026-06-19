/// Rendez-vous citoyen (backend apps/appointments).
/// Le citoyen crée une demande (statut `pending`) liée à un dossier ; l'agent
/// fixe la date ensuite (statut `scheduled`).
class AppointmentModel {
  final String id;
  final String status; // pending / scheduled / completed / cancelled
  final DateTime? scheduledDate;
  final String reason;
  final DateTime createdAt;
  final String? dossierReference;
  final String? dossierType;
  final String? agentNom;

  const AppointmentModel({
    required this.id,
    required this.status,
    required this.createdAt,
    this.scheduledDate,
    this.reason = '',
    this.dossierReference,
    this.dossierType,
    this.agentNom,
  });

  /// Libellé FR du statut.
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'scheduled':
        return 'Programmé';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final dossier = json['dossier'];
    String? ref;
    String? type;
    if (dossier is Map<String, dynamic>) {
      ref = dossier['reference'] as String?;
      type = dossier['type'] as String?;
    }
    final agent = json['agent'];
    String? agentNom;
    if (agent is Map<String, dynamic>) {
      agentNom = (agent['full_name'] ?? agent['nom']) as String?;
    }
    final sched = json['scheduled_date'] as String?;
    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      status: json['status'] as String? ?? 'pending',
      scheduledDate: (sched != null) ? DateTime.tryParse(sched) : null,
      reason: json['reason'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      dossierReference: ref,
      dossierType: type,
      agentNom: agentNom,
    );
  }
}
