import { useEffect, useState, useRef, useCallback } from "react"
import { Shield, Zap, Loader2 } from "lucide-react"
import { trackViewContent, trackInitiateCheckout, trackLeadCapture } from "@/lib/tracking"
import { saveAbandonedLead } from "@/lib/leads"

const plan = {
  id: "mensal",
  stripePlan: "monthly",
  priceId: "price_1SgsCVAflPjpW4DOXIZVjcA4",
  name: "Mensal",
  price: "29,90",
  period: "/mes",
  equivalent: "R$29,90/mes"
}

const API_URL = 'https://dating-app-production-ac43.up.railway.app';

export default function CheckoutMensal() {
  const [email, setEmail] = useState("")
  const [name, setName] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const icFiredRef = useRef(false)
  const lastCapturedEmailRef = useRef<string>("")

  const checkAndCaptureLeadData = useCallback((currentName: string, currentEmail: string) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    const trimmedEmail = currentEmail.trim().toLowerCase()
    if (currentName.trim().length >= 2 && emailRegex.test(currentEmail) && trimmedEmail !== lastCapturedEmailRef.current) {
      lastCapturedEmailRef.current = trimmedEmail
      trackLeadCapture(currentName.trim(), currentEmail.trim(), 'checkout_mensal')
      saveAbandonedLead(currentEmail, plan.name, currentName)
    }
  }, [])

  const checkAndFireIC = useCallback((currentName: string) => {
    if (currentName.trim().length >= 2 && !icFiredRef.current) {
      icFiredRef.current = true
      trackInitiateCheckout(plan.id, plan.price)
    }
  }, [])

  const handleNameChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newName = e.target.value
    setName(newName)
    if (newName.trim().length >= 2 && !icFiredRef.current) {
      setTimeout(() => checkAndFireIC(newName), 500)
    }
  }

  const handleEmailChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newEmail = e.target.value
    setEmail(newEmail)
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    const trimmedEmail = newEmail.trim().toLowerCase()
    if (emailRegex.test(newEmail) && name.trim().length >= 2 && trimmedEmail !== lastCapturedEmailRef.current) {
      setTimeout(() => checkAndCaptureLeadData(name, newEmail), 500)
    }
  }

  const handleNameBlur = () => checkAndFireIC(name)
  const handleEmailBlur = () => checkAndCaptureLeadData(name, email)

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

    try {
      const response = await fetch(`${API_URL}/create-checkout-redirect`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          priceId: plan.priceId,
          plan: plan.stripePlan,
          email: email.trim().toLowerCase(),
          name: name.trim(),
        })
      })

      const data = await response.json()

      if (!response.ok) {
        if (data.existingSubscription) {
          setError("Este email ja possui uma assinatura. Faca login para acessar.")
        } else {
          setError(data.message || "Erro ao processar. Tente novamente.")
        }
        setLoading(false)
        return
      }

      // Redirect to Stripe Checkout
      if (data.url) {
        window.location.href = data.url
      } else {
        setError("Erro ao criar checkout. Tente novamente.")
        setLoading(false)
      }
    } catch (err: any) {
      setError(err.message || "Erro ao conectar com o servidor")
      setLoading(false)
    }
  }

  useEffect(() => {
    window.scrollTo(0, 0)
    trackViewContent('checkout_mensal')
  }, [])

  return (
    <div className="min-h-screen bg-background text-foreground py-8 px-4">
      <div className="max-w-md mx-auto">

        {/* Price Display */}
        <div className="text-center" style={{ marginBottom: 24 }}>
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-green-500/30" style={{ backgroundColor: "rgba(34, 197, 94, 0.1)", marginBottom: 16 }}>
            <Shield className="w-4 h-4 text-green-500" />
            <span className="text-sm font-bold text-green-500">Garantia de 7 Dias</span>
          </div>
          <h2 className="text-xl font-bold" style={{ marginBottom: 8 }}>Plano {plan.name}</h2>
          <div className="text-3xl font-bold text-white">R$ {plan.price}<span className="text-lg text-muted-foreground">{plan.period}</span></div>
          <p className="text-sm text-muted-foreground mt-2">Nao gostou? Devolvemos 100% em ate 7 dias.</p>
        </div>

        {/* Checkout Form */}
        <div className="bg-zinc-900/80 border border-zinc-600/50" style={{ borderRadius: 20, padding: 32, marginBottom: 24 }}>
          <h3 className="font-semibold text-white flex items-center gap-2 text-lg" style={{ marginBottom: 4 }}>
            <Zap className="w-6 h-6 text-primary" />
            Ative seu acesso
          </h3>
          <p className="text-xs text-muted-foreground mb-6">Preencha seus dados para continuar</p>

          <form onSubmit={handleSubmit}>
            <div style={{ marginBottom: 16 }}>
              <label className="block text-sm text-muted-foreground mb-2">Nome completo</label>
              <input
                type="text"
                value={name}
                onChange={handleNameChange}
                onBlur={handleNameBlur}
                placeholder="Seu nome"
                className="w-full bg-zinc-800 border border-zinc-600 px-4 py-4 text-white placeholder-zinc-500 focus:outline-none focus:border-primary transition-colors"
                style={{ borderRadius: 8, fontSize: 16 }}
                disabled={loading}
              />
            </div>
            <div style={{ marginBottom: 24 }}>
              <label className="block text-sm text-muted-foreground mb-2">Email</label>
              <input
                type="email"
                value={email}
                onChange={handleEmailChange}
                onBlur={handleEmailBlur}
                placeholder="seu@email.com"
                className="w-full bg-zinc-800 border border-zinc-600 px-4 py-4 text-white placeholder-zinc-500 focus:outline-none focus:border-primary transition-colors"
                style={{ borderRadius: 8, fontSize: 16 }}
                disabled={loading}
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

            {/* Trust badges */}
            <div className="flex items-center justify-center gap-4 mt-4">
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

          </form>
        </div>

        {/* Guarantee Badge */}
        <div className="bg-gradient-to-r from-green-900/30 to-green-800/30 border border-green-500/30 rounded-2xl p-5 mb-6">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-full bg-green-500/20 flex items-center justify-center flex-shrink-0">
              <Shield className="w-7 h-7 text-green-500" />
            </div>
            <div>
              <h4 className="font-bold text-green-400 text-sm">GARANTIA DE 7 DIAS</h4>
              <p className="text-xs text-green-300/80 mt-1">Teste por 7 dias. Se nao ficar satisfeito, devolvemos 100% do seu dinheiro. Sem perguntas.</p>
            </div>
          </div>
        </div>

        <p className="text-center text-xs text-muted-foreground">Ao continuar, voce concorda com nossos termos de uso. Cancele a qualquer momento.</p>
      </div>
    </div>
  )
}
