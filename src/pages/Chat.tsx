import { useEffect, useState, useRef } from 'react'
import { useLocation } from 'wouter'
import { motion, AnimatePresence } from 'framer-motion'
import { ArrowLeft, Phone, Video, MoreVertical, Play, Pause, Mic } from 'lucide-react'

interface VoiceMessage {
  id: string
  type: 'voice'
  audioUrl: string
  duration: string
  time: string
  isPlayed: boolean
}

interface TextMessage {
  id: string
  type: 'text'
  content: string
  time: string
  isLink?: boolean
}

type Message = VoiceMessage | TextMessage

function getCurrentTime() {
  return new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}

// Componente de mensagem de voz
function VoiceMessageBubble({
  message,
  onPlay,
  isPlaying,
  progress
}: {
  message: VoiceMessage
  onPlay: () => void
  isPlaying: boolean
  progress: number
}) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
      style={{
        display: 'flex',
        justifyContent: 'flex-start',
        marginBottom: '4px'
      }}
    >
      <div style={{
        backgroundColor: '#202C33',
        borderRadius: '8px',
        padding: '8px 12px',
        minWidth: '240px',
        maxWidth: '85%'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          {/* Avatar pequeno */}
          <div style={{
            width: '40px',
            height: '40px',
            borderRadius: '50%',
            overflow: 'hidden',
            flexShrink: 0
          }}>
            <img
              src="/assets/images/proofs/Echo.png"
              alt="ECHO"
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            />
          </div>

          {/* Botão play/pause */}
          <button
            onClick={onPlay}
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '50%',
              backgroundColor: '#00A884',
              border: 'none',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              flexShrink: 0
            }}
          >
            {isPlaying ? (
              <Pause className="w-4 h-4 text-white" fill="white" />
            ) : (
              <Play className="w-4 h-4 text-white" fill="white" style={{ marginLeft: '2px' }} />
            )}
          </button>

          {/* Waveform */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '4px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '2px', height: '20px' }}>
              {Array.from({ length: 30 }).map((_, i) => {
                const heights = [4, 8, 12, 6, 14, 8, 10, 16, 6, 12, 8, 14, 4, 10, 16, 8, 12, 6, 14, 10, 8, 12, 6, 10, 14, 8, 6, 12, 8, 4]
                const isActive = (i / 30) * 100 <= progress
                return (
                  <div
                    key={i}
                    style={{
                      width: '3px',
                      height: `${heights[i]}px`,
                      backgroundColor: isActive ? '#00A884' : '#3B4A54',
                      borderRadius: '2px',
                      transition: 'background-color 0.1s'
                    }}
                  />
                )
              })}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: '#8696A0', fontSize: '11px' }}>{message.duration}</span>
              <span style={{ color: 'rgba(255,255,255,0.5)', fontSize: '11px' }}>{message.time}</span>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  )
}

// Componente de mensagem de texto
function TextMessageBubble({
  message,
  onLinkClick
}: {
  message: TextMessage
  onLinkClick?: () => void
}) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
      style={{
        display: 'flex',
        justifyContent: 'flex-start',
        marginBottom: '4px'
      }}
    >
      <div style={{
        backgroundColor: '#202C33',
        borderRadius: '8px',
        padding: '6px 12px 8px 12px',
        maxWidth: '85%',
        position: 'relative'
      }}>
        {message.isLink ? (
          <div>
            <p style={{
              color: '#E9EDEF',
              fontSize: '14px',
              margin: 0,
              marginBottom: '8px'
            }}>
              {message.content}
            </p>
            <button
              onClick={onLinkClick}
              style={{
                background: 'linear-gradient(135deg, #7C3AED 0%, #DB2777 100%)',
                border: 'none',
                borderRadius: '8px',
                padding: '10px 20px',
                color: 'white',
                fontSize: '14px',
                fontWeight: 600,
                cursor: 'pointer',
                width: '100%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px'
              }}
            >
              🔓 Acessar Feed Secreto
            </button>
          </div>
        ) : (
          <p style={{
            color: '#E9EDEF',
            fontSize: '14px',
            margin: 0,
            paddingRight: '35px'
          }}>
            {message.content}
          </p>
        )}
        <span style={{
          position: 'absolute',
          bottom: '6px',
          right: '8px',
          fontSize: '11px',
          color: 'rgba(255,255,255,0.5)'
        }}>
          {message.time}
        </span>
      </div>
    </motion.div>
  )
}

