import { Resend } from 'resend';

const resend = new Resend('re_EPWCVHjs_Fu2QZ6RRiSQozVaYFBsAcq44');

// Templates de email para recuperação de leads
const emailTemplates = {
  // Email 1 - Enviado 30 min após abandono
  immediate: {
    subject: 'Esqueceu algo? Seu teste gratis esta esperando',
    html: (name: string, plan: string) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0D0D1A; color: #fff; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .logo { text-align: center; margin-bottom: 30px; }
    .logo h1 { color: #E91E63; margin: 0; font-size: 28px; }
    .content { background: #1A1A2E; border-radius: 16px; padding: 30px; }
    h2 { color: #fff; margin-top: 0; }
    p { color: #aaa; line-height: 1.6; }
    .cta { display: inline-block; background: linear-gradient(135deg, #E91E63, #FF5722); color: #fff; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: bold; margin: 20px 0; }
    .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <h1>Desenrola AI</h1>
    </div>
    <div class="content">
      <h2>Opa${name ? `, ${name}` : ''}! Voce esqueceu algo...</h2>
      <p>Notamos que voce estava quase comecando seu <strong>teste gratuito</strong> do plano ${plan}, mas nao finalizou.</p>
      <p>Sem problemas! Seu carrinho ainda esta salvo e voce pode continuar de onde parou.</p>
      <p>Lembre-se: voce tera <strong>1 dia gratis</strong> para testar todas as funcionalidades antes de qualquer cobranca.</p>
      <center>
        <a href="https://funis-desenrola.web.app/checkout-${plan.toLowerCase()}" class="cta">Continuar meu teste gratis</a>
      </center>
      <p style="color: #666; font-size: 13px;">Se tiver alguma duvida, e so responder este email!</p>
    </div>
    <div class="footer">
      <p>Desenrola AI - Sua IA de conversas</p>
    </div>
  </div>
</body>
</html>
    `,
  },

  // Email 2 - Enviado 24h após abandono
  followUp24h: {
    subject: 'O que voce esta perdendo...',
    html: (name: string, plan: string) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0D0D1A; color: #fff; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .logo { text-align: center; margin-bottom: 30px; }
    .logo h1 { color: #E91E63; margin: 0; font-size: 28px; }
    .content { background: #1A1A2E; border-radius: 16px; padding: 30px; }
    h2 { color: #fff; margin-top: 0; }
    p { color: #aaa; line-height: 1.6; }
    .benefit { background: #2A2A3E; border-radius: 8px; padding: 12px 16px; margin: 10px 0; display: flex; align-items: center; }
    .benefit-icon { font-size: 24px; margin-right: 12px; }
    .benefit-text { color: #fff; }
    .cta { display: inline-block; background: linear-gradient(135deg, #E91E63, #FF5722); color: #fff; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: bold; margin: 20px 0; }
    .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <h1>Desenrola AI</h1>
    </div>
    <div class="content">
      <h2>${name ? `${name}, v` : 'V'}eja o que voce esta perdendo...</h2>
      <p>Enquanto voce pensa, outros usuarios ja estao:</p>

      <div class="benefit">
        <span class="benefit-icon">💬</span>
        <span class="benefit-text">Gerando mensagens que realmente funcionam</span>
      </div>
      <div class="benefit">
        <span class="benefit-icon">🔥</span>
        <span class="benefit-text">Transformando matches em encontros reais</span>
      </div>
      <div class="benefit">
        <span class="benefit-icon">🎯</span>
        <span class="benefit-text">Saindo da friendzone com estrategias certeiras</span>
      </div>
      <div class="benefit">
        <span class="benefit-icon">⚡</span>
        <span class="benefit-text">Economizando horas pensando no que responder</span>
      </div>

      <p>E o melhor: voce pode testar <strong>gratis por 1 dia</strong> antes de decidir!</p>

      <center>
        <a href="https://funis-desenrola.web.app/checkout-${plan.toLowerCase()}" class="cta">Quero comecar agora</a>
      </center>
    </div>
    <div class="footer">
      <p>Desenrola AI - Sua IA de conversas</p>
    </div>
  </div>
</body>
</html>
    `,
  },

  // Email 3 - Enviado 48-72h após abandono (com desconto)
  lastChance: {
    subject: 'Ultima chance: 20% OFF so para voce',
    html: (name: string, plan: string) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0D0D1A; color: #fff; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .logo { text-align: center; margin-bottom: 30px; }
    .logo h1 { color: #E91E63; margin: 0; font-size: 28px; }
    .content { background: #1A1A2E; border-radius: 16px; padding: 30px; }
    h2 { color: #fff; margin-top: 0; }
    p { color: #aaa; line-height: 1.6; }
    .discount-box { background: linear-gradient(135deg, #E91E63, #FF5722); border-radius: 12px; padding: 20px; text-align: center; margin: 20px 0; }
    .discount-box h3 { color: #fff; margin: 0 0 5px 0; font-size: 32px; }
    .discount-box p { color: rgba(255,255,255,0.9); margin: 0; }
    .cta { display: inline-block; background: #fff; color: #E91E63; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: bold; margin: 20px 0; }
    .timer { color: #FF5722; font-weight: bold; }
    .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <h1>Desenrola AI</h1>
    </div>
    <div class="content">
      <h2>${name ? `${name}, ` : ''}esta e sua ultima chance!</h2>
      <p>Sabemos que as vezes a gente precisa de um empurraozinho. Por isso, preparamos algo especial:</p>

      <div class="discount-box">
        <h3>20% OFF</h3>
        <p>Use o cupom: <strong>DESENROLA20</strong></p>
      </div>

      <p>Essa oferta e <span class="timer">exclusiva e expira em 24 horas</span>.</p>
      <p>Alem do desconto, voce ainda tem <strong>1 dia gratis</strong> para testar!</p>

      <center>
        <a href="https://funis-desenrola.web.app/checkout-${plan.toLowerCase()}?cupom=DESENROLA20" class="cta">Usar meu cupom agora</a>
      </center>

      <p style="color: #666; font-size: 13px;">Depois dessa oferta, so no proximo mes...</p>
    </div>
    <div class="footer">
      <p>Desenrola AI - Sua IA de conversas</p>
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
  const { to, template, name = '', plan = 'mensal' } = params;

  try {
    const templateData = emailTemplates[template];

    const { data, error } = await resend.emails.send({
      from: 'Desenrola AI <onboarding@resend.dev>', // Mudar para seu domínio depois
      to: [to],
      subject: templateData.subject,
      html: templateData.html(name, plan),
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
