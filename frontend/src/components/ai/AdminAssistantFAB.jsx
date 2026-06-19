import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Sparkles, X, Send, Loader2, MessageSquare, Mic, Volume2, VolumeX } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import api from '@/api/axiosClient';

export default function AdminAssistantFAB() {
  const { user } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const [isMuted, setIsMuted] = useState(true);
  
  const messagesEndRef = useRef(null);
  
  // Speech Recognition
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  const recognition = useRef(null);

  useEffect(() => {
    if (SpeechRecognition) {
      recognition.current = new SpeechRecognition();
      recognition.current.continuous = false;
      recognition.current.interimResults = false;
      recognition.current.lang = 'fr-FR';

      recognition.current.onstart = () => setIsListening(true);
      recognition.current.onresult = (event) => {
        const transcript = event.results[0][0].transcript;
        setInputValue(prev => prev ? prev + ' ' + transcript : transcript);
      };
      recognition.current.onerror = (event) => {
        console.error('Erreur vocale:', event.error);
        setIsListening(false);
      };
      recognition.current.onend = () => setIsListening(false);
    }
  }, [SpeechRecognition]);

  const toggleListening = () => {
    if (isListening) {
      recognition.current?.stop();
    } else {
      recognition.current?.start();
    }
  };
  const toggleMute = () => {
    setIsMuted(!isMuted);
    if (!isMuted && window.speechSynthesis) {
      window.speechSynthesis.cancel();
    }
  };

  const speakText = (text) => {
    if (isMuted || !window.speechSynthesis) return;
    window.speechSynthesis.cancel(); // Stop current speech
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'fr-FR';
    window.speechSynthesis.speak(utterance);
  };

  // Vérification stricte des rôles
  const allowedRoles = ['super_admin', 'civil_admin', 'civil_admin_supervisor'];
  if (!user || !allowedRoles.includes(user.role)) {
    return null;
  }

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    if (isOpen && messages.length === 0) {
      setMessages([
        { 
          role: 'assistant', 
          content: `Bonjour ${user.first_name}, je suis votre Assistant Analytique Teranga Civil. Je peux analyser les statistiques de votre commune (ou globales). Posez-moi une question !` 
        }
      ]);
    }
  }, [isOpen]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async (text) => {
    if (!text.trim()) return;

    const newMsg = { role: 'user', content: text };
    setMessages((prev) => [...prev, newMsg]);
    setInputValue('');
    setIsLoading(true);

    try {
      const response = await api.post('/api/ai/assistant-query/', {
        question: text,
        chat_history: messages.filter(m => m.role !== 'system') // on envoie l'historique récent
      });
      const answer = response.data.answer;
      setMessages((prev) => [...prev, { role: 'assistant', content: answer }]);
      speakText(answer);
    } catch (error) {
      console.error('Erreur IA:', error);
      const errorMsg = error.response?.data?.error || "Désolé, je rencontre des difficultés pour analyser les données en ce moment.";
      setMessages((prev) => [...prev, { role: 'assistant', content: errorMsg }]);
      speakText(errorMsg);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend(inputValue);
    }
  };

  const suggestions = [
    "Demandes ce mois-ci",
    "Charge par agent",
    "Taux d'approbation",
    "Dossiers rejetés cette semaine"
  ];

  return (
    <div className="fab-container fixed bottom-6 right-6 z-[9999]">
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.95 }}
            transition={{ duration: 0.2 }}
            className="absolute bottom-20 right-0 w-[380px] bg-white rounded-2xl shadow-2xl border border-border-subtle flex flex-col overflow-hidden"
            style={{ height: '500px' }}
          >
            {/* Header */}
            <div className="bg-indigo-950 p-4 text-white flex justify-between items-center relative overflow-hidden">
              <div className="absolute inset-0 bg-gradient-to-r from-indigo-950 to-indigo-900 z-0"></div>
              <div className="absolute -top-10 -right-10 w-20 h-20 bg-amber-400 rounded-full blur-2xl opacity-20 z-0"></div>
              
              <div className="flex items-center space-x-3 relative z-10">
                <div className="bg-amber-400 p-2 rounded-xl">
                  <Sparkles className="w-5 h-5 text-indigo-950" />
                </div>
                <div>
                  <h3 className="font-bold text-sm">Assistant Teranga</h3>
                  <p className="text-xs text-indigo-200">Intelligence Artificielle</p>
                </div>
              </div>
              <div className="flex items-center space-x-1 relative z-10">
                <button 
                  onClick={toggleMute}
                  className={`p-2 rounded-full transition-colors ${!isMuted ? 'bg-amber-400 text-indigo-950' : 'hover:bg-white/20 text-white'}`}
                  title={isMuted ? "Activer le retour vocal" : "Désactiver le retour vocal"}
                >
                  {isMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
                </button>
                <button 
                  onClick={() => setIsOpen(false)}
                  className="p-2 hover:bg-white/20 rounded-full transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Chat Body */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-layer-2">
              {messages.map((msg, idx) => (
                <div 
                  key={idx} 
                  className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  <div 
                    className={`max-w-[85%] p-3 rounded-2xl text-sm shadow-sm ${
                      msg.role === 'user' 
                        ? 'bg-primary text-white rounded-tr-sm' 
                        : 'bg-white text-text-200 border border-border-subtle rounded-tl-sm'
                    }`}
                    dangerouslySetInnerHTML={{
                      __html: msg.role === 'user' 
                        ? msg.content.replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\n/g, '<br />')
                        : msg.content.replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>').replace(/\n/g, '<br />')
                    }}
                  />
                </div>
              ))}
              
              {isLoading && (
                <div className="flex justify-start">
                  <div className="bg-white border border-border-subtle p-3 rounded-2xl rounded-tl-sm shadow-sm flex space-x-2 items-center text-primary">
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span className="text-xs font-medium">Analyse en cours...</span>
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Suggestions */}
            {messages.length <= 2 && !isLoading && (
              <div className="px-4 pb-2 flex flex-wrap gap-2">
                {suggestions.map((sug, idx) => (
                  <button
                    key={idx}
                    onClick={() => handleSend(sug)}
                    className="text-xs bg-indigo-50 hover:bg-indigo-100 text-indigo-700 px-3 py-1.5 rounded-full transition-colors border border-indigo-100/50"
                  >
                    {sug}
                  </button>
                ))}
              </div>
            )}

            {/* Input Footer */}
            <div className="p-3 bg-white border-t border-border-subtle">
              <div className="relative flex items-center gap-2">
                <div className="relative flex-1">
                  <input
                    type="text"
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                    onKeyDown={handleKeyPress}
                    placeholder={isListening ? "Écoute en cours..." : "Posez votre question..."}
                    className={`w-full bg-layer-2 border text-sm rounded-full py-3 pl-4 pr-12 focus:outline-none transition-all ${
                      isListening ? 'border-red-400 ring-1 ring-red-400' : 'border-border-strong focus:border-primary focus:ring-1 focus:ring-primary'
                    }`}
                    disabled={isLoading || isListening}
                  />
                  <button
                    onClick={() => handleSend(inputValue)}
                    disabled={isLoading || !inputValue.trim()}
                    className="absolute right-2 top-1/2 -translate-y-1/2 p-2 bg-primary text-white rounded-full hover:bg-primary-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    <Send className="w-4 h-4" />
                  </button>
                </div>
                
                {SpeechRecognition && (
                  <button
                    onClick={toggleListening}
                    disabled={isLoading}
                    className={`p-3 rounded-full flex-shrink-0 transition-all shadow-sm ${
                      isListening 
                        ? 'bg-red-500 text-white animate-pulse shadow-red-200' 
                        : 'bg-white border border-border-strong text-text-300 hover:bg-layer-2 shadow-slate-100'
                    }`}
                    title="Saisie vocale"
                  >
                    <Mic className="w-5 h-5" />
                  </button>
                )}
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <motion.button
        onClick={() => setIsOpen(!isOpen)}
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        className="relative w-14 h-14 bg-amber-400 hover:bg-amber-500 text-indigo-950 rounded-full shadow-2xl shadow-amber-500/30 flex items-center justify-center z-[9999] border-2 border-white transition-colors"
      >
        {isOpen ? <X className="w-6 h-6" /> : <MessageSquare className="w-6 h-6 fill-current" />}
        {!isOpen && (
          <span className="absolute -top-1 -right-1 flex h-4 w-4">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
            <span className="relative inline-flex rounded-full h-4 w-4 bg-white border-2 border-amber-400"></span>
          </span>
        )}
      </motion.button>
    </div>
  );
}
