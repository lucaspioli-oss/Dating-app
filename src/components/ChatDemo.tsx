import { useState, useRef, useEffect } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Sparkles, Send, Trophy } from "lucide-react"

// Conversa real baseada no testemunho
const conversationFlow = [
  {
    incoming: ["me ajuda escolher um vestido?"],
    suggestion: "Eu ajudo sim, mas só se couber 2 no vestiário 😏",
  },
  {
    incoming: ["ai vc ja ve se é facil de tirar", "tem q ser um facil ne"],
    suggestion: "Eu tiro a maioria com facilidade. Tenho habilidades ocultas 😎",
  },
  {
    incoming: ["vish", "sera?"],
    suggestion: "Também fiquei na dúvida, acho que teria que testar né? 😉",
  },
  {
    incoming: ["tbm acho", "vamos"],
    suggestion: null, // Final - vitória!
  },
]

type GameState = "waiting_click" | "scanning" | "showing_suggestion" | "victory"
type IntroState = "waiting_scroll" | "notification" | "opening" | "ready"

// Som de notificação - igual ao Quiz
const playNotificationSound = () => {
  const audio = new Audio("https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3")
  audio.volume = 1
  audio.play().catch(() => {})
}

interface ChatDemoProps {
  onResponseGenerated?: (count: number) => void
}

