import { useState, useEffect } from 'react'
import { useLocation } from 'wouter'
import { motion } from 'framer-motion'
import { Phone } from 'lucide-react'
import { useAudio } from '../../hooks/useAudio'

const PHONE_NUMBER = '345 9450-4335'
const CONTACT_NAME = 'ECHO'

export default function Dialer() {
  const [, setLocation] = useLocation()
  const [isCalling, setIsCalling] = useState(false)

  // Som de chamando
  const dialTone = useAudio('/assets/audios/effects/chamada.mp3', {
    loop: true
  })

  useEffect(() => {
    // Após 4 segundos chamando, vai para a ligação da ECHO
    if (isCalling) {
      const timer = setTimeout(() => {
        dialTone.stop()
        setLocation('/game/ligacao/ana')
      }, 8000)
      return () => clearTimeout(timer)
    }
  }, [isCalling])

  const handleCall = () => {
    setIsCalling(true)
    dialTone.play()
  }

  // Teclado numérico decorativo
  const dialPad = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#']

  if (isCalling) {
    return (
      <div className="min-h-screen bg-black flex flex-col items-center">
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="text-center flex flex-col items-center"
          style={{ paddingTop: '100px', gap: '40px' }}
        >
          {/* Avatar */}
          <motion.div
            animate={{ scale: [1, 1.05, 1] }}
            transition={{ duration: 1.5, repeat: Infinity }}
            className="rounded-full overflow-hidden border-2 border-white/20"
            style={{ width: '120px', height: '120px' }}
          >
            <img src="/assets/images/proofs/Echo.png" alt="ECHO" className="w-full h-full object-cover" />
          </motion.div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', alignItems: 'center' }}>
            <h2 className="text-2xl text-white">{CONTACT_NAME}</h2>
            <p className="text-white/50">{PHONE_NUMBER}</p>
          </div>

          <motion.p
            animate={{ opacity: [1, 0.5, 1] }}
            transition={{ duration: 1, repeat: Infinity }}
            className="text-call-green text-lg"
          >
            Chamando...
          </motion.p>
        </motion.div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-black flex flex-col items-center">
      {/* Header com número */}
      <div className="text-center" style={{ paddingTop: '48px', paddingBottom: '24px' }}>
        {/* Avatar pequeno */}
        <div
          className="rounded-full overflow-hidden border border-white/20"
          style={{ width: '64px', height: '64px', margin: '0 auto 12px auto' }}
        >
          <img src="/assets/images/proofs/Echo.png" alt="ECHO" className="w-full h-full object-cover" />
        </div>

        <p className="text-white/50 text-sm" style={{ marginBottom: '4px' }}>{CONTACT_NAME}</p>

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
      <div style={{ flex: 1, padding: '16px' }}>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(3, 64px)',
            gap: '16px',
            justifyContent: 'center'
          }}
        >
          {dialPad.map((digit) => (
            <button
              key={digit}
              className="rounded-full bg-white/5 flex items-center justify-center text-white/70 transition-colors hover:bg-white/10 active:bg-white/20"
              style={{ width: '64px', height: '64px', fontSize: '28px' }}
            >
              {digit}
            </button>
          ))}
        </div>
      </div>

      {/* Botão de ligar */}
      <div style={{ paddingBottom: '100px' }}>
        <motion.button
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          onClick={handleCall}
          className="rounded-full bg-call-green flex items-center justify-center shadow-lg shadow-call-green/30 transition-transform active:scale-90 hover:bg-call-green/90"
          style={{ width: '64px', height: '64px' }}
        >
          <Phone className="w-7 h-7 text-white" />
        </motion.button>
      </div>
    </div>
  )
}
