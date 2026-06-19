import React, { useState, useEffect, useCallback } from 'react';
import { attributionApi } from '../../services/attributionApi';
import ScoreBar from './ScoreBar';
import BadgePriorite from './BadgePriorite';
import JustificationIA from './JustificationIA';
import { ArrowPathIcon, ChevronLeftIcon, ChevronRightIcon } from '@heroicons/react/24/outline';

const CarteAttribution = () => {
    const [attributions, setAttributions] = useState([]);
    const [loading, setLoading] = useState(true);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [error, setError] = useState(null);

    // Modal state
    const [modalOpen, setModalOpen] = useState(false);
    const [selectedDossier, setSelectedDossier] = useState(null);
    const [agents, setAgents] = useState([]);
    const [selectedAgentId, setSelectedAgentId] = useState('');
    const [raison, setRaison] = useState('');
    const [submitting, setSubmitting] = useState(false);

    const fetchAttributions = useCallback(async (pageNum) => {
        setLoading(true);
        try {
            const data = await attributionApi.getCarteAttributions(pageNum);
            // DRF StandardPagination renvoie souvent count, next, previous, results
            if (data.results) {
                setAttributions(data.results);
                // Si pageSize=20, on calcule le totalPages
                setTotalPages(Math.ceil(data.count / 20) || 1);
            } else {
                // Au cas où pas paginé
                setAttributions(Array.isArray(data) ? data : []);
            }
            setError(null);
        } catch (err) {
            setError('Erreur lors du chargement des attributions.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchAttributions(page);
    }, [page, fetchAttributions]);

    const openModal = async (attribution) => {
        setSelectedDossier(attribution.dossier_id);
        setModalOpen(true);
        setRaison('');
        setSelectedAgentId('');
        // Charger les agents pour le menu déroulant
        try {
            const agentsData = await attributionApi.getAgentsCharge();
            setAgents(agentsData);
        } catch (e) {
            console.error("Erreur chargement agents", e);
        }
    };

    const handleReattribuer = async (e) => {
        e.preventDefault();
        if (!selectedAgentId || !raison) return;
        
        setSubmitting(true);
        try {
            await attributionApi.reattribuerDossier(selectedDossier, selectedAgentId, raison);
            setModalOpen(false);
            fetchAttributions(page); // Rafraîchir
        } catch (err) {
            alert(err?.response?.data?.error || "Erreur de réattribution");
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 mb-6">
            <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
                <h3 className="text-lg font-semibold text-[#0F172A]" style={{ fontFamily: '"Plus Jakarta Sans", sans-serif' }}>
                    Carte des Attributions en Cours
                </h3>
                <button 
                    onClick={() => fetchAttributions(page)}
                    className="p-2 text-gray-500 hover:bg-gray-100 rounded-full transition-colors"
                    title="Rafraîchir"
                >
                    <ArrowPathIcon className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
                </button>
            </div>
            
            {error && <div className="p-4 text-red-500 bg-red-50">{error}</div>}

            <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-gray-500 font-sans">
                    <thead className="text-xs text-gray-700 uppercase bg-gray-50">
                        <tr>
                            <th className="px-6 py-3 font-semibold">ID Dossier</th>
                            <th className="px-6 py-3 font-semibold">Type</th>
                            <th className="px-6 py-3 font-semibold">Agent Actuel</th>
                            <th className="px-6 py-3 font-semibold w-48">Score IA</th>
                            <th className="px-6 py-3 font-semibold">Priorité</th>
                            <th className="px-6 py-3 font-semibold min-w-[300px]">Justification</th>
                            <th className="px-6 py-3 font-semibold text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {attributions.map((attr) => (
                            <tr key={attr.id} className="border-b hover:bg-gray-50 transition-colors bg-white">
                                <td className="px-6 py-4 font-mono text-[#0F172A]" style={{ fontFamily: '"JetBrains Mono", monospace' }}>
                                    #{String(attr.dossier_id).substring(0, 8)}...
                                </td>
                                <td className="px-6 py-4 uppercase text-xs">{attr.dossier_type?.replace('_', ' ')}</td>
                                <td className="px-6 py-4 font-medium text-[#1D4ED8]">{attr.agent_email}</td>
                                <td className="px-6 py-4"><ScoreBar score={attr.score} /></td>
                                <td className="px-6 py-4"><BadgePriorite niveau={attr.priorite} /></td>
                                <td className="px-6 py-4"><JustificationIA texte={attr.justification_ia} /></td>
                                <td className="px-6 py-4 text-right">
                                    <button 
                                        onClick={() => openModal(attr)}
                                        className="text-sm bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 px-3 py-1.5 rounded-md font-medium transition-colors"
                                    >
                                        Réattribuer
                                    </button>
                                </td>
                            </tr>
                        ))}
                        {!loading && attributions.length === 0 && (
                            <tr><td colSpan="7" className="px-6 py-8 text-center text-gray-400 italic">Aucune attribution en cours</td></tr>
                        )}
                        {loading && attributions.length === 0 && (
                            <tr><td colSpan="7" className="px-6 py-8 text-center text-gray-400">Chargement...</td></tr>
                        )}
                    </tbody>
                </table>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
                <div className="px-6 py-4 border-t border-gray-100 flex items-center justify-between">
                    <span className="text-sm text-gray-500">Page {page} sur {totalPages}</span>
                    <div className="flex gap-2">
                        <button disabled={page === 1} onClick={() => setPage(p => p - 1)} className="p-1 rounded-md border border-gray-300 disabled:opacity-50 hover:bg-gray-50">
                            <ChevronLeftIcon className="w-5 h-5 text-gray-600" />
                        </button>
                        <button disabled={page === totalPages} onClick={() => setPage(p => p + 1)} className="p-1 rounded-md border border-gray-300 disabled:opacity-50 hover:bg-gray-50">
                            <ChevronRightIcon className="w-5 h-5 text-gray-600" />
                        </button>
                    </div>
                </div>
            )}

            {/* Modal de Réattribution */}
            {modalOpen && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
                        <div className="px-6 py-4 border-b border-gray-100">
                            <h3 className="text-lg font-semibold text-[#0F172A]" style={{ fontFamily: '"Plus Jakarta Sans", sans-serif' }}>
                                Réattribuer le dossier
                            </h3>
                            <p className="text-sm text-gray-500 font-mono mt-1" style={{ fontFamily: '"JetBrains Mono", monospace' }}>
                                ID: {selectedDossier}
                            </p>
                        </div>
                        <form onSubmit={handleReattribuer} className="p-6">
                            <div className="mb-4">
                                <label className="block text-sm font-medium text-gray-700 mb-1">Nouvel Agent</label>
                                <select 
                                    required
                                    value={selectedAgentId}
                                    onChange={(e) => setSelectedAgentId(e.target.value)}
                                    className="w-full border-gray-300 rounded-md shadow-sm focus:ring-[#1D4ED8] focus:border-[#1D4ED8] sm:text-sm p-2 border"
                                >
                                    <option value="">Sélectionner un agent...</option>
                                    {agents.map(a => (
                                        <option key={a.id} value={a.id} disabled={!a.disponibilite}>
                                            {a.nom || a.email} ({a.dossiers_en_cours} dossiers) {!a.disponibilite && '- Indisponible'}
                                        </option>
                                    ))}
                                </select>
                            </div>
                            <div className="mb-6">
                                <label className="block text-sm font-medium text-gray-700 mb-1">Raison de la réattribution</label>
                                <textarea 
                                    required
                                    rows={3}
                                    value={raison}
                                    onChange={(e) => setRaison(e.target.value)}
                                    placeholder="Justification obligatoire..."
                                    className="w-full border-gray-300 rounded-md shadow-sm focus:ring-[#1D4ED8] focus:border-[#1D4ED8] sm:text-sm p-2 border"
                                ></textarea>
                            </div>
                            <div className="flex justify-end gap-3">
                                <button type="button" onClick={() => setModalOpen(false)} className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                                    Annuler
                                </button>
                                <button type="submit" disabled={submitting || !selectedAgentId || !raison} className="px-4 py-2 text-sm font-medium text-white bg-[#1D4ED8] rounded-md hover:bg-blue-800 disabled:opacity-50 flex items-center">
                                    {submitting ? 'Confirmation...' : 'Confirmer la réattribution'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default CarteAttribution;
