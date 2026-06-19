import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../dossiers/presentation/providers/dossiers_provider.dart';
import '../../../dossiers/data/models/dossier_model.dart';
import '../providers/appointments_provider.dart';
import '../../data/models/appointment_model.dart';

/// « Mes rendez-vous » : liste des RDV du citoyen + demande d'un nouveau RDV
/// rattaché à l'un de ses dossiers. La date est fixée par la mairie ensuite.
class AppointmentsScreen extends ConsumerWidget {
  final String? preselectedDossierId;
  const AppointmentsScreen({super.key, this.preselectedDossierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAppts = ref.watch(appointmentsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: GestureDetector(
          onTap: () => _openRequestSheet(context, ref),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B285D).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text('Demander un rendez-vous',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // En-tête bleu
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 22),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                const Text('Mes rendez-vous',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
          Expanded(
            child: asyncAppts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                  onRetry: () => ref.invalidate(appointmentsListProvider)),
              data: (list) {
                if (list.isEmpty) return const _EmptyView();
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(appointmentsListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _AppointmentCard(appt: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openRequestSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RequestSheet(preselectedDossierId: preselectedDossierId),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appt;
  const _AppointmentCard({required this.appt});

  Color get _statusColor {
    switch (appt.status) {
      case 'scheduled':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF59E0B); // pending
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_rounded,
                  color: Color(0xFF1B4A9C), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appt.dossierReference ?? 'Dossier',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: Color(0xFF0F172A)),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(appt.statusLabel,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                appt.scheduledDate != null
                    ? AppFormatters.dateWithTime(appt.scheduledDate!)
                    : 'Date à fixer par la mairie',
                style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
          if (appt.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Motif : ${appt.reason}',
                style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontFamily: 'Poppins')),
          ],
        ],
      ),
    );
  }
}

/// Feuille de demande : choisir un dossier + saisir le motif.
class _RequestSheet extends ConsumerStatefulWidget {
  final String? preselectedDossierId;
  const _RequestSheet({this.preselectedDossierId});

  @override
  ConsumerState<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<_RequestSheet> {
  String? _dossierId;
  final _reasonCtr = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _dossierId = widget.preselectedDossierId;
  }

  @override
  void dispose() {
    _reasonCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_dossierId == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(appointmentsDsProvider).createAppointment(
            dossierId: _dossierId!,
            reason: _reasonCtr.text.trim(),
          );
      ref.invalidate(appointmentsListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Demande de rendez-vous envoyée. La mairie fixera la date.'),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final msg = e is ApiException ? e.message : 'Une erreur est survenue.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDossiers = ref.watch(dossiersListProvider);
    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Demander un rendez-vous',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Choisissez le dossier concerné.',
              style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Poppins')),
          const SizedBox(height: 16),
          asyncDossiers.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const Text('Impossible de charger vos dossiers.'),
            data: (dossiers) {
              if (dossiers.isEmpty) {
                return const Text(
                    'Vous n\'avez aucun dossier. Faites d\'abord une demande.');
              }
              return _DossierDropdown(
                dossiers: dossiers,
                value: _dossierId,
                onChanged: (v) => setState(() => _dossierId = v),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonCtr,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Motif (facultatif)',
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  (_dossierId == null || _submitting) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B285D),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Envoyer la demande',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DossierDropdown extends StatelessWidget {
  final List<DossierModel> dossiers;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DossierDropdown({
    required this.dossiers,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: const Text('Sélectionnez un dossier',
              style: TextStyle(fontFamily: 'Poppins')),
          items: dossiers
              .map((d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(
                      '${AppFormatters.certTypeLabel(d.type)} · ${AppFormatters.dateShort(d.createdAt)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Aucun rendez-vous',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            const Text(
              'Demandez un rendez-vous pour suivre un dossier avec la mairie.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined,
              size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text('Impossible de charger les rendez-vous',
              style: TextStyle(fontFamily: 'Poppins')),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
