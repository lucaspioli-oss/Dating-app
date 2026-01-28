import { useEffect } from "react"
import { Link } from "wouter"
import { motion } from "framer-motion"
import { Zap, MessageCircle, Heart, Sparkles, Users, Star, Shield, ArrowRight, CheckCircle } from "lucide-react"
import { trackViewContent } from "@/lib/tracking"
import ChatDemo from "@/components/ChatDemo"

const features = [
  { icon: Zap, title: "Confianza Inmediata", desc: "Siempre ten la respuesta correcta", color: "text-yellow-400" },
  { icon: MessageCircle, title: "Estrategias Ganadoras", desc: "La IA guía tus interacciones", color: "text-primary" },
  { icon: Heart, title: "Conexiones Auténticas", desc: "Relaciones verdaderas", color: "text-pink-400" },
  { icon: Sparkles, title: "Tu Estilo, Tu IA", desc: "Adaptada a ti", color: "text-green-400" },
]

const stats = [
  { icon: Users, value: "10K+", label: "Usuarios", color: "text-primary" },
  { icon: Star, value: "98%", label: "Aprobación", color: "text-yellow-400" },
  { icon: Shield, value: "7 Días", label: "Garantía", color: "text-green-400" },
]

const testimonials = [
  { text: "Conseguí mi primera cita en 3 días usando los consejos de la IA. ¡Impresionante!", name: "Carlos", age: 26, avatar: null, proof: null },
  { text: "Ya nunca me quedo sin saber qué responder. La IA entiende exactamente el contexto.", name: "Miguel", age: 24, avatar: null, proof: null },
  { text: "¡Desenrola AI es increíble, todavía no puedo creerlo!", name: "Andrés", age: 21, avatar: null, proof: "/emily_1.jpeg" },
]

