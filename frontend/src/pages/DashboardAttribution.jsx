import React, { useState, useEffect } from 'react';
import { attributionApi } from '../services/attributionApi';
import { useAttributionStats } from '../hooks/useAttributionStats';
import { useWebSocket } from '../hooks/useWebSocket';

import StatsGlobales from '../components/attribution/StatsGlobales';
import TableauAgents from '../components/attribution/TableauAgents';
import GraphiquesPerformance from '../components/attribution/GraphiquesPerformance';
import CarteAttribution from '../components/attribution/CarteAttribution';
import CentreSupervision from '../components/attribution/CentreSupervision';
import JournalAudit from '../components/attribution/JournalAudit';

import { SignalIcon, SignalSlashIcon } from '@heroicons/react/24/solid';

const DashboardAttribution = () => {
    const { lastUpdated, refetch } = useAttributionStats();
    const { isConnected, lastMessage } = useWebSocket();
    
    const [agents, setAgents] = useState([]);
    const [timeSinceUpdate, setTimeSinceUpdate] = useState(0);

    // Mettre à jour l'indicateur "Mis à jour il y a X sec"
    useEffect(() => {
        const interval = setInterval(() => {
            setTimeSinceUpdate(Math.floor((Date.now() - lastUpdated) / 1000));
        }, 1000);
        return () => clearInterval(interval);
    }, [lastUpdated]);

    // Écoute des WebSockets pour rafraîchir en temps réel
    useEffect(() => {
        if (lastMessage) {
            // Si un nouvel événement d'attribution arrive, on rafraîchit les stats et les agents
            refetch();
            fetchAgents();
            // Note: CarteAttribution gère son propre state, mais si on voulait, 
            // on pourrait passer un prop "refreshTrigger" pour forcer la mise à jour des sous-composants
        }
    }, [lastMessage, refetch]);

    const fetchAgents = async () => {
        try {
            const data = await attributionApi.getAgentsCharge();
            setAgents(data);
        } catch (e) {
            console.error("Erreur chargement agents", e);
        }
    };

    // Chargement initial
    useEffect(() => {
        fetchAgents();
    }, []);

    return (
        <div className="min-h-screen bg-[#F8FAFC] p-6 font-sans">
            <div className="max-w-7xl mx-auto space-y-6">
                
                {/* En-tête */}
                <header className="flex flex-col md:flex-row md:items-center justify-between bg-white p-5 rounded-xl shadow-sm border border-gray-100">
                    <div>
                        <h1 className="text-2xl font-bold text-[#0F172A]" style={{ fontFamily: '"Plus Jakarta Sans", sans-serif' }}>
                            Répartition Intelligente
                        </h1>
                        <p className="text-sm text-[#6B7280] mt-1">
                            Teranga Civil — Module Attribution
                        </p>
                    </div>
                    <div className="mt-4 md:mt-0 flex items-center space-x-4">
                        <div className="flex flex-col items-end">
                            <span className="text-xs text-gray-500 flex items-center">
                                {isConnected ? (
                                    <><SignalIcon className="w-3 h-3 text-[#10B981] mr-1" /> En direct (WS)</>
                                ) : (
                                    <><SignalSlashIcon className="w-3 h-3 text-[#EF4444] mr-1" /> Hors ligne</>
                                )}
                            </span>
                            <span className="text-xs font-mono text-gray-400 mt-1" style={{ fontFamily: '"JetBrains Mono", monospace' }}>
                                Mis à jour il y a {timeSinceUpdate}s
                            </span>
                        </div>
                    </div>
                </header>

                {/* Section 1 : Stats Globales */}
                <section>
                    <StatsGlobales />
                </section>

                {/* Section 2 : Tableau & Graphiques (2 colonnes) */}
                <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <div className="lg:col-span-1">
                        <TableauAgents agents={agents} />
                    </div>
                    <div className="lg:col-span-1">
                        <GraphiquesPerformance agents={agents} />
                    </div>
                </section>

                {/* Section 3 : Carte Attribution */}
                <section>
                    <CarteAttribution />
                </section>

                {/* Section 4 : Supervision & Audit (2 colonnes) */}
                <section className="grid grid-cols-1 xl:grid-cols-3 gap-6">
                    <div className="xl:col-span-1 h-[450px]">
                        <CentreSupervision agents={agents} />
                    </div>
                    <div className="xl:col-span-2 h-[450px]">
                        <JournalAudit agents={agents} />
                    </div>
                </section>

            </div>
        </div>
    );
};

export default DashboardAttribution;
