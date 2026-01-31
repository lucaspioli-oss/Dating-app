import { useEffect, useState, useRef } from 'react'
import { useLocation } from 'wouter'
import { motion, AnimatePresence } from 'framer-motion'
import { ArrowLeft, Phone, Video, MoreVertical, Check, CheckCheck } from 'lucide-react'

// Tipos
interface Message {
  id: string
  sender: 'echo' | 'mina' | 'user'
  content: string
  type: 'text' | 'image' | 'suggestion'
  time: string
}

// Script do chat
const chatFlow = [
  // Abertura
  { id: '1', sender: 'echo', content: 'Você atendeu. Isso já diz algo sobre você.', delay: 1000 },
  { id: '2', sender: 'echo', content: 'Agora eu preciso entender uma coisa.', delay: 2000 },
  { id: '3', sender: 'echo', content: 'Por que você quer isso?', delay: 1500, waitForResponse: true, options: ['Cansei de tomar vacuo', 'Quero parar de travar', 'Quero mais resultados'] },
  { id: '4', sender: 'echo', content: 'Entendi.', delay: 1000 },
  { id: '5', sender: 'echo', content: 'Vou te mostrar o que o NEO criou. Mas não vou só FALAR. Vou te fazer SENTIR.', delay: 2000 },
  { id: '6', sender: 'echo', content: 'Faz o seguinte. Imagina que eu sou uma mina que você acabou de dar match. Vou te mandar uma mensagem como ela mandaria.', delay: 3000 },
  { id: '7', sender: 'echo', content: 'Preparado?', delay: 1500, waitForResponse: true, options: ['BORA'] },

  // Simulação
  { id: '8', type: 'transition', persona: 'mina' },
  { id: '9', sender: 'mina', content: 'oi', delay: 2000, waitForResponse: true, options: ['Oi, tudo bem?', 'E aí, beleza?'] },
  { id: '10', sender: 'mina', content: 'bem e vc', delay: 2500, waitForResponse: true, options: ['Também, de boa', 'Tranquilo'] },
  { id: '11', sender: 'mina', content: 'legal', delay: 2000 },
  { id: '12', type: 'silence', delay: 4000 },

  // Análise
  { id: '13', type: 'transition', persona: 'echo' },
  { id: '14', sender: 'echo', content: 'Morreu né?', delay: 1500 },
  { id: '15', sender: 'echo', content: 'Essa é a realidade de 90% dos caras. A conversa simplesmente... morre.', delay: 2500 },
  { id: '16', sender: 'echo', content: 'Agora olha o que o sistema do NEO sugeriria nesse momento exato:', delay: 2000 },
  { id: '17', type: 'suggestion', content: 'Legal é fichinha. Me conta algo sobre você que eu não ia adivinhar nem em 10 tentativas', delay: 1000 },
  { id: '18', sender: 'echo', content: 'Percebe? Não é forçado. Não é cantada brega. É só... a coisa certa na hora certa.', delay: 3000 },
  { id: '19', sender: 'echo', content: 'Quer ver o que acontece quando você usa isso consistentemente?', delay: 2000, waitForResponse: true, options: ['MOSTRA'] },

  // Prova social
  { id: '20', sender: 'echo', content: 'Olha esses resultados reais:', delay: 1500 },
  { id: '21', type: 'image', content: '/assets/images/proofs/print_conversa_01.png', delay: 2000 },
  { id: '22', type: 'image', content: '/assets/images/proofs/print_conversa_02.png', delay: 2000 },
  { id: '23', sender: 'echo', content: 'Isso é o que acontece quando você para de adivinhar e começa a SABER o que funciona.', delay: 2500 },

  // Revelação
  { id: '24', sender: 'echo', content: 'Agora a parte que o NEO não queria que eu contasse...', delay: 3000 },
  { id: '25', sender: 'echo', content: 'Tudo que eu te mandei até agora...', delay: 2000 },
  { id: '26', sender: 'echo', content: 'O tom. As respostas. O timing.', delay: 1500 },
  { id: '27', sender: 'echo', content: 'Foi o sistema dele me guiando.', delay: 2000 },
  { id: '28', sender: 'echo', content: 'Você acabou de conversar com a ferramenta sem perceber.', delay: 2500 },
  { id: '29', sender: 'echo', content: 'E funcionou, não funcionou?', delay: 2000 },
  { id: '30', sender: 'echo', content: 'Você respondeu. Você engajou. Você ficou até aqui.', delay: 2000 },
  { id: '31', sender: 'echo', content: 'Imagina ter isso em TODA conversa. Todo match. Toda oportunidade.', delay: 2500 },
  { id: '32', sender: 'echo', content: 'O NEO me autorizou a liberar o acesso pra quem chegasse até aqui.', delay: 2500 },
  { id: '33', sender: 'echo', content: 'Você chegou. 🔓', delay: 1500, waitForResponse: true, options: ['QUERO MEU ACESSO'] },
]

function getCurrentTime() {
  return new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}

