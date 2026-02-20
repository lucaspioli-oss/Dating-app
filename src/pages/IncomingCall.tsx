import { useEffect, useState } from 'react'
import { useLocation } from 'wouter'
import { motion } from 'framer-motion'
import { Phone, PhoneOff } from 'lucide-react'
import { useVibration } from '@/hooks/useVibration'
import { useAudio } from '@/hooks/useAudio'

export default function IncomingCall() {
  const [, setLocation] = useLocation()
  const [showDeclineMessage, setShowDeclineMessage] = useState(false)
  const { startPhoneVibration, stopVibration } = useVibration()

  // Som de toque - usando um placeholder por enquanto
  const ringtone = useAudio('/assets/audios/effects/toque celular.m4a', {
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
    setLocation('/ligacao/code')
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

      {/* Conteudo */}
      <div
        className="relative z-10 flex flex-col items-center h-screen"
        style={{ paddingLeft: '24px', paddingRight: '24px', paddingTop: '80px', paddingBottom: '60px' }}
      >
        {/* Info do chamador */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center flex flex-col items-center"
          style={{ gap: '24px' }}
        >
          {/* Avatar */}
          <motion.div
            animate={{ scale: [1, 1.05, 1] }}
            transition={{ duration: 2, repeat: Infinity }}
            className="rounded-full overflow-hidden border-2 border-white/10"
            style={{ width: '112px', height: '112px' }}
          >
            <img src="/assets/images/NEO-final.png" alt="NEO" className="w-full h-full object-cover" />
          </motion.div>

          {/* Nome */}
          <div>
            <h1 className="text-3xl font-light text-white mb-2">NEO</h1>
            <p className="text-white/50 text-lg">Ligacao recebida...</p>
          </div>

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
        </motion.div>

        {/* Spacer */}
        <div style={{ flex: 1 }} />

        {/* Botoes de acao */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="flex items-center justify-center"
          style={{ gap: '100px' }}
        >
          {/* Recusar */}
          <button
            onClick={handleDecline}
            className="flex flex-col items-center"
            style={{ gap: '8px' }}
          >
            <div
              className="rounded-full bg-call-red flex items-center justify-center transition-transform active:scale-90"
              style={{ width: '72px', height: '72px' }}
            >
              <PhoneOff className="w-8 h-8 text-white" />
            </div>
            <span className="text-white/70 text-sm">Recusar</span>
          </button>

          {/* Atender */}
          <button
            onClick={handleAnswer}
            className="flex flex-col items-center"
            style={{ gap: '8px' }}
          >
            <motion.div
              animate={{ scale: [1, 1.1, 1] }}
              transition={{ duration: 0.5, repeat: Infinity }}
              className="rounded-full bg-call-green flex items-center justify-center
                         transition-transform active:scale-90 shadow-lg shadow-call-green/50"
              style={{ width: '72px', height: '72px' }}
            >
              <Phone className="w-8 h-8 text-white" />
            </motion.div>
            <span className="text-white/70 text-sm">Atender</span>
          </button>
        </motion.div>
      </div>
    </div>
  )
}