export default function ChatDemo({ onResponseGenerated }: ChatDemoProps) {
  const [introState, setIntroState] = useState<IntroState>("waiting_scroll")
  const [showNotification, setShowNotification] = useState(false)
  const [currentRound, setCurrentRound] = useState(0)
  const [chatMessages, setChatMessages] = useState<{ type: "in" | "out"; text: string }[]>([])
  const [gameState, setGameState] = useState<GameState>("waiting_click")
  const [hasStarted, setHasStarted] = useState(false)
  const [scanProgress, setScanProgress] = useState(0)
  const chatRef = useRef<HTMLDivElement>(null)
  const phoneRef = useRef<HTMLDivElement>(null)
  const hasTriggeredRef = useRef(false)

  const currentFlow = conversationFlow[currentRound]

  // Detectar quando o mockup entra na tela
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !hasTriggeredRef.current) {
            hasTriggeredRef.current = true
            setIntroState("notification")

            // Delay de 1 segundo antes de mostrar notificação
            setTimeout(() => {
              setShowNotification(true)
            }, 1000)
          }
        })
      },
      { threshold: 0.4 }
    )

    if (phoneRef.current) {
      observer.observe(phoneRef.current)
    }

    return () => observer.disconnect()
  }, [])

  // Auto-scroll quando novas mensagens são adicionadas
  useEffect(() => {
    if (chatRef.current) {
      chatRef.current.scrollTo({
        top: chatRef.current.scrollHeight,
        behavior: 'smooth'
      })
    }
  }, [chatMessages.length])

  const handleNotificationClick = () => {
    // Tocar som ao clicar (funciona pois é interação do usuário)
    playNotificationSound()
    setIntroState("opening")
    // Transição para o jogo
    setTimeout(() => {
      setIntroState("ready")
    }, 600)
  }

  const handleGenerateClick = () => {
    if (gameState !== "waiting_click") return

    // Adiciona mensagens da Larissa se ainda não foram adicionadas
    if (!hasStarted || chatMessages.length === 0 || chatMessages[chatMessages.length - 1].type === "out") {
      currentFlow.incoming.forEach((msg, i) => {
        setTimeout(() => {
          setChatMessages(prev => [...prev, { type: "in", text: msg }])
        }, i * 300)
      })
    }

    // Inicia o escaneamento após as mensagens aparecerem
    setTimeout(() => {
      setGameState("scanning")
      setScanProgress(0)

      // Animação do scanner
      const scanInterval = setInterval(() => {
        setScanProgress(prev => {
          if (prev >= 100) {
            clearInterval(scanInterval)
            // Verifica se é o round final
            if (!currentFlow.suggestion) {
              setGameState("victory")
            } else {
              setGameState("showing_suggestion")
            }
            return 100
          }
          return prev + 4
        })
      }, 50)
    }, currentFlow.incoming.length * 300 + 200)

    setHasStarted(true)
  }

  const handleSendSuggestion = () => {
    if (gameState !== "showing_suggestion" || !currentFlow.suggestion) return

    // Envia a mensagem
    setChatMessages(prev => [...prev, { type: "out", text: currentFlow.suggestion! }])

    // Próximo round
    const nextRound = currentRound + 1
    setCurrentRound(nextRound)
    setGameState("waiting_click")

    // Notifica o parent que uma resposta foi gerada
    onResponseGenerated?.(nextRound)

    // Auto-adiciona próximas mensagens da Larissa após um delay
    if (nextRound < conversationFlow.length) {
      setTimeout(() => {
        conversationFlow[nextRound].incoming.forEach((msg, i) => {
          setTimeout(() => {
            setChatMessages(prev => [...prev, { type: "in", text: msg }])
          }, i * 400)
        })
      }, 800)
    }
  }

  const handleRestart = () => {
    setCurrentRound(0)
    setChatMessages([])
    setGameState("waiting_click")
    setHasStarted(false)
    setScanProgress(0)
  }

  // Agrupa mensagens consecutivas do mesmo tipo para mostrar avatar apenas na primeira
  const shouldShowAvatar = (index: number) => {
    if (chatMessages[index].type !== "in") return false
    if (index === 0) return true
    return chatMessages[index - 1].type !== "in"
  }

  // ========== TELA DE NOTIFICAÇÃO - iPhone Mockup Realista ==========
  if (introState === "waiting_scroll" || introState === "notification" || introState === "opening") {
    return (
      <div className="flex justify-center" ref={phoneRef}>
        <motion.div
          className="relative"
          style={{ width: 220, height: 450 }}
          animate={introState === "opening" ? { scale: [1, 1.02, 0.95], opacity: [1, 1, 0] } : {}}
          transition={{ duration: 0.4 }}
        >
          {/* iPhone 15 Pro Frame */}
          <div
            className="absolute inset-0 rounded-[42px]"
            style={{
              background: 'linear-gradient(145deg, #1f1f1f 0%, #0a0a0a 100%)',
              boxShadow: `
                0 0 0 1px #333,
                0 0 0 3px #1a1a1a,
                0 20px 50px -10px rgba(0,0,0,0.7),
                inset 0 1px 1px rgba(255,255,255,0.05)
              `,
            }}
          >
            {/* Screen bezel */}
            <div
              className="absolute rounded-[38px] overflow-hidden"
              style={{
                top: 3,
                left: 3,
                right: 3,
                bottom: 3,
                background: '#000',
              }}
            >
              {/* Dynamic Island */}
              <div
                className="absolute left-1/2 -translate-x-1/2 z-30"
                style={{
                  top: 8,
                  width: 85,
                  height: 24,
                  background: '#000',
                  borderRadius: 14,
                }}
              >
                {/* Camera dot */}
                <div
                  className="absolute right-3 top-1/2 -translate-y-1/2"
                  style={{
                    width: 8,
                    height: 8,
                    background: 'radial-gradient(circle at 30% 30%, #1a1a3a, #000)',
                    borderRadius: '50%',
                  }}
                />
              </div>

              {/* Screen Content */}
              <div className="absolute inset-0">
                {/* iOS Wallpaper */}
                <div
                  className="absolute inset-0"
                  style={{
                    background: `
                      radial-gradient(ellipse at 50% 0%, rgba(120,50,180,0.4) 0%, transparent 50%),
                      radial-gradient(ellipse at 20% 100%, rgba(60,20,100,0.3) 0%, transparent 40%),
                      radial-gradient(ellipse at 80% 80%, rgba(100,40,150,0.2) 0%, transparent 40%),
                      linear-gradient(180deg, #1a0a25 0%, #0a0510 40%, #050208 100%)
                    `,
                  }}
                />

                {/* Status Bar */}
                <div className="absolute top-0 left-0 right-0 z-20 flex justify-between items-center" style={{ padding: '10px 20px 0 20px' }}>
                  <span
                    className="text-white font-semibold"
                    style={{ fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif', fontSize: 12 }}
                  >
                    9:41
                  </span>
                  <div className="flex items-center gap-1">
                    {/* Cellular */}
                    <svg width="14" height="10" viewBox="0 0 17 10" fill="white">
                      <rect x="0" y="5" width="3" height="5" rx="0.5" fillOpacity="0.3"/>
                      <rect x="4" y="3.5" width="3" height="6.5" rx="0.5" fillOpacity="0.5"/>
                      <rect x="8" y="2" width="3" height="8" rx="0.5" fillOpacity="1"/>
                      <rect x="12" y="0" width="3" height="10" rx="0.5" fillOpacity="1"/>
                    </svg>
                    {/* WiFi */}
                    <svg width="13" height="10" viewBox="0 0 15 10" fill="white">
                      <path d="M7.5 8a1.2 1.2 0 110 2.4 1.2 1.2 0 010-2.4z"/>
                      <path d="M5 6.5c1.4-1.2 3.6-1.2 5 0" stroke="white" strokeWidth="1.2" fill="none" strokeLinecap="round"/>
                      <path d="M2.5 4c2.5-2 7.5-2 10 0" stroke="white" strokeWidth="1.2" fill="none" strokeLinecap="round"/>
                    </svg>
                    {/* Battery */}
                    <div className="flex items-center">
                      <div
                        className="relative"
                        style={{
                          width: 20,
                          height: 9,
                          border: '1px solid rgba(255,255,255,0.4)',
                          borderRadius: 2,
                        }}
                      >
                        <div
                          className="absolute bg-white rounded-sm"
                          style={{ top: 1, left: 1, bottom: 1, width: '75%' }}
                        />
                      </div>
                      <div
                        className="bg-white/40"
                        style={{
                          width: 1,
                          height: 4,
                          borderRadius: '0 1px 1px 0',
                          marginLeft: 0.5,
                        }}
                      />
                    </div>
                  </div>
                </div>

                {/* Lock Screen */}
                <div className="absolute inset-0 flex flex-col items-center" style={{ paddingTop: 50 }}>
                  {/* Lock icon */}
                  <svg
                    className="text-white/60 mb-1"
                    style={{ width: 16, height: 16 }}
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={1.5}
                      d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                    />
                  </svg>

                  {/* Time */}
                  <p
                    className="text-white font-light tracking-tight"
                    style={{
                      fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
                      fontSize: 54,
                      lineHeight: 1,
                    }}
                  >
                    9:41
                  </p>

                  {/* Date */}
                  <p
                    className="text-white/60"
                    style={{
                      fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
                      fontSize: 13,
                      marginTop: 2,
                    }}
                  >
                    sexta-feira, 17 de janeiro
                  </p>
                </div>

                {/* Notification - slides UP to upper-middle area */}
                <AnimatePresence>
                  {showNotification && introState === "notification" && (
                    <motion.div
                      initial={{ y: -80, opacity: 0 }}
                      animate={{ y: 0, opacity: 1 }}
                      exit={{ y: -80, opacity: 0 }}
                      transition={{
                        type: "spring",
                        damping: 25,
                        stiffness: 500,
                      }}
                      onClick={handleNotificationClick}
                      className="absolute left-2 right-2 cursor-pointer z-30"
                      style={{ top: 160 }}
                    >
                      <motion.div
                        className="rounded-2xl flex items-center gap-3 px-4 py-3"
                        style={{
                          background: 'rgba(40, 40, 44, 0.95)',
                          backdropFilter: 'blur(50px)',
                          WebkitBackdropFilter: 'blur(50px)',
                        }}
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        {/* Profile photo */}
                        <img
                          src="/perfil_larissa.jpg"
                          alt="Larissa"
                          className="rounded-full object-cover flex-shrink-0"
                          style={{ width: 44, height: 44 }}
                        />

                        {/* Text content */}
                        <p
                          className="text-white font-medium"
                          style={{ fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif', fontSize: 14 }}
                        >
                          Larissa enviou uma nova mensagem
                        </p>
                      </motion.div>

                      {/* Animated hand cursor pointing at notification */}
                      <motion.div
                        initial={{ x: 60, opacity: 0 }}
                        animate={{ x: 0, opacity: 1 }}
                        transition={{
                          duration: 0.4,
                          delay: 0.3,
                        }}
                        className="absolute flex items-center"
                        style={{ right: -10, top: 12 }}
                      >
                        <motion.img
                          src="/cursor1.png"
                          alt="Clique aqui"
                          style={{
                            width: 55,
                            height: 55,
                          }}
                          animate={{
                            scale: [1, 0.85, 1],
                          }}
                          transition={{
                            duration: 0.6,
                            repeat: Infinity,
                            repeatDelay: 0.8,
                            ease: "easeInOut",
                          }}
                        />
                      </motion.div>

                      {/* Tap instruction */}
                      <motion.p
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ delay: 1 }}
                        className="text-center text-white/40 mt-3"
                        style={{ fontFamily: '-apple-system, sans-serif', fontSize: 11 }}
                      >
                        👆 Toque para abrir
                      </motion.p>
                    </motion.div>
                  )}
                </AnimatePresence>

                {/* Bottom shortcuts */}
                <div className="absolute bottom-6 left-0 right-0 flex justify-between px-8">
                  <div
                    className="flex items-center justify-center"
                    style={{
                      width: 40,
                      height: 40,
                      borderRadius: 20,
                      background: 'rgba(255,255,255,0.08)',
                      backdropFilter: 'blur(20px)',
                    }}
                  >
                    <svg style={{ width: 20, height: 20 }} className="text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                    </svg>
                  </div>
                  <div
                    className="flex items-center justify-center"
                    style={{
                      width: 40,
                      height: 40,
                      borderRadius: 20,
                      background: 'rgba(255,255,255,0.08)',
                      backdropFilter: 'blur(20px)',
                    }}
                  >
                    <svg style={{ width: 20, height: 20 }} className="text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                      <circle cx="12" cy="13" r="3" />
                    </svg>
                  </div>
                </div>

                {/* Home Indicator */}
                <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2">
                  <div
                    className="rounded-full bg-white/60"
                    style={{ width: 100, height: 4 }}
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Physical Buttons - left side */}
          <div
            className="absolute bg-[#2a2a2a] rounded-l-sm"
            style={{ left: -2, top: 75, width: 2, height: 22 }}
          />
          <div
            className="absolute bg-[#2a2a2a] rounded-l-sm"
            style={{ left: -2, top: 110, width: 2, height: 40 }}
          />
          <div
            className="absolute bg-[#2a2a2a] rounded-l-sm"
            style={{ left: -2, top: 160, width: 2, height: 40 }}
          />
          {/* Power button - right side */}
          <div
            className="absolute bg-[#2a2a2a] rounded-r-sm"
            style={{ right: -2, top: 125, width: 2, height: 50 }}
          />
        </motion.div>

      </div>
    )
  }

  // ========== JOGO PRINCIPAL ==========
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      className="rounded-2xl overflow-hidden relative"
      style={{
        background: '#FFFFFF',
        border: '1px solid rgba(0, 0, 0, 0.1)',
        boxShadow: '0 4px 24px rgba(0, 0, 0, 0.12)',
      }}
    >
      {/* Header - Instagram Style */}
      <div
        className="flex items-center gap-3 px-4 py-3"
        style={{
          background: '#FFFFFF',
          borderBottom: '1px solid rgba(0, 0, 0, 0.1)'
        }}
      >
        <button className="text-gray-800">
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>

        {/* Avatar com foto real */}
        <img
          src="/perfil_larissa.jpg"
          alt="Larissa"
          className="w-9 h-9 rounded-full object-cover"
        />

        <div className="flex-1">
          <div className="flex items-center gap-1">
            <p className="font-semibold text-sm text-gray-900 leading-tight">Larissa</p>
            <span
              className="text-sm text-gray-400"
              style={{
                filter: 'blur(4px)',
                userSelect: 'none',
              }}
            >
              silva
            </span>
          </div>
          <p className="text-xs text-gray-400">
            lari
            <span style={{ filter: 'blur(3px)', userSelect: 'none' }}>ssa_silva</span>
          </p>
        </div>

        <div className="flex gap-4 text-gray-800">
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
          </svg>
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
          </svg>
        </div>
      </div>

      {/* Chat Messages Area */}
      <div
        ref={chatRef}
        className="px-3 py-4 space-y-2 overflow-y-auto"
        style={{
          height: 280,
          background: '#FFFFFF'
        }}
      >
        {/* Mensagem inicial se não começou */}
        {!hasStarted && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex justify-start items-end gap-2"
          >
            <img
              src="/perfil_larissa.jpg"
              alt="Larissa"
              className="w-7 h-7 rounded-full object-cover flex-shrink-0"
            />
            <div
              style={{
                background: '#EFEFEF',
                borderRadius: '20px',
                padding: '10px 14px',
                maxWidth: '70%',
              }}
            >
              <p className="text-[15px] text-gray-900">{conversationFlow[0].incoming[0]}</p>
            </div>
          </motion.div>
        )}

        {/* Mensagens do chat */}
        <AnimatePresence mode="popLayout">
          {chatMessages.map((msg, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 10, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 0.2 }}
              className={`flex items-end gap-2 ${msg.type === "out" ? "justify-end" : "justify-start"}`}
            >
              {msg.type === "in" && (
                <img
                  src="/perfil_larissa.jpg"
                  alt="Larissa"
                  className="w-7 h-7 rounded-full object-cover flex-shrink-0"
                  style={{
                    visibility: shouldShowAvatar(i) ? 'visible' : 'hidden'
                  }}
                />
              )}
              <div
                style={{
                  background: msg.type === "out"
                    ? 'linear-gradient(90deg, #8B5CF6, #A855F7, #C026D3)'
                    : '#EFEFEF',
                  borderRadius: '20px',
                  padding: '10px 14px',
                  maxWidth: '70%',
                }}
              >
                <p className={`text-[15px] ${msg.type === "out" ? "text-white" : "text-gray-900"}`}>
                  {msg.text}
                </p>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>

        {/* Scanner Animation */}
        <AnimatePresence>
          {gameState === "scanning" && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute left-0 right-0 pointer-events-none"
              style={{ top: 60, bottom: 70 }}
            >
              <motion.div
                className="absolute left-0 right-0 h-1"
                style={{
                  background: 'linear-gradient(90deg, transparent, #A855F7, #EC4899, #A855F7, transparent)',
                  boxShadow: '0 0 20px #A855F7, 0 0 40px #EC4899',
                  top: `${scanProgress}%`,
                }}
              />
              <div
                className="absolute inset-0"
                style={{
                  background: 'linear-gradient(180deg, rgba(168,85,247,0.05) 0%, rgba(236,72,153,0.05) 100%)',
                  backgroundImage: `
                    linear-gradient(rgba(168,85,247,0.1) 1px, transparent 1px),
                    linear-gradient(90deg, rgba(168,85,247,0.1) 1px, transparent 1px)
                  `,
                  backgroundSize: '20px 20px',
                }}
              />
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Input Bar - Instagram Style (sempre visível, muda de estado) */}
      <div
        className="px-3 py-2"
        style={{
          borderTop: '1px solid rgba(0, 0, 0, 0.1)',
          background: '#FFFFFF'
        }}
      >
        <div className="flex items-center gap-2">
          {/* Camera icon - discreto */}
          <div
            className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0"
            style={{
              border: '1px solid rgba(0, 0, 0, 0.15)',
              background: '#FAFAFA',
            }}
          >
            <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
              <circle cx="12" cy="13" r="3" />
            </svg>
          </div>

          {/* Input/Action area */}
          <div className="flex-1 min-w-0 flex items-center justify-center">
            <AnimatePresence>
              {/* Estado: Aguardando clique */}
              {gameState === "waiting_click" && (
                <motion.button
                  key="cta"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.2 }}
                  onClick={handleGenerateClick}
                  className="flex items-center justify-center gap-3 relative rounded-xl overflow-hidden"
                  style={{
                    background: 'linear-gradient(135deg, #A855F7 0%, #EC4899 100%)',
                    boxShadow: '0 4px 15px rgba(168, 85, 247, 0.4)',
                    padding: '14px 24px',
                  }}
                >
                  <Sparkles className="w-5 h-5 text-white relative z-10" />
                  <span className="font-bold text-white relative z-10 uppercase tracking-wide" style={{ fontSize: 14 }}>
                    Responder com IA
                  </span>
                </motion.button>
              )}

              {/* Estado: Analisando */}
              {gameState === "scanning" && (
                <motion.div
                  key="scanning"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  className="px-4 py-3 flex items-center gap-3 rounded-xl"
                  style={{
                    background: 'linear-gradient(90deg, rgba(168,85,247,0.1), rgba(236,72,153,0.1))',
                  }}
                >
                  <div className="w-4 h-4 border-2 border-purple-500 border-t-transparent rounded-full animate-spin" />
                  <div className="flex-1">
                    <div className="h-1.5 rounded-full bg-gray-200 overflow-hidden">
                      <motion.div
                        className="h-full rounded-full"
                        style={{
                          background: 'linear-gradient(90deg, #A855F7, #EC4899)',
                          width: `${scanProgress}%`,
                        }}
                      />
                    </div>
                  </div>
                  <span className="text-xs text-gray-500">{scanProgress}%</span>
                </motion.div>
              )}

              {/* Estado: Sugestão pronta - aparece como texto digitado no input */}
              {gameState === "showing_suggestion" && currentFlow?.suggestion && (
                <motion.div
                  key="suggestion"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.2 }}
                  className="w-full rounded-3xl"
                  style={{
                    background: '#FAFAFA',
                    border: '1px solid #DBDBDB',
                    padding: '12px 16px',
                  }}
                >
                  <p
                    className="text-[14px] text-gray-900 leading-relaxed"
                    style={{ wordBreak: 'break-word' }}
                  >
                    {currentFlow.suggestion}
                  </p>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Botão de enviar ou ícones */}
          {gameState === "showing_suggestion" ? (
            <motion.button
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              onClick={handleSendSuggestion}
              className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0"
              style={{
                background: 'linear-gradient(135deg, #A855F7, #EC4899)',
              }}
            >
              <Send className="w-5 h-5 text-white" />
            </motion.button>
          ) : (
            <div className="flex items-center gap-0.5 text-gray-300">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
              </svg>
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
          )}
        </div>
      </div>

      {/* Victory Overlay */}
      <AnimatePresence>
        {gameState === "victory" && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 flex flex-col items-center justify-center z-50"
            style={{
              background: 'rgba(0, 0, 0, 0.85)',
              backdropFilter: 'blur(10px)',
            }}
          >
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ type: "spring", delay: 0.2 }}
              className="flex flex-col items-center justify-center text-center px-6"
            >
              {/* Confetti effect */}
              <div className="absolute inset-0 overflow-hidden pointer-events-none">
                {[...Array(20)].map((_, i) => (
                  <motion.div
                    key={i}
                    className="absolute w-2 h-2 rounded-full"
                    style={{
                      background: ['#A855F7', '#EC4899', '#F59E0B', '#10B981', '#3B82F6'][i % 5],
                      left: `${Math.random() * 100}%`,
                      top: -10,
                    }}
                    animate={{
                      y: [0, 400],
                      x: [0, (Math.random() - 0.5) * 100],
                      rotate: [0, 360],
                      opacity: [1, 0],
                    }}
                    transition={{
                      duration: 2,
                      delay: i * 0.1,
                      ease: "easeOut",
                    }}
                  />
                ))}
              </div>

              <motion.div
                initial={{ scale: 0, rotate: -180 }}
                animate={{ scale: 1, rotate: 0 }}
                transition={{ type: "spring", delay: 0.3 }}
                className="w-20 h-20 mx-auto rounded-full flex items-center justify-center mb-4"
                style={{
                  background: 'linear-gradient(135deg, #F59E0B, #EF4444)',
                  boxShadow: '0 0 40px rgba(245,158,11,0.5)',
                }}
              >
                <Trophy className="w-10 h-10 text-white" />
              </motion.div>

              <motion.h3
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
                className="text-2xl font-black text-white mb-2 uppercase"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                Você Conquistou Ela! 🎉
              </motion.h3>

              <motion.p
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.7 }}
                className="text-white/60"
              >
                Em apenas <span className="text-purple-400 font-bold">4 mensagens</span> usando o Desenrola AI
              </motion.p>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  )
}
