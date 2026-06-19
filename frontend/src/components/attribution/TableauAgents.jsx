import React, { useState } from 'react';
import ScoreBar from './ScoreBar';
import { ChevronUpIcon, ChevronDownIcon } from '@heroicons/react/24/solid';

const TableauAgents = ({ agents = [] }) => {
    const [sortAsc, setSortAsc] = useState(false);

    const sortedAgents = [...agents].sort((a, b) => {
        if (sortAsc) return a.score_global - b.score_global;
        return b.score_global - a.score_global;
    });

    const toggleSort = () => setSortAsc(!sortAsc);

    return (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
                <h3 className="text-lg font-semibold text-[#0F172A]" style={{ fontFamily: '"Plus Jakarta Sans", sans-serif' }}>
                    Charge des Agents
                </h3>
            </div>
            <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-gray-500 font-sans">
                    <thead className="text-xs text-gray-700 uppercase bg-gray-50">
                        <tr>
                            <th className="px-6 py-3 font-semibold">Nom de l'Agent</th>
                            <th className="px-6 py-3 font-semibold text-center">En cours</th>
                            <th className="px-6 py-3 font-semibold text-center">Charge Max</th>
                            <th 
                                className="px-6 py-3 font-semibold cursor-pointer hover:bg-gray-100 transition-colors flex items-center justify-between"
                                onClick={toggleSort}
                            >
                                Score Global
                                {sortAsc ? <ChevronUpIcon className="w-4 h-4 inline-block ml-1" /> : <ChevronDownIcon className="w-4 h-4 inline-block ml-1" />}
                            </th>
                            <th className="px-6 py-3 font-semibold text-center">Statut</th>
                        </tr>
                    </thead>
                    <tbody>
                        {sortedAgents.map((agent) => (
                            <tr 
                                key={agent.id} 
                                className={`border-b hover:bg-gray-50 transition-colors ${!agent.disponibilite ? 'bg-[#FEF2F2]' : 'bg-white'}`}
                            >
                                <td className="px-6 py-4 font-medium text-[#0F172A]">{agent.nom || agent.email}</td>
                                <td className="px-6 py-4 text-center font-mono" style={{ fontFamily: '"JetBrains Mono", monospace' }}>
                                    <span className="bg-blue-100 text-[#1D4ED8] py-1 px-2 rounded font-bold">
                                        {agent.dossiers_en_cours}
                                    </span>
                                </td>
                                <td className="px-6 py-4 text-center font-mono" style={{ fontFamily: '"JetBrains Mono", monospace' }}>
                                    {agent.charge_maximale}
                                </td>
                                <td className="px-6 py-4 min-w-[200px]">
                                    <ScoreBar score={agent.score_global} />
                                </td>
                                <td className="px-6 py-4 text-center">
                                    {agent.disponibilite ? (
                                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-[#10B981]">
                                            Disponible
                                        </span>
                                    ) : (
                                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-[#EF4444]">
                                            Indisponible
                                        </span>
                                    )}
                                </td>
                            </tr>
                        ))}
                        {agents.length === 0 && (
                            <tr>
                                <td colSpan="5" className="px-6 py-8 text-center text-gray-400 italic">
                                    Aucun agent trouvé
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default TableauAgents;
