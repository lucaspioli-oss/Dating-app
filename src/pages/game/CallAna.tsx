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

  // Áudio da ligação da Ana
  const callAudio = useAudio('/assets/audios/voices/ana_ligacao.mp3', {
    onEnded: () => {
      setCallEnded(true)
      timer.stop()
    }
  })

  useEffect(() => {
    // Inicia a chamada após pequeno delay
    const startTimer = setTimeout(() => {
      timer.start()
      callAudio.play()
    }, 500)

    return () => {
      clearTimeout(startTimer)
      callAudio.stop()
    }
  }, [])

  useEffect(() => {
    // Quando a chamada termina, vai para o chat após 1.5s
    if (callEnded) {
      const redirectTimer = setTimeout(() => {
        setLocation('/game/chat')
      }, 1500)
      return () => clearTimeout(redirectTimer)
    }
  }, [callEnded, setLocation])

  if (callEnded) {
    return (
      <div className="min-h-screen bg-black flex flex-col items-center justify-center">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center"
        >
          <div className="w-20 h-20 rounded-full bg-white/10 flex items-center justify-center mx-auto mb-4">
            <Phone className="w-10 h-10 text-white/50" />
          </div>
          <h2 className="text-xl text-white mb-1">Chamada Encerrada</h2>
          <p className="text-white/50">{timer.formatted}</p>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-black flex flex-col">
      {/* Fundo */}
      <div className="absolute inset-0 bg-gradient-to-b from-pink-900/20 to-black" />

      {/* Conteúdo */}
      <div className="relative z-10 flex flex-col items-center h-screen py-12 px-6">
        {/* Info do chamador */}
        <div className="text-center mb-8">
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="w-24 h-24 rounded-full overflow-hidden mx-auto mb-4
                       border-2 border-pink-500/30"
          >
            {/* Avatar da Ana - placeholder */}
            <div className="w-full h-full bg-gradient-to-br from-pink-500/40 to-purple-500/40
                           flex items-center justify-center">
              <span className="text-3xl font-semibold text-white">A</span>
            </div>
          </motion.div>
          <h1 className="text-2xl font-light text-white mb-1">Ana</h1>
          <p className="text-call-green text-sm">{timer.formatted}</p>
        </div>

        {/* Waveform / Indicador de áudio */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.3 }}
          className="flex items-center justify-center gap-1 mb-8"
        >
          {[...Array(16)].map((_, i) => (
            <motion.div
              key={i}
              className="w-1 bg-pink-400 rounded-full"
              animate={{
                height: callAudio.isPlaying ? [4, 8 + Math.random() * 20, 4] : 4
              }}
              transition={{
                duration: 0.2 + Math.random() * 0.2,
                repeat: Infinity,
                delay: i * 0.04
              }}
            />
          ))}
        </motion.div>

        {/* Spacer */}
        <div className="flex-1" />

        {/* Indicador de volume */}
        <div className="flex items-center gap-2 text-white/50 mb-4">
          <Volume2 className="w-4 h-4" />
          <span className="text-sm">Alto-falante ativado</span>
        </div>

        {/* Botão de encerrar (visual) */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="w-16 h-16 rounded-full bg-call-red/20 flex items-center justify-center
                     border border-call-red/50"
        >
          <Phone className="w-7 h-7 text-call-red rotate-[135deg]" />
        </motion.div>
        <p className="text-white/50 text-xs mt-2">Em chamada</p>
      </div>
    </div>
  )
}
