import { useEffect, useState, useRef } from 'react'
import { useLocation } from 'wouter'
import { motion, AnimatePresence } from 'framer-motion'
import { ArrowLeft, Phone, MoreVertical } from 'lucide-react'

// Tipos
interface Message {
  id: string
  sender: 'ana' | 'mina' | 'user'
  content: string
  type: 'text' | 'image' | 'suggestion'
}

// Script do chat
const chatFlow = [
  // Abertura
  { id: '1', sender: 'ana', content: 'Você atendeu. Isso já diz algo sobre você.', delay: 1000 },
  { id: '2', sender: 'ana', content: 'Agora eu preciso entender uma coisa.', delay: 2000 },
  { id: '3', sender: 'ana', content: 'Por que você quer isso?', delay: 1500, waitForResponse: true, options: ['Cansei de tomar vacuo', 'Quero parar de travar', 'Quero mais resultados'] },
  { id: '4', sender: 'ana', content: 'Entendi.', delay: 1000 },
  { id: '5', sender: 'ana', content: 'Vou te mostrar o que o Code criou. Mas não vou só FALAR. Vou te fazer SENTIR.', delay: 2000 },
  { id: '6', sender: 'ana', content: 'Faz o seguinte. Imagina que eu sou uma mina que você acabou de dar match. Vou te mandar uma mensagem como ela mandaria.', delay: 3000 },
  { id: '7', sender: 'ana', content: 'Preparado?', delay: 1500, waitForResponse: true, options: ['BORA'] },

  // Simulação
  { id: '8', type: 'transition', persona: 'mina' },
  { id: '9', sender: 'mina', content: 'oi', delay: 2000, waitForResponse: true, options: ['Oi, tudo bem?', 'E aí, beleza?'] },
  { id: '10', sender: 'mina', content: 'bem e vc', delay: 2500, waitForResponse: true, options: ['Também, de boa', 'Tranquilo'] },
  { id: '11', sender: 'mina', content: 'legal', delay: 2000 },
  { id: '12', type: 'silence', delay: 4000 },

  // Análise
  { id: '13', type: 'transition', persona: 'ana' },
  { id: '14', sender: 'ana', content: 'Morreu né?', delay: 1500 },
  { id: '15', sender: 'ana', content: 'Essa é a realidade de 90% dos caras. A conversa simplesmente... morre.', delay: 2500 },
  { id: '16', sender: 'ana', content: 'Agora olha o que o sistema do Code sugeriria nesse momento exato:', delay: 2000 },
  { id: '17', type: 'suggestion', content: 'Legal é fichinha. Me conta algo sobre você que eu não ia adivinhar nem em 10 tentativas', delay: 1000 },
  { id: '18', sender: 'ana', content: 'Percebe? Não é forçado. Não é cantada brega. É só... a coisa certa na hora certa.', delay: 3000 },
  { id: '19', sender: 'ana', content: 'Quer ver o que acontece quando você usa isso consistentemente?', delay: 2000, waitForResponse: true, options: ['MOSTRA'] },

  // Prova social
  { id: '20', sender: 'ana', content: 'Olha esses resultados reais:', delay: 1500 },
  { id: '21', type: 'image', content: '/assets/images/proofs/print_conversa_01.png', delay: 2000 },
  { id: '22', type: 'image', content: '/assets/images/proofs/print_conversa_02.png', delay: 2000 },
  { id: '23', sender: 'ana', content: 'Isso é o que acontece quando você para de adivinhar e começa a SABER o que funciona.', delay: 2500 },

  // Revelação
  { id: '24', sender: 'ana', content: 'Agora a parte que o Code não queria que eu contasse...', delay: 3000 },
  { id: '25', sender: 'ana', content: 'Tudo que eu te mandei até agora...', delay: 2000 },
  { id: '26', sender: 'ana', content: 'O tom. As respostas. O timing.', delay: 1500 },
  { id: '27', sender: 'ana', content: 'Foi o sistema dele me guiando.', delay: 2000 },
  { id: '28', sender: 'ana', content: 'Você acabou de conversar com a ferramenta sem perceber.', delay: 2500 },
  { id: '29', sender: 'ana', content: 'E funcionou, não funcionou?', delay: 2000 },
  { id: '30', sender: 'ana', content: 'Você respondeu. Você engajou. Você ficou até aqui.', delay: 2000 },
  { id: '31', sender: 'ana', content: 'Imagina ter isso em TODA conversa. Todo match. Toda oportunidade.', delay: 2500 },
  { id: '32', sender: 'ana', content: 'O Code me autorizou a liberar o acesso pra quem chegasse até aqui.', delay: 2500 },
  { id: '33', sender: 'ana', content: 'Você chegou. 🔓', delay: 1500, waitForResponse: true, options: ['QUERO MEU ACESSO'] },
]

