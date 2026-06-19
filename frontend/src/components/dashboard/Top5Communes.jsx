// src/components/dashboard/Top5Communes.jsx
import { useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { EmptyState } from './EmptyState';

export function Top5Communes({ loading, stats }) {
  const topCommunes = useMemo(() => {
    if (!stats?.dossiers_par_commune) return [];
    const sorted = [...stats.dossiers_par_commune].filter((c) => c.count > 0).sort((a, b) => b.count - a.count);
    return sorted.slice(0, 5);
  }, [stats]);

  const maxVal = useMemo(() => {
    if (topCommunes.length === 0) return 0;
    return Math.max(...topCommunes.map(c => c.count));
  }, [topCommunes]);

  return (
    <Card className="lg:col-span-2 lg:row-span-1 border-border-subtle bg-layer-1 shadow-sm p-6 overflow-hidden h-full flex flex-col min-h-[320px]">
      <CardHeader className="p-0 pb-4 flex-shrink-0">
        <CardTitle className="text-base font-semibold text-text-100">
          Top 5 Communes
        </CardTitle>
      </CardHeader>
      <CardContent className="p-0 flex-1 min-h-0 overflow-y-auto">
        {loading ? (
          <Skeleton className="h-full w-full rounded-xl" />
        ) : topCommunes.length === 0 ? (
          <EmptyState
            variant="insufficient"
            title="Aucune donnée communale"
            description="L'activité est insuffisante pour établir un classement."
          />
        ) : (
          <div className="space-y-4 pr-2 mt-2">
            {topCommunes.map((item, index) => {
              const widthPct = maxVal > 0 ? (item.count / maxVal) * 100 : 0;
              return (
                <div key={item.commune} className="flex flex-col gap-1.5 animate-enter" style={{ animationDelay: `${index * 50}ms` }}>
                  <div className="flex justify-between items-end text-sm">
                    <span className="font-medium text-text-300">{item.commune}</span>
                    <span className="font-semibold text-text-100">{item.count}</span>
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
