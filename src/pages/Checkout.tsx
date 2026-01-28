import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Check, Shield, Zap, Unlock } from 'lucide-react'

const plans = [
  {
    id: 'mensal',
    name: 'Mensal',
    price: '29,90',
    period: '/mês',
    equivalent: 'R$ 29,90/mês',
    highlight: false
  },
  {
    id: 'trimestral',
    name: 'Trimestral',
    price: '69,90',
    period: '/trimestre',
    equivalent: 'R$ 23,30/mês',
    badge: 'MAIS POPULAR',
    discount: '22% OFF',
    highlight: true
  },
  {
    id: 'anual',
    name: 'Anual',
    price: '199,90',
    period: '/ano',
    equivalent: 'R$ 16,66/mês',
    badge: 'MELHOR VALOR',
    discount: '44% OFF',
    highlight: false
  }
]

const features = [
  'Acesso completo ao Desenrola AI',
  'Respostas ilimitadas',
  'Análise de contexto avançada',
  'Suporte prioritário',
  'Atualizações gratuitas'
]

export default function Checkout() {
  const [selectedPlan, setSelectedPlan] = useState('trimestral')
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    // Simula processamento
    await new Promise(resolve => setTimeout(resolve, 1500))

    // Aqui você redirecionaria para o checkout real (Stripe, etc)
    alert('Redirecionando para pagamento...')
    setLoading(false)
  }

  return (
    <div className="min-h-screen bg-background py-8 px-4">
      <div className="max-w-md mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-8"
        >
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-purple-500 to-pink-500
                         flex items-center justify-center mx-auto mb-4">
            <Unlock className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white mb-2">Acesso Liberado</h1>
          <p className="text-white/60">Você completou a jornada. Agora é sua vez.</p>
        </motion.div>

        {/* Garantia */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="flex items-center justify-center gap-2 mb-6"
        >
          <Shield className="w-5 h-5 text-green-500" />
          <span className="text-green-500 font-medium">Garantia de 7 dias ou seu dinheiro de volta</span>
        </motion.div>

        {/* Planos */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="space-y-3 mb-6"
        >
          {plans.map((plan) => (
            <div
              key={plan.id}
              onClick={() => setSelectedPlan(plan.id)}
              className={`relative rounded-xl cursor-pointer transition-all ${
                selectedPlan === plan.id
                  ? 'ring-2 ring-purple-500 bg-purple-500/10'
                  : 'bg-white/5 hover:bg-white/10'
              }`}
            >
              {plan.badge && (
                <div className="absolute -top-2 left-4 bg-gradient-to-r from-purple-500 to-pink-500
                               text-white text-xs font-bold px-3 py-1 rounded-full">
                  {plan.badge}
                </div>
              )}

              <div className="p-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                    selectedPlan === plan.id
                      ? 'border-purple-500 bg-purple-500'
                      : 'border-white/30'
                  }`}>
                    {selectedPlan === plan.id && (
                      <div className="w-2 h-2 bg-white rounded-full" />
                    )}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-white font-medium">{plan.name}</span>
                      {plan.discount && (
                        <span className="bg-pink-500 text-white text-xs px-2 py-0.5 rounded">
                          {plan.discount}
                        </span>
                      )}
                    </div>
                    <span className="text-white/50 text-sm">{plan.equivalent}</span>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-xl font-bold text-white">R$ {plan.price}</span>
                  <span className="text-white/50 text-sm">{plan.period}</span>
                </div>
              </div>
            </div>
          ))}
        </motion.div>

        {/* Formulário */}
        <motion.form
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          onSubmit={handleSubmit}
          className="bg-white/5 rounded-xl p-6 mb-6"
        >
          <h3 className="text-white font-semibold flex items-center gap-2 mb-4">
            <Zap className="w-5 h-5 text-purple-500" />
            Ative seu acesso
          </h3>

          <div className="space-y-4">
            <div>
              <label className="block text-white/60 text-sm mb-1">Nome completo</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Seu nome"
                className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3
                         text-white placeholder-white/30 focus:outline-none focus:border-purple-500"
                required
              />
            </div>
            <div>
              <label className="block text-white/60 text-sm mb-1">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="seu@email.com"
                className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3
                         text-white placeholder-white/30 focus:outline-none focus:border-purple-500"
                required
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full cta-gradient text-white font-bold py-4 rounded-lg
                       transition-all hover:opacity-90 disabled:opacity-50"
            >
              {loading ? 'Processando...' : 'CONTINUAR PARA PAGAMENTO'}
            </button>
          </div>
        </motion.form>

        {/* Features */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="bg-white/5 rounded-xl p-6 mb-6"
        >
          <h3 className="text-white font-semibold mb-4">O que você recebe:</h3>
          <ul className="space-y-3">
            {features.map((feature, index) => (
              <li key={index} className="flex items-center gap-3">
                <div className="w-5 h-5 rounded-full bg-green-500/20 flex items-center justify-center">
                  <Check className="w-3 h-3 text-green-500" />
                </div>
                <span className="text-white/80">{feature}</span>
              </li>
            ))}
          </ul>
        </motion.div>

        {/* Footer */}
        <div className="text-center">
          <div className="flex items-center justify-center gap-4 mb-4">
            <Shield className="w-4 h-4 text-green-500" />
            <span className="text-white/50 text-sm">Pagamento 100% seguro</span>
          </div>
          <p className="text-white/30 text-xs">
            Ao continuar, você concorda com nossos termos de uso.
            Garantia de 7 dias - não gostou? Devolvemos 100%.
          </p>
        </div>
      </div>
    </div>
  )
}
