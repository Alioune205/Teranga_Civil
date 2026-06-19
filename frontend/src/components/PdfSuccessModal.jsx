import { useEffect, useState } from 'react';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { CheckCircle, FileDown, Eye } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export function PdfSuccessModal({ isOpen, onClose, dossier, onDownloadAgain }) {
  const navigate = useNavigate();
  const [progress, setProgress] = useState(100);

  useEffect(() => {
    if (!isOpen) {
      setProgress(100);
      return;
    }
    // Auto-close after 8 seconds
    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev <= 0) {
          clearInterval(interval);
          onClose();
          return 0;
        }
        return prev - (100 / (8000 / 50)); // 8000ms, update every 50ms
      });
    }, 50);

    return () => clearInterval(interval);
  }, [isOpen, onClose]);

  if (!dossier) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md text-center p-6 border-0 overflow-hidden">
        {/* Barre de progression en haut */}
        <div className="absolute top-0 left-0 right-0 h-1 bg-layer-3">
          <div 
            className="h-full bg-emerald-500 transition-all duration-75 ease-linear" 
            style={{ width: `${progress}%` }} 
          />
        </div>

        <DialogHeader className="flex flex-col items-center mt-4">
          <div className="h-16 w-16 rounded-full bg-emerald-50 text-emerald-500 flex items-center justify-center mb-4">
            <CheckCircle className="h-8 w-8" />
          </div>
          <DialogTitle className="text-xl">Acte généré avec succès</DialogTitle>
          <DialogDescription className="text-sm mt-2 text-center text-text-400">
            L'acte pour <strong className="text-text-200">{dossier.citoyen?.first_name} {dossier.citoyen?.last_name}</strong> a été généré et téléchargé sur votre appareil.
          </DialogDescription>
        </DialogHeader>

        <div className="bg-layer-2 p-4 rounded-lg text-sm text-left border border-border-subtle my-4 space-y-2">
          <div className="flex justify-between">
            <span className="text-text-400">Référence</span>
            <span className="font-mono font-semibold">{dossier.reference}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-text-400">Type</span>
            <span className="font-semibold">{dossier.type === 'birth_certificate' ? 'Acte de naissance' : dossier.type}</span>
          </div>
        </div>

        <DialogFooter className="flex-col sm:flex-row gap-2 sm:gap-0 sm:justify-center w-full mt-4">
          <Button variant="outline" className="w-full sm:w-auto" onClick={() => navigate(`/dossiers/${dossier.id}`)}>
            <Eye className="h-4 w-4 mr-2" />
            Voir le dossier
          </Button>
          <Button className="w-full sm:w-auto bg-emerald-600 hover:bg-emerald-700 text-white" onClick={() => onDownloadAgain(dossier)}>
            <FileDown className="h-4 w-4 mr-2" />
            Retélécharger
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
