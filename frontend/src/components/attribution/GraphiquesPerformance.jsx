import React, { useState, useEffect } from 'react';
import { 
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
    Radar, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis,
    LineChart, Line 
} from 'recharts';
import { attributionApi } from '../../services/attributionApi';

const GraphiquesPerformance = ({ agents = [] }) => {
    const [activeTab, setActiveTab] = useState('charge');
    const [selectedAgentId, setSelectedAgentId] = useState('');
    const [perfData, setPerfData] = useState(null);

    // Données fictives pour l'onglet Délais (mock sur 7 jours)
    const delaisData = React.useMemo(() => Array.from({length: 7}).map((_, i) => {
        const d = new Date();
        d.setDate(d.getDate() - (6 - i));
        return {
            date: d.toLocaleDateString('fr-FR', { weekday: 'short', day: 'numeric' }),
            temps: Math.floor(Math.random() * 40) + 10 // Entre 10 et 50 minutes
        };
    }), []);

    useEffect(() => {
        if (activeTab === 'performance' && selectedAgentId) {
            attributionApi.getAgentPerformance(selectedAgentId)
                .then(data => {
                    setPerfData([
                        { subject: 'Disponibilité', A: data.score_global || 80, fullMark: 100 },
                        { subject: 'Compétence', A: 90, fullMark: 100 },
                        { subject: 'Rapidité', A: Math.max(0, 100 - data.temps_moyen), fullMark: 100 },
                        { subject: 'Taux réussite', A: data.taux_reussite, fullMark: 100 },
                        { subject: 'Délais', A: data.taux_respect_delais, fullMark: 100 },
                    ]);
                })
                .catch(e => console.error(e));
        }
    }, [activeTab, selectedAgentId]);

    // Initialiser le premier agent
    useEffect(() => {
        if (agents.length > 0 && !selectedAgentId) {
            setSelectedAgentId(agents[0].id);
        }
    }, [agents, selectedAgentId]);

    const chargeData = React.useMemo(() => agents.map(a => ({
        name: (a.nom || a.email).split('@')[0], // Raccourcir le nom
        Attribués: a.dossiers_en_cours,
        Terminés: Math.floor(Math.random() * 20), // Fictif car absent de l'API /charge/
        'En retard': Math.floor(Math.random() * 3) // Fictif
    })), [agents]);

    return (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 flex flex-col h-full">
            <div className="px-6 py-4 border-b border-gray-100">
                <h3 className="text-lg font-semibold text-[#0F172A] mb-4" style={{ fontFamily: '"Plus Jakarta Sans", sans-serif' }}>
                    Analyse des Performances
                </h3>
                <div className="flex space-x-1 bg-gray-100 p-1 rounded-lg">
                    {['charge', 'performance', 'delais'].map(tab => (
                        <button
                            key={tab}
                            onClick={() => setActiveTab(tab)}
                            className={`flex-1 py-1.5 text-sm font-medium rounded-md capitalize transition-colors ${activeTab === tab ? 'bg-white text-[#1D4ED8] shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}
                        >
                            {tab}
                        </button>
                    ))}
                </div>
            </div>

            <div className="p-6 flex-grow flex flex-col justify-center min-h-[300px]">
                {activeTab === 'charge' && (
                    <ResponsiveContainer width="100%" height={300}>
                        <BarChart data={chargeData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                            <CartesianGrid strokeDasharray="3 3" vertical={false} />
                            <XAxis dataKey="name" tick={{fontSize: 12}} />
                            <YAxis tick={{fontSize: 12}} />
                            <Tooltip cursor={{fill: '#F8FAFC'}} />
                            <Legend wrapperStyle={{fontSize: '12px'}} />
                            <Bar dataKey="Attribués" fill="#1D4ED8" radius={[4, 4, 0, 0]} />
                            <Bar dataKey="Terminés" fill="#10B981" radius={[4, 4, 0, 0]} />
                            <Bar dataKey="En retard" fill="#EF4444" radius={[4, 4, 0, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                )}

                {activeTab === 'performance' && (
                    <div className="flex flex-col h-full">
                        <select 
                            value={selectedAgentId} 
                            onChange={(e) => setSelectedAgentId(e.target.value)}
                            className="mb-4 text-sm border-gray-300 rounded-md border p-2 w-full max-w-xs mx-auto focus:border-[#1D4ED8] focus:ring-[#1D4ED8]"
                        >
                            {agents.map(a => <option key={a.id} value={a.id}>{a.nom || a.email}</option>)}
                        </select>
                        <div className="flex-grow">
                            {perfData ? (
                                <ResponsiveContainer width="100%" height={260}>
                                    <RadarChart cx="50%" cy="50%" outerRadius="80%" data={perfData}>
                                        <PolarGrid stroke="#E2E8F0" />
                                        <PolarAngleAxis dataKey="subject" tick={{fill: '#64748b', fontSize: 11}} />
                                        <PolarRadiusAxis angle={30} domain={[0, 100]} tick={false} />
                                        <Radar name="Agent" dataKey="A" stroke="#1D4ED8" fill="#1D4ED8" fillOpacity={0.3} />
                                        <Tooltip />
                                    </RadarChart>
                                </ResponsiveContainer>
                            ) : (
                                <div className="h-full flex items-center justify-center text-gray-400">Chargement...</div>
                            )}
                        </div>
                    </div>
                )}

                {activeTab === 'delais' && (
                    <ResponsiveContainer width="100%" height={300}>
                        <LineChart data={delaisData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                            <CartesianGrid strokeDasharray="3 3" vertical={false} />
                            <XAxis dataKey="date" tick={{fontSize: 12}} />
                            <YAxis tick={{fontSize: 12}} />
                            <Tooltip />
                            <Legend wrapperStyle={{fontSize: '12px'}} />
                            <Line type="monotone" name="Temps moyen (min)" dataKey="temps" stroke="#1D4ED8" strokeWidth={3} dot={{r: 4, fill: '#F59E0B', strokeWidth: 0}} activeDot={{r: 6}} />
                        </LineChart>
                    </ResponsiveContainer>
                )}
            </div>
        </div>
    );
};

export default GraphiquesPerformance;