export default function Chat() {
  const [, setLocation] = useLocation()
  const [messages, setMessages] = useState<Message[]>([])
  const [currentStep, setCurrentStep] = useState(0)
  const [isTyping, setIsTyping] = useState(false)
  const [waitingForResponse, setWaitingForResponse] = useState(false)
  const [currentOptions, setCurrentOptions] = useState<string[]>([])
  const [currentPersona, setCurrentPersona] = useState<'ana' | 'mina'>('ana')
  const messagesEndRef = useRef<HTMLDivElement>(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
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
      setCurrentPersona(step.persona as 'ana' | 'mina')
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
          sender: 'ana',
          content: step.content!,
          type: 'suggestion'
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
          sender: 'ana',
          content: step.content!,
          type: 'image'
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
          sender: step.sender as 'ana' | 'mina',
          content: step.content,
          type: 'text'
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
      type: 'text'
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
      return { name: 'Mina do Tinder 🔥', color: 'from-pink-500 to-rose-500' }
    }
    return { name: 'Ana', color: 'from-purple-500 to-pink-500' }
  }

  const persona = getPersonaInfo()

  return (
    <div className="min-h-screen bg-whatsapp-dark flex flex-col">
      {/* Header */}
      <div className="bg-whatsapp-green/90 px-4 py-3 flex items-center gap-3">
        <ArrowLeft className="w-6 h-6 text-white/80" />
        <div className={`w-10 h-10 rounded-full bg-gradient-to-br ${persona.color} flex items-center justify-center`}>
          <span className="text-white font-semibold">{persona.name[0]}</span>
        </div>
        <div className="flex-1">
          <h2 className="text-white font-medium">{persona.name}</h2>
          <p className="text-white/60 text-xs">online</p>
        </div>
        <Phone className="w-5 h-5 text-white/80" />
        <MoreVertical className="w-5 h-5 text-white/80" />
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-2">
        <AnimatePresence>
          {messages.map((msg) => (
            <motion.div
              key={msg.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              {msg.type === 'suggestion' ? (
                <div className="max-w-[85%] bg-gradient-to-r from-purple-600 to-pink-600 rounded-xl p-4">
                  <p className="text-xs text-white/70 mb-1">💡 SUGESTÃO DO DESENROLA AI</p>
                  <p className="text-white">{msg.content}</p>
                </div>
              ) : msg.type === 'image' ? (
                <div className="max-w-[70%] bg-whatsapp-bubble rounded-xl p-1">
                  <div className="bg-gray-700 rounded-lg h-48 flex items-center justify-center">
                    <span className="text-white/50 text-sm">📸 Print de conversa</span>
                  </div>
                </div>
              ) : (
                <div className={`max-w-[85%] rounded-xl px-3 py-2 ${
                  msg.sender === 'user'
                    ? 'bg-whatsapp-bubble text-white'
                    : 'bg-whatsapp-green/30 text-white'
                }`}>
                  <p>{msg.content}</p>
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
            className="flex justify-start"
          >
            <div className="bg-whatsapp-green/30 rounded-xl px-4 py-3">
              <div className="flex gap-1">
                <div className="w-2 h-2 bg-white/50 rounded-full typing-dot" />
                <div className="w-2 h-2 bg-white/50 rounded-full typing-dot" />
                <div className="w-2 h-2 bg-white/50 rounded-full typing-dot" />
              </div>
            </div>
          </motion.div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Options / Input */}
      {waitingForResponse && currentOptions.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="px-4 py-4 bg-whatsapp-dark border-t border-white/10"
        >
          <div className="flex flex-wrap gap-2">
            {currentOptions.map((option, index) => (
              <button
                key={index}
                onClick={() => handleOptionSelect(option)}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-all
                  ${option === 'QUERO MEU ACESSO' || option === 'BORA' || option === 'MOSTRA'
                    ? 'bg-gradient-to-r from-purple-600 to-pink-600 text-white'
                    : 'bg-white/10 text-white hover:bg-white/20'
                  }`}
              >
                {option}
              </button>
            ))}
          </div>
        </motion.div>
      )}
    </div>
  )
}
