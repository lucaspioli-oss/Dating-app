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

            {/* Powered by Stripe */}
            <div className="flex items-center justify-center gap-2 mt-4 bg-white rounded-md px-3 py-2 w-fit mx-auto">
              <span className="text-xs text-zinc-600">Pagamento via</span>
              <svg className="h-5" viewBox="0 0 60 25" fill="none">
                <path d="M59.64 14.28c0-4.7-2.27-8.4-6.62-8.4-4.37 0-7.01 3.7-7.01 8.37 0 5.52 3.12 8.3 7.6 8.3 2.18 0 3.83-.49 5.08-1.19v-3.2c-1.25.63-2.68 1.01-4.5 1.01-1.78 0-3.36-.63-3.56-2.79h8.97c0-.24.04-1.19.04-1.63v-.47zm-9.07-1.74c0-2.08 1.27-2.94 2.43-2.94 1.13 0 2.32.86 2.32 2.94h-4.75zM38.23 5.88c-1.8 0-2.95.84-3.59 1.43l-.24-1.14h-3.97v21.38l4.52-.96.01-5.19c.66.48 1.62 1.16 3.22 1.16 3.26 0 6.23-2.62 6.23-8.4-.01-5.29-3.03-8.28-6.18-8.28zm-1.09 12.74c-1.07 0-1.7-.38-2.14-.86l-.02-6.78c.47-.53 1.12-.89 2.16-.89 1.65 0 2.79 1.85 2.79 4.26 0 2.45-1.12 4.27-2.79 4.27zM24.89 4.64l4.54-.97V.56l-4.54.96v3.12zM24.89 6.17h4.54v16.15h-4.54V6.17zM20.08 7.44l-.29-1.27h-3.9v16.15h4.52V11.5c1.07-1.39 2.87-1.14 3.43-.94V6.17c-.59-.22-2.72-.63-3.76 1.27zM11.14 2.02l-4.4.94-.02 14.79c0 2.73 2.05 4.74 4.78 4.74 1.51 0 2.62-.28 3.23-.61v-3.47c-.59.24-3.51 1.09-3.51-1.65V9.86h3.51V6.17h-3.51l-.08-4.15zM2.76 10.16c0-.72.6-1 1.58-1 1.42 0 3.21.43 4.63 1.19V6.34c-1.55-.62-3.08-.86-4.63-.86C1.65 5.48 0 6.9 0 9.35c0 3.78 5.2 3.18 5.2 4.81 0 .86-.74 1.13-1.78 1.13-1.54 0-3.51-.63-5.07-1.49v4.03c1.72.74 3.47 1.05 5.07 1.05 2.84 0 4.79-1.4 4.79-3.89-.02-4.08-5.45-3.36-5.45-4.83z" fill="#635BFF"/>
              </svg>
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
