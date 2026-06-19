// src/components/KPICard.jsx
import { useState, useEffect } from 'react';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

function useCountUp(end, duration = 300) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    let startTime = null;
    let animationFrame;

    const step = (timestamp) => {
      if (!startTime) startTime = timestamp;
      const progress = timestamp - startTime;
      const percentage = Math.min(progress / duration, 1);
      
      const easeOut = 1 - Math.pow(1 - percentage, 3);
      setCount(Math.floor(end * easeOut));

      if (progress < duration) {
        animationFrame = window.requestAnimationFrame(step);
      } else {
        setCount(end);
      }
    };

    animationFrame = window.requestAnimationFrame(step);

    return () => window.cancelAnimationFrame(animationFrame);
  }, [end, duration]);

  return count;
}

export function KPICard({ 
  title, 
  value, 
  icon: Icon, 
  loading = false, 
  trend,
  criticalStatus, // 'warning' | 'error' | 'success' | 'info'
  iconColorClass, // e.g., 'text-blue-700 bg-blue-50 dark:bg-blue-900/20'
  onClick // Navigation handler
}) {
  const numericValue = typeof value === 'number' ? value : parseFloat(value) || 0;
  const isPercentage = typeof value === 'string' && value.includes('%');
  const animatedValue = useCountUp(numericValue, 300);
  const displayValue = isPercentage ? `${animatedValue}%` : animatedValue;

  if (loading) {
    return (
      <div className="kpi-card skeleton border-border-strong flex flex-col justify-between">
        <div className="flex justify-between items-start mb-2">
          <div className="flex items-center gap-2">
            <div className="h-6 w-6 rounded bg-layer-3 animate-pulse" />
            <div className="h-3 w-24 rounded bg-layer-3 animate-pulse" />
          </div>
        </div>
        <div className="h-[48px] w-20 rounded bg-layer-3 animate-pulse mt-2" />
      </div>
    );
  }

  const statusClass = (numericValue >= 0 && criticalStatus) ? (criticalStatus === 'warning' ? 'critical' : criticalStatus) : (numericValue === 0 ? 'border border-gray-200 dark:border-gray-700' : '');
  
  const statusColor = criticalStatus || 'info';

  return (
    <div 
      className={`kpi-card flex flex-col justify-between min-h-[100px] ${onClick ? 'cursor-pointer hover:border-blue-300 dark:hover:border-blue-700' : ''} ${statusClass}`}
      onClick={onClick}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          {Icon && (
            <div className={`card-icon ${iconColorClass ? iconColorClass : ''}`} style={!iconColorClass ? { background: `var(--${statusColor}-dim)`, color: `var(--${statusColor})` } : {}}>
              <Icon className="h-5 w-5 flex-shrink-0" />
            </div>
          )}
          <span className="kpi-card-label">{title}</span>
        </div>
      </div>

      {/* Value & Trend */}
      <div className="flex items-end justify-between mt-2">
        <p className="kpi-card-value">
          {displayValue}
        </p>
        
        {trend && value > 0 && (
          <div className={`flex items-center gap-1 text-[11px] font-medium px-2 py-1 rounded-full ${
            trend.value > 0 ? 'bg-success-dim text-success' : 
            trend.value < 0 ? 'bg-error-dim text-error' : 
            'bg-layer-2 text-text-400'
          }`}>
            {trend.value > 0 ? <TrendingUp className="h-3 w-3" /> : 
             trend.value < 0 ? <TrendingDown className="h-3 w-3" /> : 
             <Minus className="h-3 w-3" />}
            <span>{trend.value > 0 ? '+' : ''}{trend.value}% {trend.label}</span>
          </div>
        )}
      </div>
    </div>
  );
}
