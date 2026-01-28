import { useEffect, useState } from "react"
import { Link, useLocation } from "wouter"
import { useQuizStore } from "@/lib/store"
import confetti from "canvas-confetti"
import { ChevronDown, Lock, ArrowRight, Sparkles } from "lucide-react"
import { trackViewContent } from "@/lib/tracking"

const playCelebrationSound = () => {
  const audio = new Audio("https://assets.mixkit.co/active_storage/sfx/2013/2013-preview.mp3")
  audio.volume = 0.4
  audio.play().catch(() => {})
}



function CircularProgress({ score, maxScore = 140 }: { score: number; maxScore?: number }) {
  const radius = 80
  const circumference = 2 * Math.PI * radius
  const progress = Math.min(score / maxScore, 1)
  const offset = circumference * (1 - progress)

  return (
    <div className="relative w-52 h-52 mx-auto flex items-center justify-center animate-score-pulse-glow">
      <svg className="w-full h-full -rotate-90" viewBox="0 0 200 200">
        <circle cx="100" cy="100" r={radius} fill="none" stroke="hsl(260 15% 15%)" strokeWidth="12" />
        <circle cx="100" cy="100" r={radius} fill="none" stroke="url(#scoreGradient)" strokeWidth="12"
          strokeLinecap="round" strokeDasharray={circumference} strokeDashoffset={offset}
          className="animate-progress-ring" style={{ "--target-offset": offset } as React.CSSProperties} />
        <defs>
          <linearGradient id="scoreGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="hsl(280 100% 65%)" />
            <stop offset="100%" stopColor="hsl(320 100% 60%)" />
          </linearGradient>
        </defs>
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="text-5xl font-bold tracking-tight">{score}</span>
        <span className="text-sm text-muted-foreground uppercase tracking-widest mt-1">pontos</span>
      </div>
    </div>
  )
}

function AccordionItem({ index, content, isOpen, onToggle }: { index: number; content: string; isOpen: boolean; onToggle: () => void }) {
  return (
    <div className={"rounded-xl transition-all duration-300 " + (isOpen ? "bg-zinc-800 border-2 border-primary/50 shadow-lg shadow-primary/10" : "bg-zinc-900/80 border border-zinc-700/50")} style={{ marginBottom: 20 }}>
      <button onClick={onToggle} className="w-full flex items-center gap-4 text-left hover:bg-white/5 transition-colors cursor-pointer" style={{ padding: "20px 20px" }}>
        <span className="flex items-center justify-center w-8 h-8 rounded-full bg-gradient-to-br from-primary/20 to-secondary/20 text-primary font-semibold text-sm flex-shrink-0">{index + 1}</span>
        <span className="flex-1 text-foreground/90 text-sm">{isOpen ? content : "Toque para revelar"}</span>
        <ChevronDown className={"w-5 h-5 text-muted-foreground transition-transform duration-300 flex-shrink-0 " + (isOpen ? "rotate-180" : "")} />
      </button>
    </div>
  )
}

