import { useState, useEffect } from "react";
import { getNdiogoyeLogs } from "@/api/ai";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/components/ui/use-toast";

export default function NdiogoyeLogs() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  useEffect(() => {
    loadLogs();
  }, []);

  const loadLogs = async () => {
    try {
      setLoading(true);
      const data = await getNdiogoyeLogs(1);
      setLogs(data.results || data);
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Impossible de charger les logs Ndiogoye.",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString("fr-FR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div>
        <h2 className="text-3xl font-bold tracking-tight text-text-100">Supervision Ndiogoye</h2>
        <p className="text-muted-foreground mt-2">
          Historique des requêtes et conversations avec l'assistant IA.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Historique des échanges</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-slate-900"></div>
            </div>
          ) : logs.length === 0 ? (
            <div className="text-center text-muted-foreground py-12 flex flex-col items-center">
              <span className="text-4xl mb-4">🤖</span>
              <p>Aucune conversation enregistrée pour le moment.</p>
            </div>
          ) : (
            <div className="rounded-md border overflow-x-auto">
              <table className="w-full text-sm text-left">
                <thead className="bg-layer-2 border-b">
                  <tr>
                    <th className="px-4 py-3 font-medium text-text-300">Date</th>
                    <th className="px-4 py-3 font-medium text-text-300">Utilisateur</th>
                    <th className="px-4 py-3 font-medium text-text-300">Session</th>
                    <th className="px-4 py-3 font-medium text-text-300">Intention</th>
                    <th className="px-4 py-3 font-medium text-text-300 w-1/4">Message (Citoyen)</th>
                    <th className="px-4 py-3 font-medium text-text-300 w-1/4">Réponse (Ndiogoye)</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {logs.map((log) => (
                    <tr key={log.id} className="hover:bg-layer-2 transition-colors">
                      <td className="px-4 py-3 whitespace-nowrap text-text-400">{formatDate(log.created_at)}</td>
                      <td className="px-4 py-3">
                        <div className="font-medium text-text-100">{log.user_name}</div>
                        <div className="text-xs text-text-400">{log.user_email || "-"}</div>
                      </td>
                      <td className="px-4 py-3 text-xs font-mono text-text-400">
                        {log.session_id.substring(0, 8)}
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant="outline" className="capitalize bg-blue-50 text-blue-700 border-blue-200">
                          {log.intent}
                        </Badge>
                      </td>
                      <td className="px-4 py-3">
                        <p className="line-clamp-2 text-text-200" title={log.message}>
                          {log.message}
                        </p>
                      </td>
                      <td className="px-4 py-3">
                        <p className="line-clamp-2 text-text-300" title={log.reply}>
                          {log.reply}
                        </p>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
