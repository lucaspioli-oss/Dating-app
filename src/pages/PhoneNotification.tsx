import { useState, useEffect, useRef } from 'react'
import { useLocation } from 'wouter'
import { motion, AnimatePresence } from 'framer-motion'
import { MessageCircle } from 'lucide-react'

export default function PhoneNotification() {
  const [, setLocation] = useLocation()
  const [showNotification, setShowNotification] = useState(false)
  const [currentTime, setCurrentTime] = useState('')
  const notificationSoundRef = useRef<HTMLAudioElement | null>(null)

  useEffect(() => {
    // Pré-carrega o áudio da notificação
    const audio = new Audio('/assets/audios/effects/notificacao_whats.m4a')
    audio.preload = 'auto'
    notificationSoundRef.current = audio

    // Atualiza o horário
    const updateTime = () => {
      const now = new Date()
      setCurrentTime(now.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }))
    }
    updateTime()
    const interval = setInterval(updateTime, 1000)

    // Mostra notificação após 2 segundos
    const notifTimer = setTimeout(() => {
      setShowNotification(true)
      // Tenta tocar o som
      if (notificationSoundRef.current) {
        notificationSoundRef.current.currentTime = 0
        notificationSoundRef.current.volume = 1
        const playPromise = notificationSoundRef.current.play()
        if (playPromise !== undefined) {
          playPromise.catch((error) => {
            console.log('Audio play failed:', error)
          })
        }
      }
    }, 2000)

    return () => {
      clearInterval(interval)
      clearTimeout(notifTimer)
      if (notificationSoundRef.current) {
        notificationSoundRef.current.pause()
      }
    }
  }, [])

  const handleNotificationClick = () => {
    setLocation('/chat')
  }

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
