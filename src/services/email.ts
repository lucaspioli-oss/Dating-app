import { Resend } from 'resend';

const resend = new Resend('re_EPWCVHjs_Fu2QZ6RRiSQozVaYFBsAcq44');

// Templates de email para recuperação de leads
const emailTemplates = {
  // Email de boas-vindas após compra
  welcome: {
    subject: (name: string) => name ? `${name}, sua conta Desenrola AI esta pronta! 🎉` : 'Sua conta Desenrola AI esta pronta! 🎉',
    html: (name: string, plan: string, extra?: string) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0D0D1A; color: #fff; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .logo { text-align: center; margin-bottom: 30px; }
    .logo h1 { color: #E91E63; margin: 0; font-size: 28px; }
    .content { background: #1A1A2E; border-radius: 16px; padding: 30px; }
    h2 { color: #fff; margin-top: 0; font-size: 22px; }
    p { color: #bbb; line-height: 1.7; font-size: 15px; }
    .highlight { color: #E91E63; font-weight: bold; }
    .success-badge { background: linear-gradient(135deg, #E91E63, #C2185B); border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0; }
    .success-badge h3 { color: #fff; margin: 0; font-size: 20px; }
    .success-badge p { color: rgba(255,255,255,0.9); margin: 8px 0 0 0; font-size: 14px; }
    .steps { margin: 24px 0; }
    .step { display: flex; align-items: flex-start; margin: 16px 0; }
    .step-number { background: #E91E63; color: #fff; width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; margin-right: 12px; flex-shrink: 0; }
    .step-text { color: #ddd; }
    .cta { display: inline-block; background: linear-gradient(135deg, #E91E63, #FF5722); color: #fff; text-decoration: none; padding: 16px 40px; border-radius: 8px; font-weight: bold; margin: 24px 0; font-size: 16px; }
    .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
    .help-text { font-size: 13px; color: #888; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <h1>Desenrola AI</h1>
    </div>
    <div class="content">
      <h2>${name ? `Parabens ${name}!` : 'Parabens!'} Voce tomou a melhor decisao 🚀</h2>

      <div class="success-badge">
        <h3>✅ Plano Ativado</h3>
        <p>Seu acesso foi liberado com sucesso</p>
      </div>

      <p>Agora e so criar sua senha e comecar a usar o <span class="highlight">Desenrola AI</span> para nunca mais travar nas conversas!</p>

      <div class="steps">
        <div class="step">
          <span class="step-number">1</span>
          <span class="step-text">Clique no botao abaixo para criar sua senha</span>
        </div>
        <div class="step">
          <span class="step-number">2</span>
          <span class="step-text">Acesse <strong>app.desenrolaai.site</strong></span>
        </div>
        <div class="step">
          <span class="step-number">3</span>
          <span class="step-text">Faca login com seu email e senha</span>
        </div>
        <div class="step">
          <span class="step-number">4</span>
          <span class="step-text">Comece a usar e nunca mais trave!</span>
        </div>
      </div>

      <center>
        <a href="${extra || 'https://app.desenrolaai.site/success'}" class="cta">CRIAR MINHA SENHA</a>
      </center>

      <p class="help-text">Se tiver qualquer duvida, responda esse email que te ajudamos!</p>
    </div>
    <div class="footer">
      <p>Desenrola AI - Nunca mais trave numa conversa</p>
    </div>
  </div>
</body>
</html>
    `,
  },

  // Email 1 - Enviado imediatamente após abandono
  // Foco: Lembrete amigável + reforçar que é grátis testar
  immediate: {
    subject: (name: string) => name ? `${name}, sua conversa travou? A gente resolve` : 'Sua conversa travou? A gente resolve',
    html: (name: string, plan: string) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0D0D1A; color: #fff; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .logo { text-align: center; margin-bottom: 30px; }
    .logo h1 { color: #E91E63; margin: 0; font-size: 28px; }
    .content { background: #1A1A2E; border-radius: 16px; padding: 30px; }
    h2 { color: #fff; margin-top: 0; font-size: 22px; }
    p { color: #bbb; line-height: 1.7; font-size: 15px; }
    .highlight { color: #E91E63; font-weight: bold; }
    .cta { display: inline-block; background: linear-gradient(135deg, #E91E63, #FF5722); color: #fff; text-decoration: none; padding: 16px 40px; border-radius: 8px; font-weight: bold; margin: 24px 0; font-size: 16px; }
    .cta:hover { opacity: 0.9; }
    .guarantee { background: #2A2A3E; border-radius: 8px; padding: 16px; margin: 20px 0; text-align: center; }
    .guarantee-text { color: #4CAF50; font-weight: bold; margin: 0; }
    .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
    .ps { font-size: 13px; color: #888; font-style: italic; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <h1>Desenrola AI</h1>
    </div>
    <div class="content">
      <h2>${name ? `E ai ${name}!` : 'E ai!'} Tudo certo?</h2>

      <p>Vi que voce estava prestes a testar o Desenrola AI, mas algo te impediu de finalizar.</p>

      <p>Sei como e... as vezes a gente ta conversando com alguem e <span class="highlight">trava na hora de responder</span>. Fica pensando "o que eu falo agora?" e quando ve, ja passou tempo demais.</p>

      <p>Foi exatamente pra isso que criamos o Desenrola AI. Em segundos voce tem <span class="highlight">3 opcoes de resposta</span> perfeitas pro momento.</p>

      <div class="guarantee">
        <p class="guarantee-text">🎁 TESTE GRATIS POR 24 HORAS</p>
        <p style="margin: 8px 0 0 0; color: #aaa; font-size: 13px;">Sem compromisso. Cancela quando quiser.</p>
      </div>

      <center>
        <a href="https://funis-desenrola.web.app/checkout/${plan.toLowerCase()}" class="cta">Quero testar gratis agora</a>
      </center>

      <p class="ps">PS: Mais de 2.000 caras ja usaram essa semana. Nao fica pra tras nao.</p>
    </div>
    <div class="footer">
      <p>Desenrola AI - Nunca mais trave numa conversa</p>
      <p style="margin-top: 8px;"><a href="#" style="color: #666;">Cancelar inscricao</a></p>
    </div>
  </div>
</body>
</html>
    `,
  },

  // Email 2 - Enviado 24h após abandono
  // Foco: Mostrar a DOR de não ter + prova social
  followUp24h: {
    subject: (name: string) => name ? `${name}, ela respondeu... e agora? 🤔` : 'Ela respondeu... e agora? 🤔',
    html: (name: string, plan: string) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0D0D1A; color: #fff; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .logo { text-align: center; margin-bottom: 30px; }
    .logo h1 { color: #E91E63; margin: 0; font-size: 28px; }
    .content { background: #1A1A2E; border-radius: 16px; padding: 30px; }
    h2 { color: #fff; margin-top: 0; font-size: 22px; }
    p { color: #bbb; line-height: 1.7; font-size: 15px; }
    .highlight { color: #E91E63; font-weight: bold; }
    .scenario { background: #2A2A3E; border-left: 4px solid #E91E63; padding: 16px; margin: 20px 0; border-radius: 0 8px 8px 0; }
    .scenario p { margin: 0; color: #ddd; }
    .vs { text-align: center; color: #666; font-size: 13px; margin: 16px 0; }
    .win { background: #2A2A3E; border-left: 4px solid #4CAF50; padding: 16px; margin: 20px 0; border-radius: 0 8px 8px 0; }
    .win p { margin: 0; color: #ddd; }
    .testimonial { background: #2A2A3E; border-radius: 12px; padding: 20px; margin: 24px 0; }
    .testimonial-text { color: #fff; font-style: italic; margin: 0 0 12px 0; }
    .testimonial-author { color: #888; font-size: 13px; margin: 0; }
    .cta { display: inline-block; background: linear-gradient(135deg, #E91E63, #FF5722); color: #fff; text-decoration: none; padding: 16px 40px; border-radius: 8px; font-weight: bold; margin: 24px 0; font-size: 16px; }
    .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <h1>Desenrola AI</h1>
    </div>
    <div class="content">
      <h2>${name ? `${name}, ` : ''}ja passou por isso?</h2>

      <div class="scenario">
        <p>😰 Ela manda uma mensagem...</p>
        <p>Voce le, pensa "preciso responder bem"...</p>
        <p>Passa 1 hora. Passa 2 horas.</p>
        <p>Quando responde, ela ja esfriou.</p>
      </div>

      <div class="vs">- - - ou - - -</div>

      <div class="win">
        <p>😎 Ela manda uma mensagem...</p>
        <p>Voce abre o Desenrola, cola a mensagem.</p>
        <p>Em 10 segundos tem 3 respostas perfeitas.</p>
        <p>Responde rapido. Ela continua engajada.</p>
      </div>

      <p>A diferenca entre <span class="highlight">"ficou no vacuo"</span> e <span class="highlight">"marcou o date"</span> muitas vezes e so o tempo de resposta e a qualidade da mensagem.</p>

      <div class="testimonial">
        <p class="testimonial-text">"Cara, eu travava MUITO nas conversas. Agora respondo em segundos e a qualidade das minhas mensagens melhorou absurdamente. Ja marquei 3 encontros esse mes."</p>
        <p class="testimonial-author">- Pedro, 26 anos, Sao Paulo</p>
      </div>

      <center>
        <a href="https://funis-desenrola.web.app/checkout/${plan.toLowerCase()}" class="cta">Quero parar de travar</a>
      </center>

      <p style="text-align: center; color: #888; font-size: 13px;">Teste gratis por 24h. Sem cartao ate decidir.</p>
    </div>
    <div class="footer">
      <p>Desenrola AI - Nunca mais trave numa conversa</p>
      <p style="margin-top: 8px;"><a href="#" style="color: #666;">Cancelar inscricao</a></p>
    </div>
  </div>
</body>
</html>
    `,
  },

  // Email 3 - Enviado 48-72h após abandono (com desconto)
  // Foco: Urgência + escassez + desconto real
  lastChance: {
    subject: (name: string) => name ? `⚠️ ${name}, seu desconto de 30% expira em 24h` : '⚠️ Seu desconto de 30% expira em 24h',
    html: (name: string, plan: string) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0D0D1A; color: #fff; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .logo { text-align: center; margin-bottom: 30px; }
    .logo h1 { color: #E91E63; margin: 0; font-size: 28px; }
    .content { background: #1A1A2E; border-radius: 16px; padding: 30px; }
    h2 { color: #fff; margin-top: 0; font-size: 22px; }
    p { color: #bbb; line-height: 1.7; font-size: 15px; }
    .highlight { color: #E91E63; font-weight: bold; }
    .urgent { color: #FF5722; }
    .discount-box { background: linear-gradient(135deg, #E91E63, #FF5722); border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0; }
    .discount-box h3 { color: #fff; margin: 0; font-size: 36px; font-weight: bold; }
    .discount-box p { color: rgba(255,255,255,0.9); margin: 8px 0 0 0; font-size: 14px; }
    .coupon { background: rgba(255,255,255,0.2); display: inline-block; padding: 8px 20px; border-radius: 6px; margin-top: 12px; }
    .coupon code { color: #fff; font-size: 18px; font-weight: bold; letter-spacing: 2px; }
    .timer-box { background: #2A2A3E; border-radius: 8px; padding: 16px; margin: 20px 0; text-align: center; }
    .timer-box p { margin: 0; color: #FF5722; font-weight: bold; font-size: 14px; }
    .benefits { margin: 24px 0; }
    .benefit { display: flex; align-items: center; margin: 12px 0; }
    .benefit-check { color: #4CAF50; margin-right: 12px; font-size: 18px; }
    .benefit-text { color: #ddd; }
    .cta { display: inline-block; background: #fff; color: #E91E63; text-decoration: none; padding: 16px 40px; border-radius: 8px; font-weight: bold; margin: 24px 0; font-size: 16px; }
    .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
    .final-note { background: #2A2A3E; border-radius: 8px; padding: 16px; margin-top: 20px; }
    .final-note p { margin: 0; color: #aaa; font-size: 13px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <h1>Desenrola AI</h1>
    </div>
    <div class="content">
      <h2>${name ? `${name}, ` : ''}ultima chance (de verdade)</h2>

      <p>Olha, eu entendo. As vezes a gente precisa de um empurrao pra tomar uma decisao.</p>

      <p>Entao vou ser direto: preparei um <span class="highlight">desconto exclusivo</span> pra voce que ta em cima do muro. Mas ele <span class="urgent">expira em 24 horas</span>.</p>

      <div class="discount-box">
        <h3>30% OFF</h3>
        <p>No plano ${plan}</p>
        <div class="coupon">
          <code>DESENROLA30</code>
        </div>
      </div>

      <div class="timer-box">
        <p>⏰ Esse cupom expira em 24 horas e NAO volta</p>
      </div>

      <div class="benefits">
        <div class="benefit">
          <span class="benefit-check">✓</span>
          <span class="benefit-text">Respostas inteligentes em segundos</span>
        </div>
        <div class="benefit">
          <span class="benefit-check">✓</span>
          <span class="benefit-text">Funciona em Tinder, Bumble, Instagram, WhatsApp</span>
        </div>
        <div class="benefit">
          <span class="benefit-check">✓</span>
          <span class="benefit-text">IA treinada com milhares de conversas reais</span>
        </div>
        <div class="benefit">
          <span class="benefit-check">✓</span>
          <span class="benefit-text">Cancela quando quiser, sem burocracia</span>
        </div>
      </div>

      <center>
        <a href="https://funis-desenrola.web.app/checkout/${plan.toLowerCase()}?cupom=DESENROLA30" class="cta">USAR MEU CUPOM DE 30% OFF</a>
      </center>

      <div class="final-note">
        <p>🔒 Pagamento 100% seguro. Teste gratis por 24h incluso. Se nao gostar, cancela sem pagar nada.</p>
      </div>
    </div>
    <div class="footer">
      <p>Desenrola AI - Nunca mais trave numa conversa</p>
      <p style="margin-top: 8px;"><a href="#" style="color: #666;">Cancelar inscricao</a></p>
    </div>
  </div>
</body>
</html>
    `,
  },
};

export type EmailTemplate = keyof typeof emailTemplates;

export interface SendEmailParams {
  to: string;
  template: EmailTemplate;
  name?: string;
  plan?: string;
  extra?: string; // Used for welcome email link
}

export interface AbandonedLead {
  email: string;
  name?: string;
  plan: string;
  abandonedAt: Date;
  emailsSent: EmailTemplate[];
  lastEmailSentAt?: Date;
  converted: boolean;
  createdAt: Date;
}

/**
 * Enviar email usando template
 */
export async function sendEmail(params: SendEmailParams): Promise<{ success: boolean; error?: string }> {
  const { to, template, name = '', plan = 'mensal', extra } = params;

  try {
    const templateData = emailTemplates[template];

    const { data, error } = await resend.emails.send({
      from: 'Desenrola AI <contato@desenrolaai.site>',
      to: [to],
      subject: templateData.subject(name),
      html: templateData.html(name, plan, extra),
    });

    if (error) {
      console.error('❌ Erro ao enviar email:', error);
      return { success: false, error: error.message };
    }

    console.log('✅ Email enviado:', { to, template, id: data?.id });
    return { success: true };
  } catch (error: any) {
    console.error('❌ Erro ao enviar email:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Enviar email de boas-vindas após compra
 */
export async function sendWelcomeEmail(params: {
  to: string;
  name?: string;
  plan: string;
  successUrl?: string;
}): Promise<{ success: boolean; error?: string }> {
  const { to, name, plan, successUrl } = params;

  // URL padrão para criar senha - usa o email como parâmetro
  const defaultUrl = `https://app.desenrolaai.site/success?email=${encodeURIComponent(to)}`;

  return sendEmail({
    to,
    template: 'welcome',
    name: name || undefined,
    plan,
    extra: successUrl || defaultUrl,
  });
}

/**
 * Enviar email de teste
 */
export async function sendTestEmail(to: string): Promise<{ success: boolean; error?: string }> {
  return sendEmail({
    to,
    template: 'immediate',
    name: 'Teste',
    plan: 'Mensal',
  });
}

export { emailTemplates };
