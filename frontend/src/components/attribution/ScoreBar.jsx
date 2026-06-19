import React from 'react';

const ScoreBar = ({ score, showLabel = true }) => {
    let color = 'bg-[#EF4444]'; // Rouge < 60
    if (score > 80) {
        color = 'bg-[#10B981]'; // Vert > 80
    } else if (score >= 60) {
        color = 'bg-[#F59E0B]'; // Orange 60-80
    }

    // Assurer que le score est entre 0 et 100
    const boundedScore = Math.min(Math.max(score, 0), 100);

    return (
        <div className="flex items-center w-full gap-3">
            <div className="flex-grow bg-gray-200 rounded-full h-2.5 dark:bg-gray-700 overflow-hidden">
                <div 
                    className={`h-2.5 rounded-full ${color} transition-all duration-500 ease-in-out`} 
                    style={{ width: `${boundedScore}%` }}
                ></div>
            </div>
            {showLabel && (
                <span className="text-sm font-medium text-[#0F172A]" style={{ fontFamily: '"JetBrains Mono", monospace' }}>
                    {Number(score).toFixed(1)}
                </span>
            )}
        </div>
    );
};

export default ScoreBar;