export default function LandingES() {
  useEffect(() => {
    window.scrollTo(0, 0)
    trackViewContent('landing_es')
  }, [])

  return (
    <div className="min-h-screen bg-background" style={{ overflowX: 'hidden', width: '100%', maxWidth: '100vw' }}>
      <div style={{ width: '100%', maxWidth: 448, margin: '0 auto', padding: '32px 16px', boxSizing: 'border-box' }}>

        {/* Header */}
        <header className="flex items-center justify-center" style={{ marginBottom: 40 }}>
          <h1 className="text-3xl font-bold gradient-text" style={{ fontFamily: 'var(--font-heading)', fontStyle: 'normal', textTransform: 'none', letterSpacing: '0.02em' }}>
            DESENROLA <span style={{ marginLeft: 4 }}>AI</span>
          </h1>
        </header>

        {/* Hero Section */}
        <section className="text-center" style={{ marginBottom: 40 }}>
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-2xl md:text-3xl font-bold leading-tight"
            style={{ fontFamily: 'var(--font-heading)', fontStyle: 'italic', marginBottom: 16 }}
          >
            Desbloquea Tus Conversaciones:{" "}
            <span className="gradient-text">La IA que te da la Respuesta Perfecta, Al Instante.</span>
          </motion.h2>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="text-muted-foreground leading-relaxed"
          >
            Basta de incertidumbres. Mira Desenrola AI en acción y{" "}
            <span className="text-primary font-medium">personalízalo para tu estilo único</span>.
            Empieza a dominar cualquier interacción.
          </motion.p>
        </section>

        {/* Chat Demo Section */}
        <motion.section
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          style={{ marginBottom: 40 }}
        >
          <div className="text-center" style={{ marginBottom: 20 }}>
            <p className="text-base text-white font-semibold" style={{ marginBottom: 4 }}>
              Mira Desenrola AI en Acción
            </p>
            <p className="text-sm">
              <span className="gradient-text font-bold">Resultado Real de un Usuario</span>
            </p>
          </div>

          <div className="relative">
            <ChatDemo />
          </div>
        </motion.section>

        {/* Content below ChatDemo */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: "easeOut", delay: 0.4 }}
        >
              {/* CTA Section */}
              <motion.section
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                style={{ marginBottom: 40 }}
              >
                <p className="text-center text-sm text-muted-foreground" style={{ marginBottom: 12 }}>
                  Nuestra IA analiza el contexto y genera la respuesta perfecta.{" "}
                  <span className="text-primary">Ahora, personalízala para tu estilo.</span>
                </p>

                <Link href="/es/quiz" className="flex justify-center">
                  <button
                    className="cta-gradient text-white font-bold rounded-xl flex items-center justify-center gap-3 transition-all duration-300 hover:scale-[1.02] hover:shadow-lg hover:shadow-primary/25 cursor-pointer"
                    style={{ padding: '18px 32px', width: '100%', maxWidth: 340 }}
                  >
                    <span className="uppercase tracking-wide text-sm">Empezar a Personalizar Mi IA</span>
                    <ArrowRight className="w-5 h-5" />
                  </button>
                </Link>
                <p className="text-center text-xs text-muted-foreground" style={{ marginTop: 8 }}>Gratis • Menos de 2 minutos</p>
              </motion.section>

              {/* Features Grid */}
              <motion.section
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="grid grid-cols-2 gap-3"
                style={{ marginBottom: 40 }}
              >
                {features.map((f, i) => (
                  <div
                    key={i}
                    className="rounded-xl"
                    style={{
                      background: 'rgba(30, 30, 40, 0.8)',
                      border: '1px solid rgba(255, 255, 255, 0.1)',
                      padding: 16
                    }}
                  >
                    <div
                      className={`rounded-xl ${f.color}`}
                      style={{
                        background: 'rgba(20, 20, 30, 0.8)',
                        marginBottom: 8,
                        width: 40,
                        height: 40,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center'
                      }}
                    >
                      <f.icon className="w-5 h-5" />
                    </div>
                    <h3 className="font-semibold text-sm uppercase tracking-wide text-white" style={{ fontFamily: 'var(--font-heading)', fontStyle: 'italic', marginBottom: 4 }}>{f.title}</h3>
                    <p className="text-xs text-white/50">{f.desc}</p>
                  </div>
                ))}
              </motion.section>

              {/* Stats Section */}
              <motion.section
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
                className="flex justify-between items-center rounded-2xl"
                style={{
                  background: 'rgba(30, 30, 40, 0.8)',
                  border: '1px solid rgba(255, 255, 255, 0.1)',
                  padding: 20,
                  marginBottom: 40
                }}
              >
                {stats.map((s, i) => (
                  <div key={i} className="text-center flex-1">
                    <div className="flex items-center justify-center gap-1.5" style={{ marginBottom: 4 }}>
                      <s.icon className={`w-4 h-4 ${s.color}`} />
                      <span className={`text-xl font-bold ${s.color}`} style={{ fontFamily: 'var(--font-heading)' }}>{s.value}</span>
                    </div>
                    <p className="text-xs text-white/50 uppercase tracking-wider">{s.label}</p>
                  </div>
                ))}
              </motion.section>

              {/* Testimonials Section */}
              <motion.section
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                style={{ marginBottom: 40 }}
              >
                {testimonials.map((t, i) => (
                  <div
                    key={i}
                    className="rounded-xl"
                    style={{
                      background: 'rgba(30, 30, 40, 0.8)',
                      border: '1px solid rgba(255, 255, 255, 0.1)',
                      padding: 16,
                      marginBottom: i < testimonials.length - 1 ? 16 : 0
                    }}
                  >
                    <div className="flex items-center gap-3" style={{ marginBottom: 12 }}>
                      {t.avatar ? (
                        <img src={t.avatar} alt={t.name} className="w-10 h-10 rounded-full object-cover" />
                      ) : (
                        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center">
                          <span className="text-white text-sm font-bold">{t.name[0]}</span>
                        </div>
                      )}
                      <div>
                        <p className="text-sm text-white font-semibold">{t.name}, {t.age} años</p>
                        <div className="flex gap-0.5">
                          {[...Array(5)].map((_, j) => (
                            <Star key={j} className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                          ))}
                        </div>
                      </div>
                    </div>
                    <p className="text-sm text-white/90" style={{ marginBottom: t.proof ? 12 : 0 }}>"{t.text}"</p>
                    {t.proof && (
                      <div style={{ marginTop: 12, display: 'flex', justifyContent: 'center' }}>
                        <img
                          src={t.proof}
                          alt="Resultado"
                          className="rounded-lg"
                          style={{ width: '50%', height: 'auto', objectFit: 'contain' }}
                        />
                      </div>
                    )}
                  </div>
                ))}
              </motion.section>

              {/* Final CTA Section */}
              <motion.section
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
                className="rounded-2xl text-center"
                style={{
                  background: 'linear-gradient(135deg, rgba(168, 85, 247, 0.15), rgba(236, 72, 153, 0.15))',
                  border: '1px solid rgba(168, 85, 247, 0.3)',
                  padding: 24
                }}
              >
                <div
                  className="w-12 h-12 mx-auto rounded-full flex items-center justify-center"
                  style={{ background: 'rgba(168, 85, 247, 0.2)', marginBottom: 16 }}
                >
                  <CheckCircle className="w-6 h-6 text-primary" />
                </div>
                <h3 className="text-xl font-bold uppercase tracking-wide text-white" style={{ fontFamily: 'var(--font-heading)', fontStyle: 'italic', marginBottom: 12 }}>
                  Personaliza Tu IA en 2 Minutos
                </h3>
                <p className="text-sm text-white/60 leading-relaxed" style={{ marginBottom: 16 }}>
                  Para que Desenrola AI sea tu compañero ideal, necesita conocerte.
                  Responde algunas preguntas rápidas y ten una IA hecha a tu medida.
                </p>
                <Link href="/es/quiz">
                  <span className="inline-flex items-center gap-2 text-primary font-semibold hover:underline cursor-pointer">
                    <span>Descubrir Mi Perfil de Conversación</span>
                    <ArrowRight className="w-4 h-4" />
                  </span>
                </Link>
              </motion.section>

          {/* Footer */}
          <footer className="text-center text-xs text-muted-foreground" style={{ marginTop: 40, paddingBottom: 24 }}>
            play.desenrolaai.site — Privado
          </footer>
        </motion.div>
      </div>
    </div>
  )
}
