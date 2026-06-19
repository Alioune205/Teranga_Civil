import React, { useState, useEffect } from 'react';
import { Shield, Building2, Plus, Power, PowerOff } from 'lucide-react';
import api from '@/api/axiosClient';
import { useToast } from '@/components/ui/use-toast';
import WizardNouvelleMairie from '@/components/superadmin/WizardNouvelleMairie';

export default function SuperUserManagement() {
  const [communes, setCommunes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [wizardOpen, setWizardOpen] = useState(false);
  const { toast } = useToast();

  useEffect(() => {
    fetchCommunes();
  }, []);

  const fetchCommunes = async () => {
    try {
      const res = await api.get('/api/dashboard/superadmin/communes/manage/');
      setCommunes(res.data);
    } catch (error) {
      console.error(error);
      toast({ title: 'Erreur', description: 'Impossible de charger les mairies.', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  const toggleStatus = async (id) => {
    try {
      const res = await api.patch(`/api/dashboard/superadmin/communes/${id}/toggle-status/`);
      toast({ title: 'Succès', description: res.data.message });
      fetchCommunes();
    } catch (error) {
      toast({ title: 'Erreur', description: 'Impossible de modifier le statut.', variant: 'destructive' });
    }
  };

  if (loading) return <div className="p-8 text-center text-text-400">Chargement des mairies...</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-text-200 flex items-center gap-2">
            <Building2 className="w-6 h-6 text-primary" /> Mairies et Administrateurs
          </h2>
          <p className="text-sm text-text-400 mt-1">Gérez les communes inscrites sur la plateforme</p>
        </div>
        <button 
          onClick={() => setWizardOpen(true)}
          className="bg-primary text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-primary/90 transition-colors font-medium shadow-sm"
        >
          <Plus className="w-5 h-5" /> Nouvelle Mairie
        </button>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-border-strong overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-text-300">
            <thead className="bg-layer-2 text-text-400 font-medium border-b border-border-strong">
              <tr>
                <th className="px-6 py-4">Commune</th>
                <th className="px-6 py-4">Administrateurs</th>
                <th className="px-6 py-4 text-center">Statut Global</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {communes.map(commune => (
                <tr key={commune.id} className="hover:bg-layer-2 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-bold text-text-200">{commune.name}</div>
                    <div className="text-xs text-text-400">{commune.region} • {commune.department}</div>
                    <div className="text-xs font-mono text-slate-300 mt-1">{commune.code}</div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="space-y-2">
                      {commune.admins.map(admin => (
                        <div key={admin.id} className="flex items-center gap-2">
                          <Shield className={`w-4 h-4 ${admin.role === 'civil_admin_supervisor' ? 'text-amber-500' : 'text-blue-500'}`} />
                          <div>
                            <div className="font-medium text-text-200">{admin.first_name} {admin.last_name}</div>
                            <div className="text-[10px] text-text-400">{admin.email}</div>
                          </div>
                        </div>
                      ))}
                      {commune.admins.length === 0 && <span className="text-text-400 italic">Aucun admin</span>}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-center align-middle">
                    <span className={`px-3 py-1 rounded-full text-xs font-bold ${commune.is_active ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'}`}>
                      {commune.is_active ? 'Actif' : 'Inactif'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right align-middle">
                    <button 
                      onClick={() => toggleStatus(commune.id)}
                      className={`p-2 rounded-lg transition-colors inline-flex items-center justify-center ${commune.is_active ? 'text-red-500 hover:bg-red-50' : 'text-emerald-500 hover:bg-emerald-50'}`}
                      title={commune.is_active ? "Désactiver la commune" : "Activer la commune"}
                    >
                      {commune.is_active ? <PowerOff className="w-5 h-5" /> : <Power className="w-5 h-5" />}
                    </button>
                  </td>
                </tr>
              ))}
              {communes.length === 0 && (
                <tr>
                  <td colSpan="4" className="px-6 py-12 text-center text-text-400">
                    <Building2 className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                    Aucune mairie n'a encore été enregistrée.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <WizardNouvelleMairie 
        isOpen={wizardOpen} 
        onClose={() => setWizardOpen(false)} 
        onSuccess={() => fetchCommunes()} 
      />
    </div>
  );
}
