import { useLocation } from 'wouter'
import { motion } from 'framer-motion'
import { Volume2 } from 'lucide-react'

export default function GameLanding() {
  const [, setLocation] = useLocation()

  const handleStart = () => {
    setLocation('/game/ligacao')
  }

  return (
    <div className="min-h-screen bg-background flex flex-col items-center justify-center px-6">
      {/* Background sutil */}
      <div className="absolute inset-0 bg-gradient-to-b from-purple-900/10 to-transparent pointer-events-none" />

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="text-center max-w-md relative z-10"
      >
        {/* Texto principal */}
        <h1 className="text-2xl md:text-3xl font-medium text-white leading-relaxed mb-8">
          Voce esta preparado para viver uma experiencia{' '}
          <span className="gradient-text font-semibold">
            diferente de tudo que ja viu?
          </span>
        </h1>

        {/* Aviso de som */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.3 }}
          className="flex items-center justify-center gap-2 text-muted-foreground mb-12"
        >
          <Volume2 className="w-5 h-5 animate-pulse" />
          <span className="text-sm">Aumente o som para uma melhor experiencia</span>
        </motion.div>

        {/* Botao */}
        <motion.button
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.5 }}
          onClick={handleStart}
          className="relative cta-gradient text-white font-bold text-lg px-12 py-4 rounded-full
                     transition-all duration-300 hover:scale-105 active:scale-95
                     shadow-lg shadow-purple-500/25 pulse-ring"
        >
          ESTOU PRONTO
        </motion.button>
      </motion.div>
    </div>
  )
}
