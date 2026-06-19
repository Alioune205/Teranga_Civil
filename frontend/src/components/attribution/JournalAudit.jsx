import React, { useState, useEffect, useCallback } from 'react';
import { attributionApi } from '../../services/attributionApi';
import { ChevronLeftIcon, ChevronRightIcon, ArrowRightIcon } from '@heroicons/react/24/outline';

const JournalAudit = ({ agents = [] }) => {
    const [journal, setJournal] = useState([]);
    const [loading, setLoading] = useState(true);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);

    // Filtres front-end (idéalement envoyés à l'API si elle les supporte, 
    // mais ici on filtre côté client sur la page courante faute d'endpoint filtré spécifique dans l'énoncé)
    const [filterDate, setFilterDate] = useState('');
    const [filterAgent, setFilterAgent] = useState('');

    const fetchJournal = useCallback(async (pageNum) => {
        setLoading(true);
        try {
            const data = await attributionApi.getJournal(pageNum);
            if (data.results) {
                setJournal(data.results);
                setTotalPages(Math.ceil(data.count / 20) || 1);
            } else {
                setJournal(Array.isArray(data) ? data : []);
            }
        } catch (e) {
            console.error("Erreur journal", e);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchJournal(page);
    }, [page, fetchJournal]);

    // Format date string for filtering
    const filteredJournal = journal.filter(log => {
        let matchDate = true;
        let matchAgent = true;

        if (filterDate) {
            const logDate = new Date(log.timestamp).toISOString().split('T')[0];
            matchDate = logDate === filterDate;
        }
        if (filterAgent) {
            matchAgent = log.agent_avant === filterAgent || log.agent_apres === filterAgent;
        }

        return matchDate && matchAgent;
    });

    const formatDate = (isoString) => {
        const d = new Date(isoString);
        return d.toLocaleString('fr-FR', { 
            day: '2-digit', month: '2-digit', year: 'numeric',
            hour: '2-digit', minute: '2-digit', second: '2-digit'
        });
    };

    return (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 flex flex-col h-full">
            <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                <h3 className="text-lg font-semibold text-[#0F172A]" style={{ fontFamily: '"Plus Jakarta Sans", sans-serif' }}>
                    Journal d'Audit Intégral
                </h3>
                <div className="flex space-x-2">
                    <input 
                        type="date" 
                        value={filterDate} onChange={(e) => setFilterDate(e.target.value)}
                        className="text-xs border-gray-300 rounded focus:ring-[#1D4ED8] focus:border-[#1D4ED8] p-1 border"
                    />
                    <select 
                        value={filterAgent} onChange={(e) => setFilterAgent(e.target.value)}
                        className="text-xs border-gray-300 rounded focus:ring-[#1D4ED8] focus:border-[#1D4ED8] p-1 border"
                    >
                        <option value="">Tous les agents</option>
                        {agents.map(a => <option key={a.id} value={a.email}>{a.email}</option>)}
                    </select>
                </div>
            </div>

            <div className="overflow-x-auto flex-grow">
                <table className="w-full text-left text-xs text-gray-500 font-sans">
                    <thead className="text-gray-700 uppercase bg-white border-b border-gray-100">
                        <tr>
                            <th className="px-4 py-3 font-semibold">Horodatage</th>
                            <th className="px-4 py-3 font-semibold">Action</th>
                            <th className="px-4 py-3 font-semibold">Dossier</th>
                            <th className="px-4 py-3 font-semibold">Transfert (Avant → Après)</th>
                            <th className="px-4 py-3 font-semibold">Score IA</th>
                            <th className="px-4 py-3 font-semibold">Responsable</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                        {filteredJournal.map((log) => (
                            <tr key={log.id} className="hover:bg-gray-50">
                                <td className="px-4 py-3 font-mono text-[#6B7280]" style={{ fontFamily: '"JetBrains Mono", monospace' }}>
                                    {formatDate(log.timestamp)}
                                </td>
                                <td className="px-4 py-3 font-medium text-[#0F172A]">{log.action}</td>
                                <td className="px-4 py-3 font-mono" style={{ fontFamily: '"JetBrains Mono", monospace' }}>
                                    #{String(log.dossier_id).substring(0,8)}
                                </td>
                                <td className="px-4 py-3 flex items-center">
                                    <span className="truncate w-24" title={log.agent_avant || 'Système'}>
                                        {log.agent_avant ? log.agent_avant.split('@')[0] : <span className="text-gray-400 italic">Système</span>}
                                    </span>
                                    <ArrowRightIcon className="w-3 h-3 mx-2 text-[#F59E0B]" />
                                    <span className="truncate w-24 font-medium text-[#1D4ED8]" title={log.agent_apres}>
                                        {log.agent_apres ? log.agent_apres.split('@')[0] : 'N/A'}
                                    </span>
                                </td>
                                <td className="px-4 py-3 font-mono" style={{ fontFamily: '"JetBrains Mono", monospace' }}>
                                    {log.score > 0 ? log.score.toFixed(1) : '-'}
                                </td>
                                <td className="px-4 py-3">{log.responsable}</td>
                            </tr>
                        ))}
                        {loading && <tr><td colSpan="6" className="text-center py-4">Chargement...</td></tr>}
                        {!loading && filteredJournal.length === 0 && <tr><td colSpan="6" className="text-center py-4 italic">Aucune entrée correspondante</td></tr>}
                    </tbody>
                </table>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
                <div className="px-6 py-3 border-t border-gray-100 flex items-center justify-between bg-gray-50/50">
                    <span className="text-xs text-gray-500">Page {page} sur {totalPages}</span>
                    <div className="flex gap-1">
                        <button disabled={page === 1} onClick={() => setPage(p => p - 1)} className="p-1 rounded bg-white border border-gray-200 disabled:opacity-50 hover:bg-gray-100">
                            <ChevronLeftIcon className="w-4 h-4 text-gray-600" />
                        </button>
                        <button disabled={page === totalPages} onClick={() => setPage(p => p + 1)} className="p-1 rounded bg-white border border-gray-200 disabled:opacity-50 hover:bg-gray-100">
                            <ChevronRightIcon className="w-4 h-4 text-gray-600" />
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default JournalAudit;
