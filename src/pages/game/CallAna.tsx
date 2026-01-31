import { useEffect, useState } from 'react'
import { useLocation } from 'wouter'
import { motion } from 'framer-motion'
import { Phone, Volume2 } from 'lucide-react'
import { useTimer } from '../../hooks/useTimer'
import { useAudio } from '../../hooks/useAudio'

export default function CallAna() {
  const [, setLocation] = useLocation()
  const [callEnded, setCallEnded] = useState(false)
  const timer = useTimer()

  // Audio da ligacao da ECHO
  const callAudio = useAudio('/assets/audios/audio_final_echo.m4a', {
    onEnded: () => {
      setCallEnded(true)
      timer.stop()
    }
  })

  useEffect(() => {
    // Inicia a chamada imediatamente
    timer.start()
    callAudio.play()

    return () => {
      callAudio.stop()
    }
  }, [])

  const handleContinue = () => {
    setLocation('/game/notificacao')
  }

  if (callEnded) {
    return (
      <div
        className="min-h-screen bg-black flex flex-col items-center justify-center cursor-pointer"
        onClick={handleContinue}
      >
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center"
        >
          <div className="w-20 h-20 rounded-full bg-white/10 flex items-center justify-center mx-auto mb-4">
            <Phone className="w-10 h-10 text-white/50" />
          </div>
          <h2 className="text-xl text-white mb-1">Chamada Encerrada</h2>
          <p className="text-white/50 mb-6">{timer.formatted}</p>
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="text-white/40 text-sm"
          >
            Toque para continuar
          </motion.p>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-black flex flex-col">
      {/* Fundo */}
      <div className="absolute inset-0 bg-gradient-to-b from-pink-900/20 to-black" />

      {/* Conteúdo */}
      <div
        className="relative z-10 flex flex-col items-center h-screen"
        style={{ paddingTop: '80px', paddingBottom: '100px', paddingLeft: '24px', paddingRight: '24px' }}
      >
        {/* Info do chamador */}
        <div className="text-center" style={{ marginBottom: '40px' }}>
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="rounded-full overflow-hidden border-2 border-pink-500/30"
            style={{ width: '96px', height: '96px', margin: '0 auto 16px auto' }}
          >
            <img src="/assets/images/proofs/Echo.png" alt="ECHO" className="w-full h-full object-cover" />
          </motion.div>
          <h1 className="text-2xl font-light text-white" style={{ marginBottom: '4px' }}>ECHO</h1>
          <p className="text-call-green text-sm">{timer.formatted}</p>
        </div>

        {/* Waveform / Indicador de áudio */}
        <div className="flex items-center justify-center" style={{ gap: '3px' }}>
          {[8, 16, 24, 16, 28, 20, 12, 24, 16, 8, 20, 12].map((maxHeight, i) => (
            <motion.div
              key={i}
              className="bg-pink-400 rounded-full"
              style={{ width: '3px' }}
              animate={{ height: [4, maxHeight, 4] }}
              transition={{
                duration: 0.8,
                repeat: Infinity,
                delay: i * 0.1,
                ease: "easeInOut"
              }}
            />
          ))}
        </div>

        {/* Spacer */}
        <div style={{ flex: 1 }} />

        {/* Indicador de volume */}
        <div className="flex items-center gap-2 text-white/50" style={{ marginBottom: '24px' }}>
          <Volume2 className="w-4 h-4" />
          <span className="text-sm">Alto-falante ativado</span>
        </div>

        {/* Botão de encerrar (visual) */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="rounded-full bg-call-red/20 flex items-center justify-center border border-call-red/50"
          style={{ width: '64px', height: '64px' }}
        >
          <Phone className="w-7 h-7 text-call-red rotate-[135deg]" />
        </motion.div>
      </div>
    </div>
  )
}
