import { useState, useEffect } from "react"
import { Check, Eye, EyeOff, Loader2, ArrowRight } from "lucide-react"
import { useLocation } from "wouter"

const API_URL = "https://dating-app-production-ac43.up.railway.app"

export default function Success() {
  const [, setLocation] = useLocation()
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  useEffect(() => {
    // Get email from URL params
    const params = new URLSearchParams(window.location.search)
    const emailParam = params.get("email")
    if (emailParam) {
      setEmail(decodeURIComponent(emailParam))
    }
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    // Validations
    if (!email) {
      setError("Email e obrigatorio")
      return
    }

    if (password.length < 6) {
      setError("Senha deve ter no minimo 6 caracteres")
      return
    }

    if (password !== confirmPassword) {
      setError("As senhas nao coincidem")
      return
    }

    setLoading(true)

    try {
      const response = await fetch(`${API_URL}/set-password`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || data.message || "Erro ao definir senha")
      }

      setSuccess(true)

      // Redirect to app after 2 seconds
      setTimeout(() => {
        window.location.href = "https://app.desenrolaai.site"
      }, 2000)

    } catch (err: any) {
      setError(err.message || "Erro ao definir senha")
    } finally {
      setLoading(false)
    }
  }

  const handleSkip = () => {
    window.location.href = "https://app.desenrolaai.site"
  }

  if (success) {
    return (
      <div className="min-h-screen bg-background text-foreground flex items-center justify-center p-8">
        <div className="text-center max-w-md">
          <div className="w-20 h-20 mx-auto mb-6 rounded-full bg-green-500/20 flex items-center justify-center">
            <Check className="w-10 h-10 text-green-500" />
          </div>
          <h1 className="text-2xl font-bold mb-2">Senha definida com sucesso!</h1>
          <p className="text-muted-foreground mb-4">Redirecionando para o app...</p>
          <Loader2 className="w-6 h-6 animate-spin mx-auto text-primary" />
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background text-foreground py-8 px-4">
      <div className="max-w-md mx-auto">

        {/* Success Header */}
        <div className="text-center mb-8">
          <div className="w-20 h-20 mx-auto mb-6 rounded-full bg-green-500/20 flex items-center justify-center">
            <Check className="w-10 h-10 text-green-500" />
          </div>
          <h1 className="text-2xl font-bold mb-2">Parabens! Inscricao realizada!</h1>
          <p className="text-muted-foreground">Seu teste gratis de 1 dia comecou.</p>
        </div>

        {/* Password Setup Form */}
        <div className="bg-zinc-900/80 border border-zinc-600/50 rounded-2xl p-6 mb-6">
          <h2 className="text-lg font-semibold mb-2">Crie sua senha de acesso</h2>
          <p className="text-sm text-muted-foreground mb-6">
            Defina uma senha para acessar o Desenrola AI
          </p>

          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label className="block text-sm text-muted-foreground mb-2">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="seu@email.com"
                className="w-full bg-zinc-800 border border-zinc-600 px-4 py-3 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:border-primary"
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm text-muted-foreground mb-2">Senha</label>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Minimo 6 caracteres"
                  className="w-full bg-zinc-800 border border-zinc-600 px-4 py-3 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:border-primary pr-12"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-white"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
            </div>

            <div className="mb-6">
              <label className="block text-sm text-muted-foreground mb-2">Confirmar senha</label>
              <input
                type={showPassword ? "text" : "password"}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Repita a senha"
                className="w-full bg-zinc-800 border border-zinc-600 px-4 py-3 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:border-primary"
              />
            </div>

            {error && (
              <p className="text-red-500 text-sm mb-4">{error}</p>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full cta-gradient py-4 rounded-lg font-bold text-white flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {loading ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Salvando...
                </>
              ) : (
                <>
                  Criar senha e acessar
                  <ArrowRight className="w-5 h-5" />
                </>
              )}
            </button>
          </form>
        </div>

        {/* Skip Option */}
        <button
          onClick={handleSkip}
          className="w-full text-center text-sm text-muted-foreground hover:text-white transition-colors"
        >
          Pular e definir senha depois
        </button>

        <p className="text-center text-xs text-muted-foreground mt-6">
          Voce pode definir sua senha depois acessando o app e clicando em "Esqueci minha senha"
        </p>
      </div>
    </div>
  )
}
