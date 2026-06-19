import React, { useState, useEffect } from 'react';
import { Building2, Search, ArrowUpDown, ChevronDown } from 'lucide-react';
import api from '@/api/axiosClient';

export default function SuperPerformance() {
  const [communes, setCommunes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    const fetchCommunes = async () => {
      try {
        const res = await api.get('/api/dashboard/superadmin/communes/performance/');
        setCommunes(res.data);
      } catch (error) {
        console.error(error);
      } finally {
        setLoading(false);
      }
    };
    fetchCommunes();
  }, []);

  const filtered = communes.filter(c => c.name.toLowerCase().includes(search.toLowerCase()));

  if (loading) return <div className="p-8 text-center text-text-400">Chargement des performances...</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text-200">Classement des Communes</h1>
          <p className="text-sm text-text-400">Performances détaillées par commune</p>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-border-strong overflow-hidden">
        <div className="p-4 border-b border-border-strong flex items-center justify-between bg-layer-2">
          <div className="relative w-72">
            <Search className="w-4 h-4 text-text-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Rechercher une commune..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2 border border-border-strong rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
            />
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-text-300">
            <thead className="bg-layer-2 text-text-400 font-medium border-b border-border-strong">
              <tr>
                <th className="px-6 py-4">Commune</th>
                <th className="px-6 py-4">Demandes (Total)</th>
                <th className="px-6 py-4 text-emerald-600">Approuvées</th>
                <th className="px-6 py-4 text-red-600">Rejetées</th>
                <th className="px-6 py-4 text-right">Recettes (FCFA)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filtered.map((c, i) => (
                <tr key={c.id} className="hover:bg-layer-2 transition-colors">
                  <td className="px-6 py-4 font-medium text-text-200 flex items-center gap-3">
                    <span className="text-xs font-bold text-text-400 w-4">{i + 1}.</span>
                    {c.name}
                  </td>
                  <td className="px-6 py-4">{c.total_dossiers}</td>
                  <td className="px-6 py-4 text-emerald-600 font-medium">{c.approved_dossiers}</td>
                  <td className="px-6 py-4 text-red-600 font-medium">{c.rejected_dossiers}</td>
                  <td className="px-6 py-4 text-right font-bold text-text-200">
                    {c.revenue.toLocaleString()}
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan="5" className="px-6 py-8 text-center text-text-400">
                    Aucune commune trouvée.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
