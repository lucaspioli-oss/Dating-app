import { useState, useEffect } from 'react'
import { useLocation } from 'wouter'
import { motion } from 'framer-motion'
import { Phone, User, Delete } from 'lucide-react'
import { useAudio } from '../../hooks/useAudio'

const PHONE_NUMBER = '345 9450-4335'
const CONTACT_NAME = 'Ana'

export default function Dialer() {
  const [, setLocation] = useLocation()
  const [isCalling, setIsCalling] = useState(false)
  const [ringCount, setRingCount] = useState(0)

  // Som de chamando
  const dialTone = useAudio('/assets/audios/effects/chamando.mp3', {
    onEnded: () => {
      // Conta os toques
      setRingCount(prev => prev + 1)
    }
  })

  useEffect(() => {
    // Após 3 toques, vai para a ligação da Ana
    if (ringCount >= 3) {
      dialTone.stop()
      setLocation('/game/ligacao/ana')
    } else if (isCalling && ringCount > 0) {
      // Toca novamente
      dialTone.play()
    }
  }, [ringCount, isCalling])

  const handleCall = () => {
    setIsCalling(true)
    dialTone.play()
  }

  // Teclado numérico decorativo
  const dialPad = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#']

  if (isCalling) {
    return (
      <div className="min-h-screen bg-black flex flex-col items-center justify-center">
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="text-center"
        >
          {/* Avatar */}
          <motion.div
            animate={{ scale: [1, 1.05, 1] }}
            transition={{ duration: 1.5, repeat: Infinity }}
            className="w-24 h-24 rounded-full bg-gradient-to-br from-pink-500/30 to-purple-500/30
                       flex items-center justify-center mx-auto mb-6
                       border-2 border-white/20"
          >
            <User className="w-12 h-12 text-white/70" />
          </motion.div>

          <h2 className="text-2xl text-white mb-2">{CONTACT_NAME}</h2>
          <p className="text-white/50 mb-1">{PHONE_NUMBER}</p>

          <motion.p
            animate={{ opacity: [1, 0.5, 1] }}
            transition={{ duration: 1, repeat: Infinity }}
            className="text-call-green"
          >
            Chamando...
          </motion.p>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-black flex flex-col">
      {/* Header com número */}
      <div className="pt-12 pb-6 px-6 text-center">
        {/* Avatar pequeno */}
        <div className="w-16 h-16 rounded-full bg-gradient-to-br from-pink-500/30 to-purple-500/30
                       flex items-center justify-center mx-auto mb-3
                       border border-white/20">
          <User className="w-8 h-8 text-white/70" />
        </div>

        <p className="text-white/50 text-sm mb-1">{CONTACT_NAME}</p>

        {/* Número */}
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-3xl font-light text-white tracking-wider"
        >
          {PHONE_NUMBER}
        </motion.div>
      </div>

      {/* Teclado numérico (decorativo) */}
      <div className="flex-1 px-8 py-4">
        <div className="grid grid-cols-3 gap-4 max-w-xs mx-auto">
          {dialPad.map((digit) => (
            <button
              key={digit}
              className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center
                         text-2xl text-white/70 mx-auto
                         transition-colors hover:bg-white/10 active:bg-white/20"
            >
              {digit}
            </button>
          ))}
        </div>

        {/* Botão de apagar (decorativo) */}
        <div className="flex justify-end max-w-xs mx-auto mt-2 pr-2">
          <button className="p-3 text-white/50">
            <Delete className="w-6 h-6" />
          </button>
        </div>
      </div>

      {/* Botão de ligar */}
      <div className="pb-12 px-6">
        <motion.button
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          onClick={handleCall}
          className="w-16 h-16 rounded-full bg-call-green flex items-center justify-center
                     mx-auto shadow-lg shadow-call-green/30
                     transition-transform active:scale-90 hover:bg-call-green/90"
        >
          <Phone className="w-7 h-7 text-white" />
        </motion.button>
      </div>
    </div>
  )
}
