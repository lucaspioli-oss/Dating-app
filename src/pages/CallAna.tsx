import { useEffect, useState, useRef } from 'react'
import { useLocation } from 'wouter'
import { motion, AnimatePresence } from 'framer-motion'
import { Phone, Volume2, MessageCircle } from 'lucide-react'
import { useTimer } from '@/hooks/useTimer'
import { useAudio } from '@/hooks/useAudio'

type Stage = 'call' | 'notification'

export default function CallAna() {
  const [, setLocation] = useLocation()
  const [stage, setStage] = useState<Stage>('call')
  const [showNotification, setShowNotification] = useState(false)
  const [currentTime, setCurrentTime] = useState('')
  const timer = useTimer()
  const notificationSoundRef = useRef<HTMLAudioElement | null>(null)

  // Audio da ligacao da ECHO
  const callAudio = useAudio('/assets/audios/voices/audio_final_echo.m4a', {
    onEnded: () => {
      timer.stop()
      // Muda para tela de notificação após 1.5s
      setTimeout(() => {
        setStage('notification')
      }, 1500)
    }
  })

  // Pré-carrega o som de notificação
  useEffect(() => {
    const audio = new Audio('/assets/audios/effects/notificacao_whats.m4a')
    audio.preload = 'auto'
    notificationSoundRef.current = audio
  }, [])

  // Inicia a chamada
  useEffect(() => {
    timer.start()
    callAudio.play()

    return () => {
      callAudio.stop()
    }
  }, [])

  // Quando muda para tela de notificação
  useEffect(() => {
    if (stage === 'notification') {
      // Atualiza horário
      const updateTime = () => {
        const now = new Date()
        setCurrentTime(now.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }))
      }
      updateTime()
      const interval = setInterval(updateTime, 1000)

      // Mostra notificação após 2 segundos e toca som
      const notifTimer = setTimeout(() => {
        setShowNotification(true)
        // Toca o som
        if (notificationSoundRef.current) {
          notificationSoundRef.current.currentTime = 0
          notificationSoundRef.current.volume = 1
          notificationSoundRef.current.play().catch(() => {})
        }
      }, 2000)

      return () => {
        clearInterval(interval)
        clearTimeout(notifTimer)
      }
    }
  }, [stage])

  const handleNotificationClick = () => {
    setLocation('/chat')
  }

  // Tela de notificação (lock screen)
  if (stage === 'notification') {
    return (
      <div className="min-h-screen bg-black flex flex-col">
        {/* Wallpaper escuro */}
        <div className="absolute inset-0 bg-gradient-to-b from-gray-900 via-black to-black" />

        {/* Status bar */}
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

        {/* Horário grande */}
        <div className="relative z-10 text-center" style={{ marginTop: '80px' }}>
          <h1 className="text-white font-light" style={{ fontSize: '72px', letterSpacing: '2px' }}>
            {currentTime}
          </h1>
          <p className="text-white/50" style={{ fontSize: '18px', marginTop: '8px' }}>
            {new Date().toLocaleDateString('pt-BR', { weekday: 'long', day: 'numeric', month: 'long' })}
          </p>
        </div>

        {/* Área de notificações */}
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
                  {/* Header da notificação */}
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

                  {/* Conteúdo */}
                  <div style={{ marginLeft: '44px' }}>
                    <p className="text-white font-medium" style={{ fontSize: '15px', marginBottom: '2px' }}>
                      ECHO
                    </p>
                    <p className="text-white/70" style={{ fontSize: '14px' }}>
                      🎤 Mensagem de voz
                    </p>
                  </div>
                </div>

                {/* Dica para clicar */}
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

        {/* Indicador de swipe (decorativo) */}
        <div className="relative z-10" style={{ paddingBottom: '20px' }}>
          <div
            className="mx-auto rounded-full bg-white/30"
            style={{ width: '120px', height: '4px' }}
          />
        </div>
      </div>
    )
  }

  // Tela de chamada
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
