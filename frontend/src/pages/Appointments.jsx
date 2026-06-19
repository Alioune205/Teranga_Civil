// src/pages/Appointments.jsx
import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { getAppointments, scheduleAppointment, cancelAppointment } from '@/api/appointments';
import { getUserList } from '@/api/users';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { toast } from '@/components/ui/use-toast';
import { Loader2, Calendar as CalendarIcon, CheckCircle, XCircle, Clock } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';

const StatusBadge = ({ status }) => {
  const statusConfig = {
    pending: { label: 'En attente', color: 'bg-warning/20 text-warning' },
    scheduled: { label: 'Programmé', color: 'bg-primary/20 text-primary' },
    completed: { label: 'Terminé', color: 'bg-success/20 text-success' },
    cancelled: { label: 'Annulé', color: 'bg-danger/20 text-danger' },
  };
  const config = statusConfig[status] || { label: status, color: 'bg-layer-3 text-text-300' };
  
  return (
    <span className={`px-2.5 py-1 text-xs font-semibold rounded-full ${config.color}`}>
      {config.label}
    </span>
  );
};

export default function Appointments() {
  const { role, user } = useAuth();
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [agents, setAgents] = useState([]);
  
  // Modal state
  const [scheduleModalOpen, setScheduleModalOpen] = useState(false);
  const [cancelModalOpen, setCancelModalOpen] = useState(false);
  const [selectedAppointment, setSelectedAppointment] = useState(null);
  
  // Form state
  const [scheduledDate, setScheduledDate] = useState('');
  const [selectedAgentId, setSelectedAgentId] = useState('');
  const [cancelReason, setCancelReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const isAdmin = ['civil_admin', 'civil_admin_supervisor', 'super_admin'].includes(role);

  useEffect(() => {
    fetchAppointments();
    if (isAdmin) {
      fetchAgents();
    }
  }, [role]);

  const fetchAppointments = async () => {
    try {
      setLoading(true);
      const data = await getAppointments();
      setAppointments(data.results || data);
    } catch (err) {
      toast({ title: 'Erreur', description: 'Impossible de charger les rendez-vous', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  const fetchAgents = async () => {
    try {
      const data = await getUserList({ role: 'agent' });
      setAgents(data.results || data);
    } catch (err) {
      console.error('Erreur agents', err);
    }
  };

  const handleOpenSchedule = (appt) => {
    setSelectedAppointment(appt);
    setScheduledDate('');
    setSelectedAgentId('');
    setScheduleModalOpen(true);
  };

  const handleOpenCancel = (appt) => {
    setSelectedAppointment(appt);
    setCancelReason('');
    setCancelModalOpen(true);
  };

  const onSchedule = async () => {
    if (!scheduledDate) {
      toast({ title: 'Erreur', description: 'Veuillez choisir une date', variant: 'destructive' });
      return;
    }
    
    try {
      setActionLoading(true);
      const payload = {
        scheduled_date: new Date(scheduledDate).toISOString(),
      };
      
      if (isAdmin && selectedAgentId) {
        payload.agent_id = selectedAgentId;
      }
      
      await scheduleAppointment(selectedAppointment.id, payload);
      toast({ title: 'Succès', description: 'Rendez-vous programmé avec succès', variant: 'success' });
      setScheduleModalOpen(false);
      fetchAppointments();
    } catch (err) {
      if (err.response?.status === 403) {
        toast({ title: 'Erreur', description: "Vous n'avez pas l'autorisation d'assigner un agent.", variant: 'destructive' });
      } else {
        toast({ title: 'Erreur', description: 'Erreur lors de la programmation', variant: 'destructive' });
      }
    } finally {
      setActionLoading(false);
    }
  };

  const onCancel = async () => {
    if (!cancelReason) {
      toast({ title: 'Erreur', description: 'Veuillez saisir un motif', variant: 'destructive' });
      return;
    }
    
    try {
      setActionLoading(true);
      await cancelAppointment(selectedAppointment.id, cancelReason);
      toast({ title: 'Succès', description: 'Rendez-vous annulé', variant: 'success' });
      setCancelModalOpen(false);
      fetchAppointments();
    } catch (err) {
      toast({ title: 'Erreur', description: 'Erreur lors de l\'annulation', variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="space-y-6 animate-enter">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-secondary">Gestion des Rendez-vous</h1>
          <p className="text-sm text-text-400 mt-1">Gérez les demandes de rendez-vous des citoyens.</p>
        </div>
      </div>

      <Card className="border-border-subtle shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border-subtle bg-layer-2">
                <th className="p-4 text-xs font-semibold text-text-400 uppercase tracking-wider">Dossier</th>
                <th className="p-4 text-xs font-semibold text-text-400 uppercase tracking-wider">Citoyen</th>
                <th className="p-4 text-xs font-semibold text-text-400 uppercase tracking-wider">Date & Heure</th>
                <th className="p-4 text-xs font-semibold text-text-400 uppercase tracking-wider">Agent assigné</th>
                <th className="p-4 text-xs font-semibold text-text-400 uppercase tracking-wider">Statut</th>
                <th className="p-4 text-xs font-semibold text-text-400 uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan="6" className="p-8 text-center text-text-400">
                    <Loader2 className="h-6 w-6 animate-spin mx-auto mb-2" />
                    Chargement des rendez-vous...
                  </td>
                </tr>
              ) : appointments.length === 0 ? (
                <tr>
                  <td colSpan="6" className="p-8 text-center text-text-400">
                    Aucun rendez-vous trouvé.
                  </td>
                </tr>
              ) : (
                appointments.map((appt) => (
                  <tr key={appt.id} className="hover:bg-layer-2 transition-colors">
                    <td className="p-4">
                      <span className="font-semibold text-secondary">{appt.dossier?.reference}</span>
                    </td>
                    <td className="p-4">
                      <p className="font-medium text-secondary">{appt.citizen?.first_name} {appt.citizen?.last_name}</p>
                      <p className="text-xs text-text-400">{appt.citizen?.email}</p>
                    </td>
                    <td className="p-4">
                      {appt.scheduled_date ? (
                        <span className="text-sm font-medium text-text-200">
                          {new Date(appt.scheduled_date).toLocaleString('fr-FR', {
                            dateStyle: 'medium',
                            timeStyle: 'short'
                          })}
                        </span>
                      ) : (
                        <span className="text-sm text-text-400 italic">Non définie</span>
                      )}
                    </td>
                    <td className="p-4">
                      {appt.agent ? (
                        <span className="text-sm font-medium text-secondary">
                          {appt.agent.first_name} {appt.agent.last_name}
                        </span>
                      ) : (
                        <span className="text-sm text-text-400 italic">Non assigné</span>
                      )}
                    </td>
                    <td className="p-4">
                      <StatusBadge status={appt.status} />
                    </td>
                    <td className="p-4 text-right space-x-2">
                      {appt.status === 'pending' && (
                        <>
                          <Button size="sm" variant="outline" onClick={() => handleOpenSchedule(appt)} className="gap-1 border-primary text-primary hover:bg-primary/10">
                            <CalendarIcon className="w-3.5 h-3.5" /> Planifier
                          </Button>
                          <Button size="sm" variant="outline" onClick={() => handleOpenCancel(appt)} className="gap-1 border-danger text-danger hover:bg-danger/10">
                            <XCircle className="w-3.5 h-3.5" /> Rejeter
                          </Button>
                        </>
                      )}
                      {appt.status === 'scheduled' && (
                        <Button size="sm" variant="outline" onClick={() => handleOpenCancel(appt)} className="gap-1 border-danger text-danger hover:bg-danger/10">
                          <XCircle className="w-3.5 h-3.5" /> Annuler
                        </Button>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Modal Planification */}
      <Dialog open={scheduleModalOpen} onOpenChange={setScheduleModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Programmer le rendez-vous</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label>Date et Heure</Label>
              <Input
                type="datetime-local"
                value={scheduledDate}
                onChange={(e) => setScheduledDate(e.target.value)}
              />
            </div>

            {isAdmin && (
              <div className="space-y-2">
                <Label>Assigner à un agent (Optionnel)</Label>
                <select
                  value={selectedAgentId}
                  onChange={(e) => setSelectedAgentId(e.target.value)}
                  className="flex h-10 w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                >
                  <option value="">-- M'assigner à moi-même --</option>
                  {agents.map(agent => (
                    <option key={agent.id} value={agent.id}>
                      {agent.first_name} {agent.last_name}
                    </option>
                  ))}
                </select>
                <p className="text-xs text-text-400">
                  Si vous sélectionnez un agent, ce dernier recevra une notification lui attribuant ce rendez-vous.
                </p>
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setScheduleModalOpen(false)}>Fermer</Button>
            <Button onClick={onSchedule} disabled={actionLoading} className="gap-2">
              {actionLoading && <Loader2 className="w-4 h-4 animate-spin" />}
              Confirmer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Annulation */}
      <Dialog open={cancelModalOpen} onOpenChange={setCancelModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Annuler le rendez-vous</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label>Motif de l'annulation/rejet</Label>
              <Input
                placeholder="Veuillez préciser le motif..."
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setCancelModalOpen(false)}>Fermer</Button>
            <Button variant="destructive" onClick={onCancel} disabled={actionLoading} className="gap-2">
              {actionLoading && <Loader2 className="w-4 h-4 animate-spin" />}
              Confirmer l'annulation
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