export default function Chat() {
  const [, setLocation] = useLocation()
  const [messages, setMessages] = useState<Message[]>([])
  const [currentStep, setCurrentStep] = useState(0)
  const [isTyping, setIsTyping] = useState(false)
  const [waitingForResponse, setWaitingForResponse] = useState(false)
  const [currentOptions, setCurrentOptions] = useState<string[]>([])
  const [currentPersona, setCurrentPersona] = useState<'echo' | 'mina'>('echo')
  const messagesEndRef = useRef<HTMLDivElement>(null)

  const scrollToBottom = () => {
    if (messages.length > 0) {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
    }
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages, isTyping])

  // Processa o próximo passo do chat
  useEffect(() => {
    if (waitingForResponse || currentStep >= chatFlow.length) return

    const step = chatFlow[currentStep]

    // Transição de persona
    if (step.type === 'transition') {
      setCurrentPersona(step.persona as 'echo' | 'mina')
      setCurrentStep(prev => prev + 1)
      return
    }

    // Silêncio
    if (step.type === 'silence') {
      const timer = setTimeout(() => {
        setCurrentStep(prev => prev + 1)
      }, step.delay)
      return () => clearTimeout(timer)
    }

    // Sugestão da IA
    if (step.type === 'suggestion' && step.content) {
      const timer = setTimeout(() => {
        setMessages(prev => [...prev, {
          id: step.id,
          sender: 'echo',
          content: step.content!,
          type: 'suggestion',
          time: getCurrentTime()
        }])
        setCurrentStep(prev => prev + 1)
      }, step.delay)
      return () => clearTimeout(timer)
    }

    // Imagem
    if (step.type === 'image' && step.content) {
      const timer = setTimeout(() => {
        setMessages(prev => [...prev, {
          id: step.id,
          sender: 'echo',
          content: step.content!,
          type: 'image',
          time: getCurrentTime()
        }])
        setCurrentStep(prev => prev + 1)
      }, step.delay)
      return () => clearTimeout(timer)
    }

    // Mensagem normal
    if (step.sender) {
      setIsTyping(true)

      const typingTimer = setTimeout(() => {
        setIsTyping(false)
        setMessages(prev => [...prev, {
          id: step.id,
          sender: step.sender as 'echo' | 'mina',
          content: step.content,
          type: 'text',
          time: getCurrentTime()
        }])

        if (step.waitForResponse && step.options) {
          setWaitingForResponse(true)
          setCurrentOptions(step.options)
        } else {
          setCurrentStep(prev => prev + 1)
        }
      }, step.delay)

      return () => clearTimeout(typingTimer)
    }
  }, [currentStep, waitingForResponse])

  const handleOptionSelect = (option: string) => {
    // Adiciona resposta do usuário
    setMessages(prev => [...prev, {
      id: `user-${currentStep}`,
      sender: 'user',
      content: option,
      type: 'text',
      time: getCurrentTime()
    }])

    setWaitingForResponse(false)
    setCurrentOptions([])

    // Se for o botão final, vai pro checkout
    if (option === 'QUERO MEU ACESSO') {
      setTimeout(() => {
        setLocation('/game/checkout')
      }, 500)
      return
    }

    setCurrentStep(prev => prev + 1)
  }

  const getPersonaInfo = () => {
    if (currentPersona === 'mina') {
      return {
        name: 'Mina do Tinder',
        avatar: '🔥',
        status: 'online'
      }
    }
    return {
      name: 'ECHO',
      avatar: '/assets/images/proofs/Echo.png',
      status: 'online'
    }
  }

  const persona = getPersonaInfo()

  return (
    <div className="h-screen flex flex-col overflow-hidden" style={{ backgroundColor: '#0B141A' }}>
      {/* Header - WhatsApp style */}
      <div style={{
        backgroundColor: '#1F2C34',
        padding: '8px 16px',
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        flexShrink: 0
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
          {currentPersona === 'echo' ? (
            <img
              src="/assets/images/proofs/Echo.png"
              alt="ECHO"
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            />
          ) : (
            <span style={{ fontSize: '20px' }}>🔥</span>
          )}
        </div>

        {/* Name and status */}
        <div style={{ flex: 1 }}>
          <h2 style={{
            color: '#E9EDEF',
            fontSize: '16px',
            fontWeight: 500,
            margin: 0
          }}>
            {persona.name}
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
            <motion.div
              key={msg.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              style={{
                display: 'flex',
                justifyContent: msg.sender === 'user' ? 'flex-end' : 'flex-start',
                marginBottom: '4px'
              }}
            >
              {msg.type === 'suggestion' ? (
                <div style={{
                  maxWidth: '85%',
                  background: 'linear-gradient(135deg, #7C3AED 0%, #DB2777 100%)',
                  borderRadius: '8px',
                  padding: '8px 12px',
                  position: 'relative'
                }}>
                  <p style={{
                    fontSize: '11px',
                    color: 'rgba(255,255,255,0.7)',
                    marginBottom: '4px',
                    fontWeight: 500
                  }}>
                    💡 SUGESTÃO DO DESENROLA AI
                  </p>
                  <p style={{ color: 'white', fontSize: '14px', margin: 0 }}>{msg.content}</p>
                  <span style={{
                    fontSize: '11px',
                    color: 'rgba(255,255,255,0.6)',
                    float: 'right',
                    marginTop: '4px'
                  }}>
                    {msg.time}
                  </span>
                </div>
              ) : msg.type === 'image' ? (
                <div style={{
                  maxWidth: '70%',
                  backgroundColor: msg.sender === 'user' ? '#005C4B' : '#202C33',
                  borderRadius: '8px',
                  padding: '4px',
                  position: 'relative'
                }}>
                  <div style={{
                    backgroundColor: '#1A1A1A',
                    borderRadius: '6px',
                    height: '200px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <span style={{ color: '#8696A0', fontSize: '14px' }}>📸 Print de conversa</span>
                  </div>
                  <span style={{
                    fontSize: '11px',
                    color: 'rgba(255,255,255,0.6)',
                    float: 'right',
                    marginTop: '4px',
                    marginRight: '4px'
                  }}>
                    {msg.time}
                  </span>
                </div>
              ) : (
                <div style={{
                  maxWidth: '85%',
                  backgroundColor: msg.sender === 'user' ? '#005C4B' : '#202C33',
                  borderRadius: '8px',
                  padding: '6px 12px 8px 12px',
                  position: 'relative'
                }}>
                  <p style={{
                    color: '#E9EDEF',
                    fontSize: '14px',
                    margin: 0,
                    paddingRight: msg.sender === 'user' ? '50px' : '35px'
                  }}>
                    {msg.content}
                  </p>
                  <span style={{
                    position: 'absolute',
                    bottom: '6px',
                    right: '8px',
                    fontSize: '11px',
                    color: 'rgba(255,255,255,0.5)',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '2px'
                  }}>
                    {msg.time}
                    {msg.sender === 'user' && (
                      <CheckCheck className="w-4 h-4" style={{ color: '#53BDEB', marginLeft: '2px' }} />
                    )}
                  </span>
                </div>
              )}
            </motion.div>
          ))}
        </AnimatePresence>

        {/* Typing indicator */}
        {isTyping && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            style={{
              display: 'flex',
              justifyContent: 'flex-start',
              marginBottom: '4px'
            }}
          >
            <div style={{
              backgroundColor: '#202C33',
              borderRadius: '8px',
              padding: '12px 16px'
            }}>
              <div style={{ display: 'flex', gap: '4px' }}>
                <div className="typing-dot" style={{
                  width: '8px',
                  height: '8px',
                  backgroundColor: '#8696A0',
                  borderRadius: '50%',
                  animation: 'typing 1.4s infinite',
                  animationDelay: '0ms'
                }} />
                <div className="typing-dot" style={{
                  width: '8px',
                  height: '8px',
                  backgroundColor: '#8696A0',
                  borderRadius: '50%',
                  animation: 'typing 1.4s infinite',
                  animationDelay: '200ms'
                }} />
                <div className="typing-dot" style={{
                  width: '8px',
                  height: '8px',
                  backgroundColor: '#8696A0',
                  borderRadius: '50%',
                  animation: 'typing 1.4s infinite',
                  animationDelay: '400ms'
                }} />
              </div>
            </div>
          </motion.div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input area / Options */}
      <div style={{
        backgroundColor: '#1F2C34',
        padding: '8px 16px',
        minHeight: '62px',
        flexShrink: 0
      }}>
        {waitingForResponse && currentOptions.length > 0 ? (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: '8px',
              justifyContent: 'center'
            }}
          >
            {currentOptions.map((option, index) => (
              <button
                key={index}
                onClick={() => handleOptionSelect(option)}
                style={{
                  padding: '10px 20px',
                  borderRadius: '20px',
                  fontSize: '14px',
                  fontWeight: 500,
                  border: 'none',
                  cursor: 'pointer',
                  transition: 'all 0.2s',
                  background: option === 'QUERO MEU ACESSO' || option === 'BORA' || option === 'MOSTRA'
                    ? 'linear-gradient(135deg, #7C3AED 0%, #DB2777 100%)'
                    : '#2A3942',
                  color: '#E9EDEF'
                }}
              >
                {option}
              </button>
            ))}
          </motion.div>
        ) : (
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
              <svg width="24" height="24" viewBox="0 0 24 24" fill="white">
                <path d="M12 15c1.66 0 3-1.34 3-3V6c0-1.66-1.34-3-3-3S9 4.34 9 6v6c0 1.66 1.34 3 3 3zm-1-9c0-.55.45-1 1-1s1 .45 1 1v6c0 .55-.45 1-1 1s-1-.45-1-1V6z"/>
                <path d="M17 11c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z"/>
              </svg>
            </div>
          </div>
        )}
      </div>

      <style>{`
        @keyframes typing {
          0%, 60%, 100% {
            transform: translateY(0);
            opacity: 0.5;
          }
          30% {
            transform: translateY(-4px);
            opacity: 1;
          }
        }
      `}</style>
    </div>
  )
}
