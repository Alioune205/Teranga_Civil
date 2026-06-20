// src/components/StatusBadge.jsx
import { Badge } from '@/components/ui/badge';
import { Clock, Eye, CheckCircle, XCircle, Package, FileText, Send } from 'lucide-react';

const STATUS_CONFIG = {
  draft: {
    label: 'Brouillon',
    className: 'bg-[#94A3B8] text-white border-[#94A3B8]',
    Icon: FileText,
  },
  submitted: {
    label: 'Soumis',
    className: 'bg-[#F59E0B] text-white border-[#F59E0B]',
    Icon: Send,
  },
  in_review: {
    label: 'En vérification',
    className: 'bg-[#1D4ED8] text-white border-[#1D4ED8]',
    Icon: Eye,
  },
  en_approbation: {
    label: 'En attente',
    className: 'bg-[#F97316] text-white border-[#F97316]',
    Icon: Clock,
  },
  approved: {
    label: 'Approuvé',
    className: 'bg-[#10B981] text-white border-[#10B981]',
    Icon: CheckCircle,
  },
  validated: {
    label: 'Validé',
    className: 'bg-[#10B981] text-white border-[#10B981]',
    Icon: CheckCircle,
  },
  generated: {
    label: 'Généré',
    className: 'bg-[#8B5CF6] text-white border-[#8B5CF6]',
    Icon: Package,
  },
  delivered: {
    label: 'Délivré',
    className: 'bg-[#0F172A] text-white border-[#0F172A]',
    Icon: Package,
  },
  rejected: {
    label: 'Rejeté',
    className: 'bg-[#EF4444] text-white border-[#EF4444]',
    Icon: XCircle,
  },
  completed: {
    label: 'Terminé',
    className: 'bg-[#0F172A] text-white border-[#0F172A]',
    Icon: CheckCircle,
  },
};

export function StatusBadge({ status, className = '' }) {
  const config = STATUS_CONFIG[status] || {
    label: status,
    className: 'bg-layer-3 text-text-200 border-border-strong',
    Icon: null,
  };
  const { Icon } = config;

  return (
    <Badge className={`${config.className} ${className} text-xs font-medium px-2.5 py-1 inline-flex items-center gap-1.5`}>
      {Icon && <Icon className="h-3 w-3 flex-shrink-0" aria-hidden="true" />}
      {config.label}
    </Badge>
  );
}
