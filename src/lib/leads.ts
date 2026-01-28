const API_URL = 'https://dating-app-production-ac43.up.railway.app';

/**
 * Salvar lead abandonado no backend
 * Chamado quando o usuário preenche email mas não finaliza a compra
 */
export async function saveAbandonedLead(
  email: string,
  plan: string,
  name?: string
): Promise<boolean> {
  try {
    const response = await fetch(`${API_URL}/abandoned-lead`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: email.toLowerCase().trim(),
        name: name?.trim() || undefined,
        plan,
      }),
    });

    if (response.ok) {
      console.log('Lead abandonado salvo:', email);
      return true;
    } else {
      console.error('Erro ao salvar lead:', await response.text());
      return false;
    }
  } catch (error) {
    console.error('Erro ao salvar lead abandonado:', error);
    return false;
  }
}

/**
 * Marcar lead como convertido
 * Chamado após compra bem-sucedida
 */
export async function markLeadConverted(email: string): Promise<boolean> {
  try {
    const response = await fetch(`${API_URL}/lead-converted`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: email.toLowerCase().trim(),
      }),
    });

    if (response.ok) {
      console.log('Lead marcado como convertido:', email);
      return true;
    }
    return false;
  } catch (error) {
    console.error('Erro ao marcar lead como convertido:', error);
    return false;
  }
}