// Indicador de gravando
function RecordingIndicator() {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      style={{
        display: 'flex',
        justifyContent: 'flex-start',
        marginBottom: '4px'
      }}
    >
      <div style={{
        backgroundColor: '#202C33',
        borderRadius: '8px',
        padding: '12px 16px',
        display: 'flex',
        alignItems: 'center',
        gap: '8px'
      }}>
        <motion.div
          animate={{ opacity: [1, 0.3, 1] }}
          transition={{ duration: 1, repeat: Infinity }}
        >
          <Mic className="w-5 h-5" style={{ color: '#EF4444' }} />
        </motion.div>
        <span style={{ color: '#8696A0', fontSize: '14px' }}>gravando...</span>
        <motion.div
          style={{ display: 'flex', gap: '2px' }}
        >
          {[0, 1, 2].map((i) => (
            <motion.div
              key={i}
              style={{
                width: '4px',
                height: '4px',
                backgroundColor: '#8696A0',
                borderRadius: '50%'
              }}
              animate={{ opacity: [0.3, 1, 0.3] }}
              transition={{ duration: 1, repeat: Infinity, delay: i * 0.2 }}
            />
          ))}
        </motion.div>
      </div>
    </motion.div>
  )
}

// Indicador de digitando
function TypingIndicator() {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      style={{
        display: 'flex',
        justifyContent: 'flex-start',
        marginBottom: '4px'
      }}
    >
      <div style={{
        backgroundColor: '#202C33',
        borderRadius: '8px',
        padding: '12px 16px',
        display: 'flex',
        alignItems: 'center',
        gap: '4px'
      }}>
        {[0, 1, 2].map((i) => (
          <motion.div
            key={i}
            style={{
              width: '8px',
              height: '8px',
              backgroundColor: '#8696A0',
              borderRadius: '50%'
            }}
            animate={{ y: [0, -5, 0] }}
            transition={{ duration: 0.6, repeat: Infinity, delay: i * 0.15 }}
          />
        ))}
      </div>
    </motion.div>
  )
}

