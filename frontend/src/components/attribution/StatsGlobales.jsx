import React from 'react';
import { useAttributionStats } from '../../hooks/useAttributionStats';
import { FolderIcon, ClockIcon, PlayCircleIcon, CheckCircleIcon, XCircleIcon } from '@heroicons/react/24/outline';

const StatsGlobales = () => {
    const { data, loading, error } = useAttributionStats();

    const cards = [
        {
            title: 'Total Dossiers',
            value: data?.total || 0,
            icon: FolderIcon,
            colorClass: 'text-[#0F172A]',
            bgIconClass: 'bg-gray-100'
        },
        {
            title: 'En Attente',
            value: data?.en_attente || 0,
            icon: ClockIcon,
            colorClass: 'text-[#F59E0B]',
            bgIconClass: 'bg-orange-100'
        },
        {
            title: 'En Traitement',
            value: data?.en_traitement || 0,
            icon: PlayCircleIcon,
            colorClass: 'text-[#1D4ED8]',
            bgIconClass: 'bg-blue-100'
        },
        {
            title: 'Terminés',
            value: data?.termines || 0,
            icon: CheckCircleIcon,
            colorClass: 'text-[#10B981]',
            bgIconClass: 'bg-green-100'
        },
        {
            title: 'Rejetés',
            value: data?.rejetes || 0,
            icon: XCircleIcon,
            colorClass: 'text-[#EF4444]',
            bgIconClass: 'bg-red-100'
        }
    ];

    if (error) {
        return <div className="p-4 bg-red-50 text-red-600 rounded-lg shadow">{error}</div>;
    }

    return (
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4 mb-6">
            {cards.map((card, idx) => (
                <div key={idx} className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 flex items-center justify-between transition-transform hover:-translate-y-1 duration-200">
                    <div>
                        <p className="text-sm font-medium text-gray-500 font-sans mb-1">{card.title}</p>
                        {loading ? (
                            <div className="h-8 w-16 bg-gray-200 animate-pulse rounded"></div>
                        ) : (
                            <h3 className="text-3xl font-bold font-['Plus_Jakarta_Sans'] text-[#0F172A]" style={{ fontFamily: '"Plus Jakarta Sans", sans-serif' }}>
                                {card.value}
                            </h3>
                        )}
                    </div>
                    <div className={`p-3 rounded-full ${card.bgIconClass}`}>
                        <card.icon className={`w-6 h-6 ${card.colorClass}`} />
                    </div>
                </div>
            ))}
        </div>
    );
};

export default StatsGlobales;
