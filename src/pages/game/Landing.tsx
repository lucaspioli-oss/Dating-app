import { useLocation } from 'wouter'
import { motion } from 'framer-motion'
import { Volume2 } from 'lucide-react'

export default function GameLanding() {
  const [, setLocation] = useLocation()

  const handleStart = () => {
    setLocation('/game/ligacao')
  }

  return (
    <div className="min-h-screen bg-background flex flex-col items-center justify-center" style={{ paddingBottom: '80px', paddingLeft: '32px', paddingRight: '32px' }}>
      {/* Background sutil */}
      <div className="absolute inset-0 bg-gradient-to-b from-purple-900/10 to-transparent pointer-events-none" />

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="text-center w-full max-w-sm relative z-10 px-2 flex flex-col items-center"
        style={{ gap: '60px' }}
      >
        {/* Texto principal */}
        <h1 className="text-2xl md:text-3xl font-medium text-white leading-snug">
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
          className="flex items-center justify-center gap-2 text-muted-foreground"
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
          className="relative cta-gradient text-white font-bold text-xl px-16 py-5 rounded-full
                     transition-all duration-300 hover:scale-105 active:scale-95
                     shadow-lg shadow-purple-500/25 pulse-ring w-full max-w-xs"
        >
          ESTOU PRONTO
        </motion.button>
      </motion.div>
    </div>
  )
}
