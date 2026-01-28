import { useEffect, useState } from 'react'
import { useLocation } from 'wouter'
import { motion } from 'framer-motion'
import { Phone, PhoneOff, User } from 'lucide-react'
import { useVibration } from '../../hooks/useVibration'
import { useAudio } from '../../hooks/useAudio'

export default function IncomingCall() {
  const [, setLocation] = useLocation()
  const [showDeclineMessage, setShowDeclineMessage] = useState(false)
  const { startPhoneVibration, stopVibration } = useVibration()

  // Som de toque - usando um placeholder por enquanto
  const ringtone = useAudio('/assets/audios/effects/toque_celular.mp3', {
    loop: true
  })

  useEffect(() => {
    // Inicia vibração e toque após pequeno delay
    const timer = setTimeout(() => {
      startPhoneVibration()
      ringtone.play()
    }, 500)

    return () => {
      clearTimeout(timer)
      stopVibration()
      ringtone.stop()
    }
  }, [])

  const handleAnswer = () => {
    stopVibration()
    ringtone.stop()
    setLocation('/game/ligacao/code')
  }

  const handleDecline = () => {
    stopVibration()
    ringtone.stop()
    setShowDeclineMessage(true)
  }

  const handleRetry = () => {
    setShowDeclineMessage(false)
    startPhoneVibration()
    ringtone.play()
  }

  if (showDeclineMessage) {
    return (
      <div className="min-h-screen bg-black flex flex-col items-center justify-center px-6">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center"
        >
          <div className="w-20 h-20 rounded-full bg-red-500/20 flex items-center justify-center mx-auto mb-6">
            <PhoneOff className="w-10 h-10 text-red-500" />
          </div>
          <h2 className="text-xl font-semibold text-white mb-2">Chamada perdida</h2>
          <p className="text-white/50 mb-8">Você recusou a ligação</p>
          <button
            onClick={handleRetry}
            className="bg-call-green text-white font-semibold px-8 py-3 rounded-full
                       transition-all hover:bg-call-green/90"
          >
            Ligar de volta
          </button>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-black flex flex-col">
      {/* Fundo gradiente */}
      <div className="absolute inset-0 bg-gradient-to-b from-gray-900 to-black" />

      {/* Conteúdo */}
      <div className="relative z-10 flex flex-col items-center justify-between h-screen py-16 px-6">
        {/* Info do chamador */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center"
        >
          {/* Avatar */}
          <motion.div
            animate={{ scale: [1, 1.05, 1] }}
            transition={{ duration: 2, repeat: Infinity }}
            className="w-28 h-28 rounded-full bg-gradient-to-br from-gray-700 to-gray-800
                       flex items-center justify-center mx-auto mb-6
                       border-2 border-white/10"
          >
            <User className="w-14 h-14 text-white/50" />
          </motion.div>

          {/* Nome */}
          <h1 className="text-3xl font-light text-white mb-2">Número Desconhecido</h1>
          <p className="text-white/50 text-lg">Ligação recebida...</p>
        </motion.div>

        {/* Indicador de chamada */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.3 }}
          className="flex items-center gap-2 text-white/50"
        >
          <motion.div
            animate={{ opacity: [1, 0.3, 1] }}
            transition={{ duration: 1, repeat: Infinity }}
            className="w-2 h-2 rounded-full bg-call-green"
          />
          <span>Chamando...</span>
        </motion.div>

        {/* Botões de ação */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="flex items-center justify-center gap-16"
        >
          {/* Recusar */}
          <button
            onClick={handleDecline}
            className="flex flex-col items-center gap-2"
          >
            <div className="w-16 h-16 rounded-full bg-call-red flex items-center justify-center
                           transition-transform active:scale-90">
              <PhoneOff className="w-7 h-7 text-white" />
            </div>
            <span className="text-white/70 text-sm">Recusar</span>
          </button>

          {/* Atender */}
          <button
            onClick={handleAnswer}
            className="flex flex-col items-center gap-2"
          >
            <motion.div
              animate={{ scale: [1, 1.1, 1] }}
              transition={{ duration: 0.5, repeat: Infinity }}
              className="w-16 h-16 rounded-full bg-call-green flex items-center justify-center
                         transition-transform active:scale-90 shadow-lg shadow-call-green/50"
            >
              <Phone className="w-7 h-7 text-white" />
            </motion.div>
            <span className="text-white/70 text-sm">Atender</span>
          </button>
        </motion.div>
      </div>
    </div>
  )
}