export default function Result() {
  const { matchedProfile, totalScore } = useQuizStore()
  const [, setLocation] = useLocation()
  const [analyzing, setAnalyzing] = useState(true)
  const [progress, setProgress] = useState(0)
  const [openPoints, setOpenPoints] = useState<number[]>([])

  useEffect(() => {
    window.scrollTo(0, 0)
    trackViewContent('result')
  }, [])

  useEffect(() => {
    if (!matchedProfile && !analyzing) {
      setLocation("/")
    }
  }, [matchedProfile, analyzing, setLocation])

  useEffect(() => {
    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(interval)
          setAnalyzing(false)
          return 100
        }
        return prev + 2
      })
    }, 30)
    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    if (!analyzing && matchedProfile) {
      playCelebrationSound()
      confetti({
        particleCount: 150,
        spread: 70,
        origin: { y: 0.6 },
        colors: ["#a855f7", "#ec4899", "#ffffff"]
      })
    }
  }, [analyzing, matchedProfile])

  
  const togglePoint = (index: number) => {
    setOpenPoints((prev) => prev.includes(index) ? prev.filter((p) => p !== index) : [...prev, index])
  }

  if (analyzing) {
    return (
      <div className="fixed inset-0 flex flex-col items-center justify-center bg-background text-foreground p-8">
        <div className="w-full max-w-md space-y-10 text-center flex flex-col items-center">
          <div className="relative w-36 h-36">
            <div className="absolute inset-0 border-4 border-primary/20 rounded-full animate-pulse"></div>
            <div className="absolute inset-0 border-4 border-t-primary rounded-full animate-spin"></div>
            <div className="absolute inset-0 flex items-center justify-center font-bold text-2xl">
              {progress}%
            </div>
          </div>
          <h2 className="text-2xl md:text-3xl font-bold animate-pulse">Analisando suas respostas...</h2>
          <div className="space-y-4 text-muted-foreground text-base">
            <p className={progress > 30 ? "text-primary transition-colors" : ""}>Mapeando padroes de comunicacao</p>
            <p className={progress > 60 ? "text-primary transition-colors" : ""}>Comparando com base de dados</p>
            <p className={progress > 90 ? "text-primary transition-colors" : ""}>Gerando estrategia personalizada</p>
          </div>
        </div>
      </div>
    )
  }

  if (!matchedProfile) return null

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-md mx-auto px-6 py-10 space-y-12">

        <header className="text-center space-y-2 animate-fade-up">
          <p className="text-sm uppercase tracking-[0.2em] text-muted-foreground">Seu perfil e</p>
          <h1 className="text-4xl font-bold gradient-text">{matchedProfile.name}</h1>
        </header>

        <div className="animate-fade-up-delay-1 flex justify-center">
          <CircularProgress score={totalScore} />
        </div>

        <p className="text-center text-muted-foreground leading-relaxed animate-fade-up-delay-2">
          {matchedProfile.description}
        </p>

        <section className="space-y-6 animate-fade-up-delay-3 mb-10">
          <div className="flex items-center gap-3">
            <Sparkles className="w-5 h-5 text-primary" />
            <h2 className="text-lg font-semibold uppercase tracking-wide">Seus Pontos de Atencao</h2>
          </div>
          <p className="text-sm text-muted-foreground">Clique para revelar cada ponto</p>
          <div className="space-y-8">
            {matchedProfile.recommendations.map((rec, i) => (
              <AccordionItem key={i} index={i} content={rec} isOpen={openPoints.includes(i)} onToggle={() => togglePoint(i)} />
            ))}
          </div>
        </section>

        <section className="bg-zinc-900/90 border border-zinc-800 rounded-2xl p-8 text-center animate-fade-up-delay-4" style={{ marginTop: 48 }}>
          <h3 className="text-xl font-bold uppercase tracking-wide">Desbloqueie Seu Plano Completo</h3>
          <p className="text-sm text-muted-foreground leading-relaxed">
            Preparamos um guia passo a passo especifico para o seu perfil <span className="text-primary font-medium">{matchedProfile.name}</span>.
          </p>
          <Link href="/sales2" className="flex justify-center">
            <button className="cta-gradient rounded-xl flex items-center justify-center gap-3 transition-all duration-300 hover:scale-[1.02] hover:shadow-lg hover:shadow-primary/25 active:scale-[0.98] cursor-pointer" style={{ paddingTop: 18, paddingBottom: 18, paddingLeft: 48, paddingRight: 48, marginTop: 20 }}>
              <span className="uppercase tracking-wide font-bold">Ver Meu Plano</span>
              <ArrowRight className="w-5 h-5" />
            </button>
          </Link>
          <div className="flex items-center justify-center gap-2 text-xs text-muted-foreground">
            <Lock className="w-3.5 h-3.5" />
            <span>Seu resultado e privado e nao sera compartilhado.</span>
          </div>
        </section>
      </div>
    </div>
  )
}
