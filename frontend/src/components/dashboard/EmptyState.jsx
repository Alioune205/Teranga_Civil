// src/components/dashboard/EmptyState.jsx
import { Database, BarChart2, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';

export function EmptyState({ variant = 'no-data', title, description, actionLabel, onAction }) {
  let Icon = Database;
  let iconColor = 'text-text-500';
  
  if (variant === 'insufficient') {
    Icon = BarChart2;
    iconColor = 'text-amber-500';
    description = description || "Pas assez de données pour le moment.";
  } else if (variant === 'error') {
    Icon = AlertCircle;
    iconColor = 'text-red-500';
  }

  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center select-none animate-enter h-full">
      <div className="relative mb-5">
        <div className="absolute inset-0 bg-layer-3 rounded-full blur-xl scale-125"></div>
        <div className={`relative bg-layer-1 p-4 rounded-2xl shadow-sm border border-border-subtle ${iconColor}`}>
          <Icon className="h-10 w-10" strokeWidth={1.5} />
        </div>
      </div>
      <h3 className="text-[15px] font-semibold text-text-200">{title}</h3>
      <p className="text-[13px] text-text-400 mt-1.5 max-w-sm leading-relaxed">{description}</p>
      {actionLabel && onAction && (
        <Button onClick={onAction} className="mt-5 h-9 bg-blue-700 hover:bg-blue-800 text-white" size="sm">
          {actionLabel}
        </Button>
      )}
    </div>
  );
}
