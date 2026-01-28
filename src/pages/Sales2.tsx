import { useEffect, useState, useRef, useCallback } from "react"
import { useLocation } from "wouter"
import { useQuizStore } from "@/lib/store"
import { Check, Shield, Zap, Star, X, ArrowRight, Sparkles, Loader2 } from "lucide-react"
import { trackViewContent, trackInitiateCheckout, trackScrollDepth, trackTimeOnPage, trackLeadCapture } from "@/lib/tracking"
import { saveAbandonedLead } from "@/lib/leads"

const API_URL = 'https://dating-app-production-ac43.up.railway.app';

const PAYMENT_LINKS: Record<string, string> = {
  mensal: "https://buy.stripe.com/eVq9AS3Go12xcle7zY5AQ01",
  trimestral: "https://buy.stripe.com/aFabJ0fp67qVfxqdYm5AQ02",
  anual: "https://buy.stripe.com/bJedR8el2bHb1GA1bA5AQ04",
};

const plans = [
  { id: "mensal", stripePlan: "monthly", priceId: "price_1SgsCVAflPjpW4DOXIZVjcA4", name: "Mensal", price: "29,90", period: "/mes", equivalent: "Equivale a R$29,90/mes", originalPrice: "", badge: "", badgeBottom: "", highlight: false, discount: "" },
  { id: "trimestral", stripePlan: "quarterly", priceId: "price_1SgsmgAflPjpW4DO0oID3xaW", name: "Trimestral", price: "69,90", originalPrice: "89,70", period: "/trimestre", equivalent: "Equivale a R$23,30/mes", badge: "MAIS POPULAR", badgeBottom: "MELHOR VALOR", highlight: true, discount: "22% OFF" },
  { id: "anual", stripePlan: "yearly", priceId: "price_1SgsESAflPjpW4DO6Sd4z8n0", name: "Anual", price: "199,90", originalPrice: "358,80", period: "/ano", equivalent: "Equivale a R$16,66/mes", badge: "44% OFF", badgeBottom: "", highlight: false, discount: "" }
]

