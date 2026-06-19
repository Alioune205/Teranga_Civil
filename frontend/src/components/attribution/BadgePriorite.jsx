import React from 'react';

const BadgePriorite = ({ niveau }) => {
    let bgColor = 'bg-gray-500'; // faible
    let label = 'Faible';

    switch (niveau) {
        case 'urgent':
            bgColor = 'bg-[#EF4444]';
            label = 'Urgent';
            break;
        case 'eleve':
            bgColor = 'bg-[#F59E0B]';
            label = 'Élevé';
            break;
        case 'normal':
            bgColor = 'bg-[#1D4ED8]';
            label = 'Normal';
            break;
        case 'faible':
            bgColor = 'bg-[#6B7280]';
            label = 'Faible';
            break;
        default:
            break;
    }

    return (
        <span className={`${bgColor} text-white text-xs font-semibold px-2 py-1 rounded-full uppercase tracking-wide font-sans`}>
            {label}
        </span>
    );
};

export default BadgePriorite;
