import { useState, useEffect, useRef, useCallback } from 'react'
import { useLocation } from 'wouter'
import { motion, AnimatePresence } from 'framer-motion'
import { Phone, Volume2, MessageCircle } from 'lucide-react'

const PHONE_NUMBER = '345 9450-4335'
const CONTACT_NAME = 'ECHO'

type Stage = 'dialer' | 'calling' | 'call' | 'notification'

export default function Dialer() {
  const [, setLocation] = useLocation()
  const [stage, setStage] = useState<Stage>('dialer')
  const [showNotification, setShowNotification] = useState(false)
  const [currentTime, setCurrentTime] = useState('')
  const [callTime, setCallTime] = useState(0)
  const callTimerRef = useRef<number | null>(null)

  // Refs para os áudios
  const dialToneRef = useRef<HTMLAudioElement | null>(null)
  const echoAudioRef = useRef<HTMLAudioElement | null>(null)
  const notifSoundRef = useRef<HTMLAudioElement | null>(null)

  // Formata o tempo da chamada
  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  // Inicializa os áudios uma vez
  useEffect(() => {
    // Som de chamando
    const dialTone = new Audio('/assets/audios/effects/chamada.mp3')
    dialTone.loop = true
    dialToneRef.current = dialTone

    // Áudio da Echo
    const echoAudio = new Audio('/assets/audios/voices/audio_final_echo.m4a')
    echoAudioRef.current = echoAudio

    // Som de notificação
    const notifSound = new Audio('/assets/audios/effects/notificacao_whats.m4a')
    notifSoundRef.current = notifSound

    return () => {
      dialTone.pause()
      echoAudio.pause()
      notifSound.pause()
    }
  }, [])

  // Função para iniciar a chamada (clicou em ligar)
  const handleCall = useCallback(() => {
    setStage('calling')

    // Toca som de chamando
    if (dialToneRef.current) {
      dialToneRef.current.currentTime = 0
      dialToneRef.current.play().catch(console.error)
    }

    // Após 8 segundos, para o som e inicia a ligação
    setTimeout(() => {
      if (dialToneRef.current) {
        dialToneRef.current.pause()
        dialToneRef.current.currentTime = 0
      }

      setStage('call')
      setCallTime(0)

      // Inicia contador de tempo
      callTimerRef.current = setInterval(() => {
        setCallTime(prev => prev + 1)
      }, 1000)

      // Toca áudio da Echo
      if (echoAudioRef.current) {
        echoAudioRef.current.currentTime = 0
        echoAudioRef.current.play().catch(console.error)

        // Quando terminar, vai para notificação
        echoAudioRef.current.onended = () => {
          if (callTimerRef.current) {
            clearInterval(callTimerRef.current)
          }

          setTimeout(() => {
            setStage('notification')
          }, 1500)
        }
      }
    }, 8000)
  }, [])

  // Quando muda para tela de notificação
  useEffect(() => {
    if (stage === 'notification') {
      const updateTime = () => {
        const now = new Date()
        setCurrentTime(now.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }))
      }
      updateTime()
      const interval = setInterval(updateTime, 1000)

      // Mostra notificação após 2 segundos e toca som
      const notifTimer = setTimeout(() => {
        setShowNotification(true)
        if (notifSoundRef.current) {
          notifSoundRef.current.currentTime = 0
          notifSoundRef.current.play().catch(console.error)
        }
      }, 2000)

      return () => {
        clearInterval(interval)
        clearTimeout(notifTimer)
      }
    }
  }, [stage])

  const handleNotificationClick = () => {
    setLocation('/game/chat')
  }

  const dialPad = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#']

  // ==================== TELA DE NOTIFICAÇÃO ====================
  if (stage === 'notification') {
    return (
      <div className="min-h-screen bg-black flex flex-col">
        <div className="absolute inset-0 bg-gradient-to-b from-gray-900 via-black to-black" />

        <div
          className="relative z-10 flex items-center justify-between text-white/70 text-sm"
          style={{ padding: '12px 24px' }}
        >
          <span>{currentTime}</span>
          <div className="flex items-center gap-1">
            <div className="flex gap-0.5">
              <div className="w-1 h-2 bg-white/70 rounded-sm" />
              <div className="w-1 h-3 bg-white/70 rounded-sm" />
              <div className="w-1 h-4 bg-white/70 rounded-sm" />
              <div className="w-1 h-3 bg-white/50 rounded-sm" />
            </div>
            <span style={{ marginLeft: '8px' }}>85%</span>
          </div>
        </div>

        <div className="relative z-10 text-center" style={{ marginTop: '80px' }}>
          <h1 className="text-white font-light" style={{ fontSize: '72px', letterSpacing: '2px' }}>
            {currentTime}
          </h1>
          <p className="text-white/50" style={{ fontSize: '18px', marginTop: '8px' }}>
            {new Date().toLocaleDateString('pt-BR', { weekday: 'long', day: 'numeric', month: 'long' })}
          </p>
        </div>

        <div className="relative z-10 flex-1" style={{ padding: '40px 16px' }}>
          <AnimatePresence>
            {showNotification && (
              <motion.div
                initial={{ opacity: 0, y: -50, scale: 0.9 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                transition={{ type: 'spring', damping: 20, stiffness: 300 }}
                onClick={handleNotificationClick}
                className="cursor-pointer"
              >
                <div
                  className="rounded-2xl backdrop-blur-xl"
                  style={{
                    background: 'rgba(255, 255, 255, 0.1)',
                    border: '1px solid rgba(255, 255, 255, 0.1)',
                    padding: '12px 16px'
                  }}
                >
                  <div className="flex items-center gap-3" style={{ marginBottom: '8px' }}>
                    <div
                      className="rounded-full bg-green-500 flex items-center justify-center"
                      style={{ width: '32px', height: '32px' }}
                    >
                      <MessageCircle className="w-4 h-4 text-white" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <span className="text-white font-medium" style={{ fontSize: '14px' }}>WhatsApp</span>
                        <span className="text-white/50" style={{ fontSize: '12px' }}>agora</span>
                      </div>
                    </div>
                  </div>

                  <div style={{ marginLeft: '44px' }}>
                    <p className="text-white font-medium" style={{ fontSize: '15px', marginBottom: '2px' }}>
                      ECHO
                    </p>
                    <p className="text-white/70" style={{ fontSize: '14px' }}>
                      🎤 Mensagem de voz
                    </p>
                  </div>
                </div>

                <motion.p
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 1 }}
                  className="text-center text-white/40"
                  style={{ fontSize: '12px', marginTop: '16px' }}
                >
                  Toque para abrir
                </motion.p>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <div className="relative z-10" style={{ paddingBottom: '20px' }}>
          <div
            className="mx-auto rounded-full bg-white/30"
            style={{ width: '120px', height: '4px' }}
          />
        </div>
      </div>
    )
  }

  // ==================== TELA DE LIGAÇÃO (ECHO) ====================
  if (stage === 'call') {
    return (
      <div className="min-h-screen bg-black flex flex-col">
        <div className="absolute inset-0 bg-gradient-to-b from-pink-900/20 to-black" />

        <div
          className="relative z-10 flex flex-col items-center h-screen"
          style={{ paddingTop: '80px', paddingBottom: '100px', paddingLeft: '24px', paddingRight: '24px' }}
        >
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
            <p className="text-call-green text-sm">{formatTime(callTime)}</p>
          </div>

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

          <div style={{ flex: 1 }} />

          <div className="flex items-center gap-2 text-white/50" style={{ marginBottom: '24px' }}>
            <Volume2 className="w-4 h-4" />
            <span className="text-sm">Alto-falante ativado</span>
          </div>

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

  // ==================== TELA CHAMANDO ====================
  if (stage === 'calling') {
    return (
      <div className="min-h-screen bg-black flex flex-col items-center">
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="text-center flex flex-col items-center"
          style={{ paddingTop: '100px', gap: '40px' }}
        >
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

  // ==================== TELA DO DISCADOR ====================
  return (
    <div className="min-h-screen bg-black flex flex-col items-center">
      <div className="text-center" style={{ paddingTop: '48px', paddingBottom: '24px' }}>
        <div
          className="rounded-full overflow-hidden border border-white/20"
          style={{ width: '64px', height: '64px', margin: '0 auto 12px auto' }}
        >
          <img src="/assets/images/proofs/Echo.png" alt="ECHO" className="w-full h-full object-cover" />
        </div>

        <p className="text-white/50 text-sm" style={{ marginBottom: '4px' }}>{CONTACT_NAME}</p>

        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-3xl font-light text-white tracking-wider"
        >
          {PHONE_NUMBER}
        </motion.div>
      </div>

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