const profileContent: Record<string, { headline: string; subheadline: string; painPoints: string[]; solutions: string[]; benefits: string[] }> = {
  iniciante: {
    headline: "Voce nao precisa mais se sentir perdido",
    subheadline: "O Desenrola AI foi feito para quem esta comecando do zero",
    painPoints: ["Nao sabe como comecar uma conversa sem parecer estranho", "Fica travado sem saber o que responder", "Medo de ser ignorado ou rejeitado", "Nao tem ideia de como manter o interesse dela"],
    solutions: ["Templates prontos para iniciar qualquer conversa com confianca", "Respostas inteligentes que mantem o papo fluindo naturalmente", "Tecnicas para criar conexao desde a primeira mensagem", "Guia passo a passo do match ate o encontro"],
    benefits: ["Tenha seu primeiro encontro em ate 7 dias", "Nunca mais fique sem saber o que dizer", "Construa confianca real nas suas interacoes", "Transforme matches em conversas que evoluem"]
  },
  timido: {
    headline: "Sua timidez nao precisa te limitar",
    subheadline: "Descubra como se expressar sem forcar sua personalidade",
    painPoints: ["Sente ansiedade so de pensar em puxar assunto", "Demora dias para responder por medo de errar", "Conversas morrem porque voce nao sabe continuar", "Perde oportunidades por nao conseguir se expressar"],
    solutions: ["Mensagens prontas que soam naturais e nao forcadas", "Tecnicas para ganhar tempo e pensar nas respostas", "Scripts para momentos de bloqueio criativo", "Exercicios graduais para aumentar sua confianca"],
    benefits: ["Converse sem aquela pressao no peito", "Responda rapido e com seguranca", "Mostre sua personalidade real aos poucos", "Conquiste no seu ritmo sem se forcar"]
  },
  romantico: {
    headline: "Equilibre romance com estrategia",
    subheadline: "Seja romantico sem parecer desesperado",
    painPoints: ["Suas mensagens parecem intensas demais no inicio", "Voce se apega rapido e isso afasta as pessoas", "Confunde interesse educado com conexao real", "Investe muito em quem nao retribui"],
    solutions: ["Timing certo para demonstrar interesse sem exagerar", "Como ler os sinais de interesse real vs educacao", "Tecnicas para dosar o romance na medida certa", "Filtros para identificar quem vale seu investimento"],
    benefits: ["Atraia pessoas que valorizam romance de verdade", "Crie conexoes profundas sem se queimar", "Saiba quando e como intensificar", "Encontre alguem que combine com seu jeito de amar"]
  },
  "conversador-trava": {
    headline: "Destrave suas conversas de vez",
    subheadline: "Transforme papos que morrem em encontros que acontecem",
    painPoints: ["Comeca bem mas a conversa sempre esfria", "Nao sabe como evoluir do chat pro encontro", "Fica preso em papo superficial sem profundidade", "Perde o timing de chamar pra sair"],
    solutions: ["Tecnicas de escalada conversacional comprovadas", "O momento exato de propor o encontro", "Perguntas que criam intimidade natural", "Como manter o interesse entre as mensagens"],
    benefits: ["Converta mais matches em encontros reais", "Nunca mais deixe uma conversa morrer", "Crie tensao e expectativa do jeito certo", "Domine a arte da transicao chat-encontro"]
  },
  conquistador: {
    headline: "Leve seu jogo para o proximo nivel",
    subheadline: "Otimize seus resultados com estrategias avancadas",
    painPoints: ["Tem matches mas quer mais qualidade", "Sente que esta no piloto automatico", "Quer se destacar das mensagens genericas", "Busca conexoes mais significativas"],
    solutions: ["Estrategias avancadas de diferenciacao", "Tecnicas de personalizacao em escala", "Como filtrar e priorizar os melhores matches", "Frameworks para conversas memoraveis"],
    benefits: ["Atraia pessoas de maior qualidade", "Gaste menos tempo com mais resultados", "Crie conexoes genuinas e duradouras", "Seja lembrado como diferente de todos"]
  },
  analitico: {
    headline: "Dados e estrategia a seu favor",
    subheadline: "Uma abordagem sistematica para conexoes reais",
    painPoints: ["Analisa tanto que perde a espontaneidade", "Suas mensagens parecem calculadas demais", "Dificuldade em criar conexao emocional", "Overthinking paralisa suas acoes"],
    solutions: ["Frameworks que equilibram logica e emocao", "Templates que soam naturais mesmo sendo planejados", "Como usar sua capacidade analitica a favor", "Tecnicas para sair da cabeca e agir"],
    benefits: ["Converta analise em acao efetiva", "Crie conexoes genuinas usando seu estilo", "Tenha um sistema que funciona de verdade", "Resultados mensuraveis e consistentes"]
  }
}

