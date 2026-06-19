import React from 'react';

const JustificationIA = ({ texte }) => {
    if (!texte) return null;

    return (
        <div className="relative bg-[#EFF6FF] border-l-[3px] border-[#1D4ED8] p-3 rounded-r-md shadow-sm mt-2">
            <span className="absolute top-2 right-2 bg-[#1D4ED8] text-white text-[10px] font-bold px-1.5 py-0.5 rounded uppercase tracking-wider">
                IA
            </span>
            <p className="text-[#0F172A] italic text-sm font-sans pr-8 leading-relaxed">
                "{texte}"
            </p>
        </div>
    );
};

export default JustificationIA;
