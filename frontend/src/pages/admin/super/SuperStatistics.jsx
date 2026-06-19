import React, { useState, useEffect } from 'react';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, LineChart, Line } from 'recharts';
import api from '@/api/axiosClient';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

export default function SuperStatistics() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchCharts = async () => {
      try {
        const res = await api.get('/api/dashboard/superadmin/charts/');
        setData(res.data);
      } catch (error) {
        console.error(error);
      } finally {
        setLoading(false);
      }
    };
    fetchCharts();
  }, []);

  if (loading) return <div className="p-8 text-center text-text-400">Chargement des graphiques...</div>;
  if (!data) return <div className="p-8 text-center text-red-500">Erreur de chargement des graphiques.</div>;

  // Format data for Recharts
  const pieData = data.documents_breakdown.map((item, idx) => ({
    name: item.type === 'birth_certificate' ? 'Extrait Naissance' :
          item.type === 'residence_certificate' ? 'Certificat Résidence' :
          item.type === 'marriage_certificate' ? 'Certificat Mariage' :
          item.type === 'death_certificate' ? 'Certificat Décès' : item.type,
    value: item.count
  }));

  const formatMonth = (dateString) => {
    const d = new Date(dateString);
    return d.toLocaleDateString('fr-FR', { month: 'short', year: 'numeric' });
  };

  const trendData = data.dossiers_trend.map(item => ({
    name: formatMonth(item.month || item.date),
    Demandes: item.count || item.total
  }));

  const revenueData = data.revenue_trend.map(item => ({
    name: formatMonth(item.month),
    Revenus: item.revenue
  }));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text-200">Statistiques & Graphiques</h1>
          <p className="text-sm text-text-400">Analytique avancée de l'état civil</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Répartition des documents */}
        <div className="bg-white p-6 rounded-2xl border border-border-subtle shadow-sm">
          <h3 className="text-lg font-bold text-text-200 mb-4">Répartition par Type de Document</h3>
          <div className="h-72 w-full">
            <ResponsiveContainer>
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  fill="#8884d8"
                  paddingAngle={5}
                  dataKey="value"
                  label={({name, percent}) => `${name} ${(percent * 100).toFixed(0)}%`}
                >
                  {pieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Évolution des Demandes */}
        <div className="bg-white p-6 rounded-2xl border border-border-subtle shadow-sm">
          <h3 className="text-lg font-bold text-text-200 mb-4">Évolution des Demandes</h3>
          <div className="h-72 w-full">
            <ResponsiveContainer>
              <BarChart data={trendData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="name" axisLine={false} tickLine={false} />
                <YAxis axisLine={false} tickLine={false} />
                <Tooltip cursor={{fill: '#f8fafc'}} />
                <Bar dataKey="Demandes" fill="#6366f1" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Évolution des Revenus */}
        <div className="bg-white p-6 rounded-2xl border border-border-subtle shadow-sm lg:col-span-2">
          <h3 className="text-lg font-bold text-text-200 mb-4">Évolution des Revenus (FCFA)</h3>
          <div className="h-80 w-full">
            <ResponsiveContainer>
              <LineChart data={revenueData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="name" axisLine={false} tickLine={false} />
                <YAxis axisLine={false} tickLine={false} width={80} />
                <Tooltip />
                <Line type="monotone" dataKey="Revenus" stroke="#10b981" strokeWidth={3} dot={{r: 4, fill: '#10b981'}} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}