export default function Chat() {
  const [, setLocation] = useLocation()
  const [messages, setMessages] = useState<Message[]>([])
  const [currentlyPlaying, setCurrentlyPlaying] = useState<string | null>(null)
  const [playProgress, setPlayProgress] = useState<{ [key: string]: number }>({})
  const [isRecording, setIsRecording] = useState(false)
  const [isTyping, setIsTyping] = useState(false)
  const [chatPhase, setChatPhase] = useState(0)
  const audioRefs = useRef<{ [key: string]: HTMLAudioElement }>({})
  const messagesEndRef = useRef<HTMLDivElement>(null)

  const voiceMessages = [
    { id: 'voice1', audioUrl: '/assets/audios/audio whats 1.m4a', duration: '0:07' },
    { id: 'voice2', audioUrl: '/assets/audios/audio whats 2.mp3', duration: '0:30' },
    { id: 'voice3', audioUrl: '/assets/audios/audio whats 3.mp3', duration: '0:15' }
  ]

  const textMessages = [
    "O Neo gravou uns vídeos explicando tudo.",
    "Menos de 2 minutos",
    "Entra no feed secreto e assiste.",
    "aqui o link:"
  ]

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth', block: 'end' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages, isRecording, isTyping])

  // Função para enviar mensagens de texto uma por uma
  const sendTextMessages = (index: number = 0) => {
    if (index >= textMessages.length) {
      setIsTyping(false)
      return
    }

    setIsTyping(true)

    // Tempo de digitação proporcional ao tamanho da mensagem (mínimo 1s, máximo 2s)
    const typingTime = Math.min(2000, Math.max(1000, textMessages[index].length * 50))

    setTimeout(() => {
      setIsTyping(false)

      const newMessage: TextMessage = {
        id: `text-${index}`,
        type: 'text',
        content: textMessages[index],
        time: getCurrentTime(),
        isLink: index === textMessages.length - 1 // última mensagem tem o link
      }

      setMessages(prev => [...prev, newMessage])

      // Envia próxima mensagem após um pequeno delay
      if (index < textMessages.length - 1) {
        setTimeout(() => {
          sendTextMessages(index + 1)
        }, 500)
      }
    }, typingTime)
  }

  // Inicializa - primeira mensagem já está lá + já começa gravando o próximo
  useEffect(() => {
    const firstMessage: VoiceMessage = {
      id: 'voice1',
      type: 'voice',
      audioUrl: voiceMessages[0].audioUrl,
      duration: voiceMessages[0].duration,
      time: getCurrentTime(),
      isPlayed: false
    }
    setMessages([firstMessage])

    // Já mostra que está gravando o próximo áudio
    setIsRecording(true)

    // Após 13 segundos, para de gravar e envia o áudio 2
    const timer1 = setTimeout(() => {
      setIsRecording(false)
      const secondMessage: VoiceMessage = {
        id: 'voice2',
        type: 'voice',
        audioUrl: voiceMessages[1].audioUrl,
        duration: voiceMessages[1].duration,
        time: getCurrentTime(),
        isPlayed: false
      }
      setMessages(prev => [...prev, secondMessage])
      setChatPhase(1)

      // Após 1 segundo, começa a gravar o áudio 3
      setTimeout(() => {
        setIsRecording(true)

        // Após 15 segundos, para de gravar e envia o áudio 3
        setTimeout(() => {
          setIsRecording(false)
          const thirdMessage: VoiceMessage = {
            id: 'voice3',
            type: 'voice',
            audioUrl: voiceMessages[2].audioUrl,
            duration: voiceMessages[2].duration,
            time: getCurrentTime(),
            isPlayed: false
          }
          setMessages(prev => [...prev, thirdMessage])
          setChatPhase(2)

          // Após 3 segundos, começa a enviar as mensagens de texto
          setTimeout(() => {
            sendTextMessages(0)
          }, 3000)
        }, 15000)
      }, 1000)
    }, 13000)

    // Pré-carrega os áudios
    voiceMessages.forEach(vm => {
      const audio = new Audio(vm.audioUrl)
      audio.preload = 'auto'
      audioRefs.current[vm.id] = audio
    })

    return () => {
      clearTimeout(timer1)
      // Cleanup
      Object.values(audioRefs.current).forEach(audio => {
        audio.pause()
        audio.src = ''
      })
    }
  }, [])

  // Controla o fluxo após cada áudio terminar de tocar
  const handleAudioEnded = (messageId: string) => {
    setCurrentlyPlaying(null)
    setPlayProgress(prev => ({ ...prev, [messageId]: 100 }))

    // Marca como tocado
    setMessages(prev => prev.map(m =>
      m.type === 'voice' && m.id === messageId ? { ...m, isPlayed: true } : m
    ))
  }

  const handlePlayPause = (messageId: string) => {
    const audio = audioRefs.current[messageId]
    if (!audio) return

    if (currentlyPlaying === messageId) {
      // Pausar
      audio.pause()
      setCurrentlyPlaying(null)
    } else {
      // Pausar qualquer outro que esteja tocando
      if (currentlyPlaying && audioRefs.current[currentlyPlaying]) {
        audioRefs.current[currentlyPlaying].pause()
      }

      // Tocar este
      audio.currentTime = 0
      setPlayProgress(prev => ({ ...prev, [messageId]: 0 }))

      audio.onended = () => handleAudioEnded(messageId)
      audio.ontimeupdate = () => {
        const progress = (audio.currentTime / audio.duration) * 100
        setPlayProgress(prev => ({ ...prev, [messageId]: progress }))
      }

      audio.play().catch(err => console.log('Audio play error:', err))
      setCurrentlyPlaying(messageId)
    }
  }

  const handleLinkClick = () => {
    setLocation('/tiktok')
  }

  return (
    <div className="h-screen flex flex-col overflow-hidden" style={{ backgroundColor: '#0B141A' }}>
      {/* Header - WhatsApp style */}
      <div style={{
        backgroundColor: '#1F2C34',
        padding: '8px 16px',
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        flexShrink: 0,
        position: 'sticky',
        top: 0,
        zIndex: 10
      }}>
        <ArrowLeft className="w-6 h-6" style={{ color: '#8696A0' }} />

        {/* Avatar */}
        <div style={{
          width: '40px',
          height: '40px',
          borderRadius: '50%',
          backgroundColor: '#6B7B8A',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          overflow: 'hidden'
        }}>
          <img
            src="/assets/images/proofs/Echo.png"
            alt="ECHO"
            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
          />
        </div>

        {/* Name and status */}
        <div style={{ flex: 1 }}>
          <h2 style={{
            color: '#E9EDEF',
            fontSize: '16px',
            fontWeight: 500,
            margin: 0
          }}>
            ECHO
          </h2>
          <p style={{
            color: '#8696A0',
            fontSize: '13px',
            margin: 0
          }}>
            online
          </p>
        </div>

        {/* Action icons */}
        <Video className="w-5 h-5" style={{ color: '#8696A0' }} />
        <Phone className="w-5 h-5" style={{ color: '#8696A0', marginLeft: '16px' }} />
        <MoreVertical className="w-5 h-5" style={{ color: '#8696A0', marginLeft: '16px' }} />
      </div>

      {/* Chat area with WhatsApp background pattern */}
      <div
        style={{
          flex: 1,
          overflowY: 'auto',
          backgroundColor: '#0B141A',
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23182229' fill-opacity='0.6'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
          padding: '8px 16px'
        }}
      >
        {/* Date chip */}
        <div style={{
          display: 'flex',
          justifyContent: 'center',
          marginBottom: '8px'
        }}>
          <span style={{
            backgroundColor: '#182229',
            color: '#8696A0',
            fontSize: '12px',
            padding: '6px 12px',
            borderRadius: '8px'
          }}>
            HOJE
          </span>
        </div>

        <AnimatePresence>
          {messages.map((msg) => (
            msg.type === 'voice' ? (
              <VoiceMessageBubble
                key={msg.id}
                message={msg}
                onPlay={() => handlePlayPause(msg.id)}
                isPlaying={currentlyPlaying === msg.id}
                progress={playProgress[msg.id] || 0}
              />
            ) : (
              <TextMessageBubble
                key={msg.id}
                message={msg}
                onLinkClick={handleLinkClick}
              />
            )
          ))}

          {isRecording && <RecordingIndicator key="recording" />}
          {isTyping && <TypingIndicator key="typing" />}
        </AnimatePresence>

        <div ref={messagesEndRef} />
      </div>

      {/* Input area */}
      <div style={{
        backgroundColor: '#1F2C34',
        padding: '8px 16px',
        minHeight: '62px',
        flexShrink: 0
      }}>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '8px'
        }}>
          <div style={{
            flex: 1,
            backgroundColor: '#2A3942',
            borderRadius: '24px',
            padding: '10px 16px',
            display: 'flex',
            alignItems: 'center'
          }}>
            <span style={{ color: '#8696A0', fontSize: '14px' }}>Mensagem</span>
          </div>
          <div style={{
            width: '48px',
            height: '48px',
            borderRadius: '50%',
            backgroundColor: '#00A884',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <Mic className="w-6 h-6 text-white" />
          </div>
        </div>
      </div>
    </div>
  )
}
