const fs = require("fs");
const content = `import { useEffect, useState } from "react"
import { useQuizStore } from "@/lib/store"
import { Check, Shield, Zap, Star } from "lucide-react"

export default function Sales() {
  const { matchedProfile } = useQuizStore()
  const [selectedPlan, setSelectedPlan] = useState("trimestral")

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [])

  const features = [
    "Acesso completo ao Desenrola AI",
    "Plano personalizado para seu perfil",
    "Atualizacoes e novos conteudos",
    "Suporte prioritario",
    "Garantia de 7 dias"
  ]

  const plans = [
    { id: "mensal", name: "Mensal", price: "19,90", period: "/mes", equivalent: "Equivale a R$19,90/mes" },
    { id: "trimestral", name: "Trimestral", price: "29,90", originalPrice: "59,70", period: "/trimestre", equivalent: "Equivale a R$9,97/mes", badge: "MAIS POPULAR", badgeBottom: "MELHOR VALOR", highlight: true, discount: "50% OFF" },
    { id: "anual", name: "Anual", price: "197,90", period: "/ano", equivalent: "Equivale a R$16,49/mes", badge: "17% OFF" }
  ]

  return (
    <div className="min-h-screen bg-background text-foreground py-8 px-4">
      <div className="max-w-md mx-auto">
        <div className="text-center" style={{ marginBottom: 32 }}>
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-primary/30" style={{ backgroundColor: "rgba(168, 85, 247, 0.1)", marginBottom: 24 }}>
            <Zap className="w-4 h-4 text-primary" />
            <span className="text-sm font-bold text-primary">Oferta Especial</span>
          </div>
          <h1 className="text-2xl font-bold" style={{ marginBottom: 8 }}>Desbloqueie o <span className="gradient-text">Desenrola AI</span></h1>
          {matchedProfile && (<p className="text-sm text-muted-foreground">Estrategias personalizadas para o perfil <span className="text-primary font-semibold">{matchedProfile.name}</span></p>)}
        </div>
        <div style={{ marginBottom: 32 }}>
          {plans.map((plan) => (
            <div key={plan.id} onClick={() => setSelectedPlan(plan.id)} className="cursor-pointer transition-all duration-300" style={{ marginBottom: 16, padding: plan.highlight ? 3 : 0, background: plan.highlight ? "linear-gradient(135deg, hsl(280 100% 65%), hsl(320 100% 60%))" : "transparent", borderRadius: 16 }}>
              <div className={plan.highlight ? "bg-zinc-900" : "bg-zinc-900/60 border border-zinc-700/50"} style={{ borderRadius: plan.highlight ? 13 : 16, padding: "20px 24px", position: "relative" }}>
                {plan.badge && (<div style={{ position: "absolute", top: -12, right: 16, backgroundColor: plan.highlight ? "hsl(280 100% 65%)" : "hsl(320 100% 60%)", color: "white", fontSize: 10, fontWeight: 700, padding: "4px 12px", borderRadius: 20 }}>{plan.badge}</div>)}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div style={{ width: 20, height: 20, borderRadius: "50%", border: selectedPlan === plan.id ? "2px solid hsl(280 100% 65%)" : "2px solid #555", display: "flex", alignItems: "center", justifyContent: "center" }}>
                      {selectedPlan === plan.id && (<div style={{ width: 10, height: 10, borderRadius: "50%", backgroundColor: "hsl(280 100% 65%)" }} />)}
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
                    {plan.originalPrice && (<span className="text-sm text-muted-foreground line-through" style={{ marginRight: 8 }}>R${plan.originalPrice}</span>)}
                    <span className="text-xl font-bold text-white">R$ {plan.price}</span>
                    <span className="text-sm text-muted-foreground">{plan.period}</span>
                  </div>
                </div>
                {plan.badgeBottom && (<div style={{ marginTop: 12, backgroundColor: "rgba(168, 85, 247, 0.2)", color: "hsl(280 100% 70%)", fontSize: 11, fontWeight: 700, padding: "6px 0", borderRadius: 8, textAlign: "center" }}>{plan.badgeBottom}</div>)}
              </div>
            </div>
          ))}
        </div>
        <div className="bg-zinc-900/60 border border-zinc-700/50" style={{ borderRadius: 16, padding: 24, marginBottom: 32 }}>
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
        <a href="https://pay.hotmart.com/SEU_LINK" target="_blank" rel="noopener noreferrer" className="block" style={{ marginBottom: 24 }}>
          <button className="w-full cta-gradient rounded-xl transition-all duration-300 hover:scale-[1.02] active:scale-[0.98] cursor-pointer" style={{ padding: "18px 24px" }}>
            <span className="uppercase tracking-wide font-bold text-white">Comecar Agora</span>
          </button>
        </a>
        <div className="flex items-center justify-center gap-2 text-muted-foreground text-xs" style={{ marginBottom: 24 }}>
          <Shield className="w-4 h-4" />
          <span>Pagamento 100% seguro</span>
        </div>
        <div className="bg-zinc-900/40 border border-zinc-700/30" style={{ borderRadius: 12, padding: 16, marginBottom: 24 }}>
          <div className="flex items-center gap-2" style={{ marginBottom: 8 }}>
            <div className="flex text-yellow-400">{[...Array(5)].map((_, i) => (<Star key={i} className="w-4 h-4 fill-current" />))}</div>
            <span className="text-xs text-muted-foreground">4.9 (2.847 avaliacoes)</span>
          </div>
          <p className="text-sm text-white/70 italic">"Depois do Desenrola, consegui finalmente ter conversas naturais e marquei varios encontros!"</p>
          <p className="text-xs text-muted-foreground" style={{ marginTop: 8 }}>- Lucas, 28 anos</p>
        </div>
        <p className="text-center text-xs text-muted-foreground">Garantia incondicional de 7 dias. Se nao gostar, devolvemos seu dinheiro.</p>
      </div>
    </div>
  )
}
`;
fs.writeFileSync("src/pages/Sales.tsx", content);
console.log("done");