export default function Sales2() {
  const [, setLocation] = useLocation()
  const { matchedProfile } = useQuizStore()
  const [selectedPlan, setSelectedPlan] = useState<string>("trimestral")
  const [email, setEmail] = useState("")
  const [name, setName] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email)) {
      setError("Digite um email valido")
      return
    }

    if (!name.trim() || name.trim().length < 2) {
      setError("Digite seu nome completo")
      return
    }

    setLoading(true)
    setError(null)

    const planData = plans.find(p => p.id === selectedPlan)
    if (!planData) {
      setError("Selecione um plano")
      setLoading(false)
      return
    }

    try {
      // Tentar usar a API primeiro (melhor: verifica duplicados, cria cliente, tracking)
      const response = await fetch(`${API_URL}/create-checkout-redirect`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          priceId: planData.priceId,
          plan: planData.stripePlan,
          email: email.trim().toLowerCase(),
          name: name.trim(),
        })
      })

      const data = await response.json()

      if (!response.ok) {
        if (data.existingSubscription) {
          setError("Este email ja possui uma assinatura. Faca login para acessar.")
          setLoading(false)
          return
        }
        // Se a API falhar por outro motivo, usar Payment Link como fallback
        throw new Error(data.message || "API error")
      }

      if (data.url) {
        window.location.href = data.url
      } else {
        throw new Error("No URL returned")
      }
    } catch (err: any) {
      console.warn("API falhou, usando Payment Link como fallback:", err.message)

      // Fallback: usar Payment Link diretamente
      saveAbandonedLead(email.trim(), planData.name, name.trim())
      const paymentLink = PAYMENT_LINKS[planData.id]
      if (paymentLink) {
        const checkoutUrl = `${paymentLink}?prefilled_email=${encodeURIComponent(email.trim().toLowerCase())}`
        window.location.href = checkoutUrl
      } else {
        setError("Erro ao processar. Tente novamente.")
        setLoading(false)
      }
    }
  }

  // Tracking refs
  const scrollMilestonesRef = useRef<Set<number>>(new Set())
  const timeIntervalsRef = useRef<Set<number>>(new Set())
  const icFiredRef = useRef(false)
  const lastCapturedEmailRef = useRef<string>("")
  const startTimeRef = useRef(Date.now())

  // Track scroll depth
  useEffect(() => {
    const handleScroll = () => {
      const scrollTop = window.scrollY
      const docHeight = document.documentElement.scrollHeight - window.innerHeight
      const scrollPercent = Math.round((scrollTop / docHeight) * 100)

      const milestones = [25, 50, 75, 100]
      milestones.forEach(milestone => {
        if (scrollPercent >= milestone && !scrollMilestonesRef.current.has(milestone)) {
          scrollMilestonesRef.current.add(milestone)
          trackScrollDepth(milestone, 'sales')
        }
      })
    }

    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  // Track time on page
  useEffect(() => {
    const intervals = [15, 30, 60, 120, 180] // segundos

    const checkTime = () => {
      const elapsed = Math.floor((Date.now() - startTimeRef.current) / 1000)
      intervals.forEach(interval => {
        if (elapsed >= interval && !timeIntervalsRef.current.has(interval)) {
          timeIntervalsRef.current.add(interval)
          trackTimeOnPage(interval, 'sales')
        }
      })
    }

    const timer = setInterval(checkTime, 1000)
    return () => clearInterval(timer)
  }, [])

  // Track lead capture when both name and email are filled
  const checkAndCaptureLeadData = useCallback((currentName: string, currentEmail: string) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    const trimmedEmail = currentEmail.trim().toLowerCase()
    if (
      currentName.trim().length >= 2 &&
      emailRegex.test(currentEmail) &&
      trimmedEmail !== lastCapturedEmailRef.current
    ) {
      lastCapturedEmailRef.current = trimmedEmail
      trackLeadCapture(currentName.trim(), currentEmail.trim(), 'sales_page')
      // Salvar lead abandonado para disparo de emails
      const planData = plans.find(p => p.id === selectedPlan)
      saveAbandonedLead(currentEmail.trim(), planData?.name || selectedPlan, currentName.trim())
    }
  }, [selectedPlan])

  // Check and fire IC
  const checkAndFireIC = useCallback((currentName: string) => {
    if (currentName.trim().length >= 2 && !icFiredRef.current) {
      icFiredRef.current = true
      const planData = plans.find(p => p.id === selectedPlan)
      trackInitiateCheckout(selectedPlan, planData?.price)
    }
  }, [selectedPlan])

  // Handle name change - also check on change for mobile
  const handleNameChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newName = e.target.value
    setName(newName)
    // Fire IC when name has 2+ chars (works on mobile)
    if (newName.trim().length >= 2 && !icFiredRef.current) {
      setTimeout(() => checkAndFireIC(newName), 500)
    }
  }

  // Handle email change - also check on change for mobile
  const handleEmailChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newEmail = e.target.value
    setEmail(newEmail)
    // Check lead capture when email looks valid (works on mobile)
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    const trimmedEmail = newEmail.trim().toLowerCase()
    if (emailRegex.test(newEmail) && name.trim().length >= 2 && trimmedEmail !== lastCapturedEmailRef.current) {
      setTimeout(() => checkAndCaptureLeadData(name, newEmail), 500)
    }
  }

  // Handle name blur - fire initiate_checkout
  const handleNameBlur = () => {
    checkAndFireIC(name)
  }

  // Handle email blur - check for lead capture
  const handleEmailBlur = () => {
    checkAndCaptureLeadData(name, email)
  }

  useEffect(() => {
    window.scrollTo(0, 0)
    trackViewContent('sales')
  }, [])

  const profileId = matchedProfile?.id || "iniciante"
  const content = profileContent[profileId] || profileContent.iniciante

  const features = ["Acesso completo ao Desenrola AI", "Plano personalizado para seu perfil", "Atualizacoes e novos conteudos", "Suporte prioritario", "Garantia de 7 dias"]

  return (
    <div className="min-h-screen bg-background text-foreground py-8 px-6">
      <div className="max-w-md mx-auto">

        <header className="text-center" style={{ marginBottom: 40 }}>
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-primary/30" style={{ backgroundColor: "rgba(168, 85, 247, 0.1)", marginBottom: 16 }}>
            <Sparkles className="w-4 h-4 text-primary" />
            <span className="text-sm font-medium text-primary">Perfil: {matchedProfile?.name || "Iniciante"}</span>
          </div>
          <h1 className="text-2xl font-bold" style={{ marginBottom: 8 }}>{content.headline}</h1>
          <p className="text-sm text-muted-foreground">{content.subheadline}</p>
        </header>

        <section className="bg-zinc-900/60 border border-zinc-700/50" style={{ borderRadius: 16, padding: 24, marginBottom: 24 }}>
          <div className="flex items-center gap-2" style={{ marginBottom: 16 }}>
            <X className="w-5 h-5 text-red-500" />
            <h3 className="font-semibold text-white">Voce se identifica?</h3>
          </div>
          <ul>
            {content.painPoints.map((point, i) => (
              <li key={i} className="flex items-start gap-3" style={{ marginBottom: i < content.painPoints.length - 1 ? 12 : 0 }}>
                <div style={{ width: 8, height: 8, borderRadius: "50%", backgroundColor: "hsl(0 84% 60%)", marginTop: 6, flexShrink: 0 }} />
                <span className="text-sm text-white/70">{point}</span>
              </li>
            ))}
          </ul>
        </section>

        <section className="bg-zinc-900/60 border border-primary/30" style={{ borderRadius: 16, padding: 24, marginBottom: 24 }}>
          <div className="flex items-center gap-2" style={{ marginBottom: 16 }}>
            <Check className="w-5 h-5 text-primary" />
            <h3 className="font-semibold text-white">O Desenrola AI resolve isso</h3>
          </div>
          <ul>
            {content.solutions.map((solution, i) => (
              <li key={i} className="flex items-start gap-3" style={{ marginBottom: i < content.solutions.length - 1 ? 12 : 0 }}>
                <div style={{ width: 20, height: 20, borderRadius: "50%", backgroundColor: "rgba(168, 85, 247, 0.2)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <Check className="w-3 h-3 text-primary" />
                </div>
                <span className="text-sm text-white/80">{solution}</span>
              </li>
            ))}
          </ul>
        </section>

        <section className="bg-zinc-900/60 border border-secondary/30" style={{ borderRadius: 16, padding: 24, marginBottom: 24 }}>
          <div className="flex items-center gap-2" style={{ marginBottom: 16 }}>
            <ArrowRight className="w-5 h-5 text-secondary" />
            <h3 className="font-semibold text-white">O que voce vai conquistar</h3>
          </div>
          <ul>
            {content.benefits.map((benefit, i) => (
              <li key={i} className="flex items-start gap-3" style={{ marginBottom: i < content.benefits.length - 1 ? 12 : 0 }}>
                <div style={{ width: 20, height: 20, borderRadius: "50%", backgroundColor: "rgba(236, 72, 153, 0.2)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <ArrowRight className="w-3 h-3 text-secondary" />
                </div>
                <span className="text-sm text-white/80">{benefit}</span>
              </li>
            ))}
          </ul>
        </section>

        <div className="bg-zinc-900/40 border border-zinc-700/30" style={{ borderRadius: 12, padding: 16, marginBottom: 32 }}>
          <div className="flex items-center gap-2" style={{ marginBottom: 8 }}>
            <div className="flex text-yellow-400">{[...Array(5)].map((_, i) => (<Star key={i} className="w-4 h-4 fill-current" />))}</div>
            <span className="text-xs text-muted-foreground">4.9 (2.847 avaliacoes)</span>
          </div>
          <p className="text-sm text-white/70 italic">"Depois do Desenrola, consegui finalmente ter conversas naturais e marquei varios encontros!"</p>
          <p className="text-xs text-muted-foreground" style={{ marginTop: 8 }}>- Lucas, 28 anos</p>
        </div>

        <div className="text-center" style={{ marginBottom: 24 }}>
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-green-500/30" style={{ backgroundColor: "rgba(34, 197, 94, 0.1)", marginBottom: 16 }}>
            <Shield className="w-4 h-4 text-green-500" />
            <span className="text-sm font-bold text-green-500">Garantia de 7 Dias</span>
          </div>
          <h2 className="text-xl font-bold">Escolha seu plano</h2>
          <p className="text-sm text-muted-foreground mt-2">Nao gostou? Devolvemos 100% em ate 7 dias.</p>
        </div>

        <div style={{ marginBottom: 24 }}>
          {plans.map((plan) => {
            const isSelected = selectedPlan === plan.id;
            return (
              <div key={plan.id} onClick={() => setSelectedPlan(plan.id)} className="cursor-pointer transition-all duration-300" style={{ marginBottom: 16, padding: isSelected ? 3 : 0, background: isSelected ? "linear-gradient(135deg, hsl(280 100% 65%), hsl(320 100% 60%))" : "transparent", borderRadius: 16 }}>
                <div className={isSelected ? "bg-zinc-900" : "bg-zinc-900/60 border border-zinc-700/50"} style={{ borderRadius: isSelected ? 13 : 16, padding: "20px 24px", position: "relative" }}>
                  {plan.badge && (<div style={{ position: "absolute", top: -12, right: 16, backgroundColor: isSelected ? "hsl(280 100% 65%)" : "hsl(320 100% 60%)", color: "white", fontSize: 10, fontWeight: 700, padding: "4px 12px", borderRadius: 20 }}>{plan.badge}</div>)}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div style={{ width: 20, height: 20, borderRadius: "50%", border: isSelected ? "2px solid hsl(280 100% 65%)" : "2px solid #555", display: "flex", alignItems: "center", justifyContent: "center" }}>
                        {isSelected && (<div style={{ width: 10, height: 10, borderRadius: "50%", backgroundColor: "hsl(280 100% 65%)" }} />)}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-white">{plan.name}</span>
                          {plan.discount && (<span style={{ backgroundColor: "hsl(320 100% 60%)", color: "white", fontSize: 10, fontWeight: 700, padding: "2px 8px", borderRadius: 10 }}>{plan.discount}</span>)}
                        </div>
                        <span className="text-xs text-muted-foreground">{plan.equivalent}</span>
                      </div>
                    </div>
                    <div className="text-right">
                      {plan.originalPrice && (<span className="text-base text-muted-foreground line-through" style={{ marginRight: 8 }}>R${plan.originalPrice}</span>)}
                      <span className="text-2xl font-bold text-white">R$ {plan.price}</span>
                      <span className="text-sm text-muted-foreground">{plan.period}</span>
                    </div>
                  </div>
                  {plan.badgeBottom && (<div style={{ marginTop: 12, backgroundColor: "rgba(168, 85, 247, 0.2)", color: "hsl(280 100% 70%)", fontSize: 11, fontWeight: 700, padding: "6px 0", borderRadius: 8, textAlign: "center" }}>{plan.badgeBottom}</div>)}
                </div>
              </div>
            );
          })}
        </div>

        {/* Security Badges - logo após seleção de planos */}
        <div className="flex items-center justify-center gap-4 mb-6">
          <div className="flex items-center gap-1.5 text-green-500">
            <Shield className="w-4 h-4" />
            <span className="text-xs font-medium">Seguro</span>
          </div>
          <div className="flex items-center gap-1.5 text-green-500">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd"/>
            </svg>
            <span className="text-xs font-medium">Criptografado</span>
          </div>
        </div>

        <div className="bg-zinc-900/60 border border-zinc-700/50" style={{ borderRadius: 16, padding: 24, marginBottom: 24 }}>
          <h3 className="font-semibold text-white flex items-center gap-2" style={{ marginBottom: 4 }}>
            <Zap className="w-5 h-5 text-primary" />
            Ative seu acesso
          </h3>
          <p className="text-xs text-muted-foreground mb-4">Preencha seus dados para continuar</p>

          <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: 12 }}>
            <label className="block text-sm text-muted-foreground mb-2">Nome completo</label>
            <input
              type="text"
              value={name}
              onChange={handleNameChange}
              onBlur={handleNameBlur}
              placeholder="Seu nome"
              className="w-full bg-zinc-800 border border-zinc-700 px-4 text-white placeholder-zinc-500 focus:outline-none focus:border-primary"
              style={{ borderRadius: 4, paddingTop: 18, paddingBottom: 18 }}
            />
          </div>
          <div style={{ marginBottom: 12 }}>
            <label className="block text-sm text-muted-foreground mb-2">Email</label>
            <input
              type="email"
              value={email}
              onChange={handleEmailChange}
              onBlur={handleEmailBlur}
              placeholder="seu@email.com"
              className="w-full bg-zinc-800 border border-zinc-700 px-4 text-white placeholder-zinc-500 focus:outline-none focus:border-primary"
              style={{ borderRadius: 4, paddingTop: 18, paddingBottom: 18 }}
            />
          </div>

          {error && <p className="text-red-500 text-sm mb-4">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full cta-gradient transition-all duration-300 hover:scale-[1.02] active:scale-[0.98] cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed flex flex-col items-center justify-center gap-1"
            style={{ padding: "18px 24px", borderRadius: 6 }}
          >
            {loading ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                <span className="uppercase tracking-wide font-bold text-white">Redirecionando...</span>
              </>
            ) : (
              <>
                <span className="uppercase tracking-wide font-bold text-white text-base">Continuar para Pagamento</span>
                <span className="text-xs text-white/80 font-normal">Pagamento seguro via Stripe</span>
              </>
            )}
          </button>

                    </form>
        </div>

        <div className="bg-zinc-900/60 border border-zinc-700/50" style={{ borderRadius: 16, padding: 24, marginBottom: 24 }}>
          <h3 className="font-semibold text-white" style={{ marginBottom: 16 }}>O que voce recebe:</h3>
          <ul>
            {features.map((feature, i) => (
              <li key={i} className="flex items-center gap-3" style={{ marginBottom: i < features.length - 1 ? 12 : 0 }}>
                <div style={{ width: 20, height: 20, borderRadius: "50%", backgroundColor: "rgba(34, 197, 94, 0.2)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <Check className="w-3 h-3 text-green-500" />
                </div>
                <span className="text-sm text-white/80">{feature}</span>
              </li>
            ))}
          </ul>
        </div>

        <div className="flex items-center justify-center gap-2 text-muted-foreground text-xs" style={{ marginBottom: 24 }}>
          <Shield className="w-4 h-4" />
          <span>Pagamento 100% seguro</span>
        </div>

        <p className="text-center text-xs text-muted-foreground">Ao continuar, voce concorda com nossos termos de uso. Garantia de 7 dias - nao gostou? Devolvemos 100%.</p>
      </div>
    </div>
  )
}
