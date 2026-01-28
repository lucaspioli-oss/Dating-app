import { useState, useEffect, useRef } from "react"
import { useLocation } from "wouter"
import { useQuizStore } from "@/lib/store"
import { questions } from "@/lib/data"
import { motion, AnimatePresence } from "framer-motion"
import { Bot, Send } from "lucide-react"
import { trackLead } from "@/lib/tracking"

export default function Quiz() {
  const [, setLocation] = useLocation()
  const { currentQuestionIndex, answerQuestion, nextQuestion, calculateProfile, resetQuiz } = useQuizStore()
  const [chatHistory, setChatHistory] = useState<{ role: "bot" | "user", text: string }[]>([])
  const [isTyping, setIsTyping] = useState(false)
  const [isProcessing, setIsProcessing] = useState(false)
  const scrollRef = useRef<HTMLDivElement>(null)

  const currentQuestion = questions[currentQuestionIndex]
  const progress = ((currentQuestionIndex + 1) / questions.length) * 100

  const playSendSound = () => {
    const audio = new Audio("https://assets.mixkit.co/active_storage/sfx/2354/2354-preview.mp3")
    audio.volume = 0.3
    audio.play().catch(() => {})
  }

  const playReceiveSound = () => {
    const audio = new Audio("https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3")
    audio.volume = 0.25
    audio.play().catch(() => {})
  }

  useEffect(() => {
    window.scrollTo(0, 0)
    resetQuiz()
    addBotMessage(questions[0].text)
  }, [])

  // Auto-scroll apenas quando nova mensagem é adicionada ao chat
  useEffect(() => {
    if (chatHistory.length === 0) return

    const scrollContainer = scrollRef.current
    if (!scrollContainer) return

    // Scroll suave para o final
    requestAnimationFrame(() => {
      scrollContainer.scrollTo({
        top: scrollContainer.scrollHeight,
        behavior: "smooth"
      })
    })
  }, [chatHistory.length])

  const addBotMessage = (text: string) => {
    setIsTyping(true)
    setTimeout(() => {
      setIsTyping(false)
      setChatHistory(prev => [...prev, { role: "bot", text }])
      playReceiveSound()
    }, 1200)
  }

  const handleOptionClick = (optionText: string, points: number) => {
    if (isProcessing) return
    setIsProcessing(true)

    playSendSound()
    setChatHistory(prev => [...prev, { role: "user", text: optionText }])
    answerQuestion(currentQuestion.id, points)

    const nextIdx = currentQuestionIndex + 1
    if (nextIdx < questions.length) {
      setTimeout(() => {
        nextQuestion()
        addBotMessage(questions[nextIdx].text)
        setIsProcessing(false)
      }, 500)
    } else {
      setTimeout(() => {
        calculateProfile()
        const { matchedProfile } = useQuizStore.getState()
        trackLead(matchedProfile?.id)
        setLocation("/result")
      }, 1000)
    }
  }

  return (
    <div className="h-[100dvh] bg-background text-foreground flex flex-col overflow-hidden">
      {/* Background effects */}
      <div className="fixed inset-0 -z-10 pointer-events-none overflow-hidden">
        <div className="absolute top-1/4 -left-20 w-80 h-80 bg-primary/15 rounded-full blur-[100px] animate-pulse" />
        <div className="absolute bottom-1/4 -right-20 w-80 h-80 bg-secondary/15 rounded-full blur-[100px] animate-pulse" style={{ animationDelay: "1s" }} />
      </div>

      {/* Header - Fixed height */}
      <header className="flex-shrink-0 px-5 py-4 border-b border-white/10 bg-black/60 backdrop-blur-md flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-full bg-gradient-to-tr from-primary to-secondary flex items-center justify-center shadow-lg neon-glow-purple">
            <Bot className="w-5 h-5 text-black" />
          </div>
          <div>
            <span className="font-heading font-black text-sm gradient-text">DESENROLA.AI</span>
            <div className="flex items-center gap-1.5 mt-0.5">
              <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
              <span className="text-[11px] text-white/50">Online agora</span>
            </div>
          </div>
        </div>
        <div className="flex gap-3 items-center">
          <div className="h-2 w-24 md:w-32 bg-white/10 rounded-full overflow-hidden">
            <motion.div className="h-full progress-bar" initial={{ width: 0 }} animate={{ width: progress + "%" }} transition={{ duration: 0.5 }} />
          </div>
          <span className="text-xs font-mono text-secondary font-bold">{currentQuestionIndex + 1}/{questions.length}</span>
        </div>
      </header>

      {/* Chat Area - Scrollable, takes remaining space */}
      <main
        ref={scrollRef}
        className="flex-1 overflow-y-auto overscroll-contain"
      >
        <div className="max-w-xl mx-auto px-6 md:px-10 py-6">
          <div className="flex flex-col gap-5">
            {chatHistory.map((msg, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.3 }}
                className={"flex " + (msg.role === "user" ? "justify-end" : "justify-start")}
              >
                {msg.role === "bot" ? (
                  <div className="flex items-end gap-3 max-w-[88%]">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-primary to-secondary flex items-center justify-center flex-shrink-0 shadow-lg">
                      <Bot className="w-5 h-5 text-black" />
                    </div>
                    <div className="chat-bot">
                      <span className="text-white text-[15px] leading-[1.6]">{msg.text}</span>
                    </div>
                  </div>
                ) : (
                  <div className="chat-user max-w-[88%]">
                    <span className="text-black text-[15px] leading-[1.6]">{msg.text}</span>
                  </div>
                )}
              </motion.div>
            ))}
            {isTyping && (
              <motion.div
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                className="flex justify-start"
              >
                <div className="flex items-end gap-3">
                  <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-primary to-secondary flex items-center justify-center flex-shrink-0 shadow-lg">
                    <Bot className="w-5 h-5 text-black" />
                  </div>
                  <div className="chat-bot flex gap-2">
                    <span className="typing-dot" />
                    <span className="typing-dot" />
                    <span className="typing-dot" />
                  </div>
                </div>
              </motion.div>
            )}
          </div>
        </div>
      </main>

      {/* Options Area - Fixed height at bottom */}
      <div className="flex-shrink-0 bg-background border-t border-white/5">
        <div className="max-w-xl mx-auto w-full px-6 md:px-10 py-4">
          <div style={{ minHeight: 180 }}>
            <AnimatePresence mode="wait">
              {!isTyping && !isProcessing && currentQuestion && (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.15 }}
                  className="flex flex-col gap-2 mb-3"
                >
                {currentQuestion.options.map((opt, i) => (
                  <motion.button
                    key={i}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.05 }}
                    onClick={() => handleOptionClick(opt.text, opt.points)}
                    className="option-btn text-left"
                  >
                    <span className="text-[15px] font-medium text-white/90">{opt.text}</span>
                  </motion.button>
                ))}
                </motion.div>
              )}
            </AnimatePresence>
          </div>
          <div className="glass rounded-2xl px-5 py-3 flex items-center gap-3">
            <div className="flex-1 text-white/30 text-sm">Selecione uma opcao acima...</div>
            <div className="w-9 h-9 rounded-full bg-white/10 flex items-center justify-center">
              <Send className="w-4 h-4 text-white/30" />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
