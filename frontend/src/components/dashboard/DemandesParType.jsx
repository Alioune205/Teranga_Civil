// src/components/dashboard/DemandesParType.jsx
import { useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { EmptyState } from './EmptyState';

const TYPE_LABELS = {
  birth_certificate: 'Acte de naissance',
  marriage_certificate: 'Acte de mariage',
  death_certificate: 'Acte de décès',
  residence_certificate: 'Certificat de résidence',
  other: 'Autre',
};

export function DemandesParType({ loading, stats }) {
  const dataByType = useMemo(() => {
    if (!stats?.dossiers_par_type) return [];
    return Object.entries(stats.dossiers_par_type)
      .filter(([_, count]) => count > 0)
      .map(([type, count]) => ({
        type,
        type_display: TYPE_LABELS[type] || type,
        count
      }))
      .sort((a, b) => b.count - a.count);
  }, [stats]);

  const totalDossiers = useMemo(() => {
    return dataByType.reduce((sum, item) => sum + item.count, 0);
  }, [dataByType]);

  const maxVal = useMemo(() => {
    if (dataByType.length === 0) return 0;
    return Math.max(...dataByType.map(d => d.count));
  }, [dataByType]);

  return (
    <Card className="lg:col-span-3 lg:row-span-1 border-border-subtle bg-layer-1 shadow-sm p-6 overflow-hidden h-full flex flex-col min-h-[320px]">
      <CardHeader className="p-0 pb-4 flex-shrink-0">
        <CardTitle className="text-base font-semibold text-text-100">
          Demandes par type
        </CardTitle>
      </CardHeader>
      <CardContent className="p-0 flex-1 min-h-0 overflow-y-auto">
        {loading ? (
          <Skeleton className="h-full w-full rounded-xl" />
        ) : dataByType.length === 0 ? (
          <EmptyState
            variant="no-data"
            title="Aucune donnée"
            description="Les données n'ont pas encore été générées."
          />
        ) : (
          <div className="space-y-4 pr-2 mt-2">
            {dataByType.map((item, index) => {
              const widthPct = maxVal > 0 ? (item.count / maxVal) * 100 : 0;
              const globalPct = totalDossiers > 0 ? (item.count / totalDossiers) * 100 : 0;
              return (
                <div key={item.type} className="flex flex-col gap-1.5 animate-enter" style={{ animationDelay: `${index * 50}ms` }}>
                  <div className="flex justify-between items-end text-sm">
                    <span className="font-medium text-text-300">{item.type_display}</span>
                    <span className="font-semibold text-text-100">
                      {item.count} <span className="text-[11px] font-normal text-text-400">({globalPct.toFixed(1)}%)</span>
                    </span>
                  </div>
                  <div className="h-2 w-full bg-layer-3 rounded-full overflow-hidden">
                    <div 
                      className="h-full rounded-full bg-blue-600 dark:bg-blue-500 transition-all duration-1000 ease-out" 
                      style={{ width: `${widthPct}%`, opacity: 1 - (index * 0.15) }} 
                    />
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
