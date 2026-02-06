"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConversationImageAnalyzerAgent = void 0;
const base_agent_1 = require("./base-agent");
class ConversationImageAnalyzerAgent extends base_agent_1.BaseAgent {
    // Implementação do método abstrato (não usado diretamente)
    async execute(input) {
        const systemPrompt = this.buildSystemPrompt();
        return await this.analyzeImage(input, systemPrompt);
    }
    async analyzeAndExtract(input) {
        const systemPrompt = this.buildSystemPrompt();
        const result = await this.analyzeImage(input, systemPrompt);
        return this.parseExtractedData(result);
    }
    buildSystemPrompt() {
        return `Você é um especialista em extrair mensagens de screenshots de conversas de apps de namoro e mensageiros.

Sua função é analisar a imagem de uma conversa e extrair a ÚLTIMA MENSAGEM enviada pela pessoa com quem o usuário está conversando (o match/crush).

COMO IDENTIFICAR AS MENSAGENS:
- Em apps de namoro (Tinder, Bumble, Hinge): as mensagens DO MATCH geralmente aparecem do lado ESQUERDO ou com cor diferente
- Em WhatsApp/Instagram DM: mensagens DO MATCH aparecem do lado ESQUERDO (bolhas cinza/brancas)
- As mensagens DO USUÁRIO geralmente aparecem do lado DIREITO (bolhas coloridas, azuis ou verdes)

O QUE EXTRAIR:
1. **Última mensagem do match**: A mensagem mais recente enviada PELO MATCH (não pelo usuário)
2. **Contexto**: As últimas 2-3 mensagens anteriores para contexto (opcional)

FORMATO DA RESPOSTA:
Retorne APENAS um objeto JSON válido:

{
  "lastMessage": "A última mensagem que o match enviou (texto exato)",
  "lastMessageSender": "match" ou "user" ou "unknown",
  "conversationContext": ["mensagem anterior 1", "mensagem anterior 2"] ou null,
  "platform": "plataforma detectada ou null"
}

IMPORTANTE:
- Retorne APENAS o JSON, nada mais
- Se não conseguir identificar qual lado é do match, faça seu melhor palpite baseado no layout
- O mais importante é extrair a ÚLTIMA mensagem que NÃO é do usuário
- Seja PRECISO - transcreva exatamente o que está escrito
- Se a imagem não for de uma conversa, retorne {"error": "Imagem não parece ser uma conversa"}`;
    }
    async analyzeImage(input, systemPrompt) {
        const message = await this.client.messages.create({
            model: 'claude-sonnet-4-5-20250929',
            max_tokens: 1024,
            system: systemPrompt,
            messages: [
                {
                    role: 'user',
                    content: [
                        {
                            type: 'image',
                            source: {
                                type: 'base64',
                                media_type: input.imageMediaType,
                                data: input.imageBase64,
                            },
                        },
                        {
                            type: 'text',
                            text: `Analise este screenshot de conversa${input.platform ? ` do ${input.platform.toUpperCase()}` : ''} e extraia a última mensagem do match (a pessoa com quem o usuário está conversando).`,
                        },
                    ],
                },
            ],
        });
        const content = message.content[0];
        if (content.type === 'text') {
            return content.text;
        }
        throw new Error('Resposta inesperada da API');
    }
    parseExtractedData(jsonResponse) {
        try {
            console.log('Resposta da IA (conversa):', jsonResponse);
            let parsed;
            // Tentar parse direto primeiro
            try {
                parsed = JSON.parse(jsonResponse);
            }
            catch {
                // Se falhar, tentar extrair JSON da resposta
                let jsonMatch = jsonResponse.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/);
                if (!jsonMatch) {
                    jsonMatch = jsonResponse.match(/\{[\s\S]*\}/);
                }
                if (!jsonMatch) {
                    console.error('Nenhum JSON encontrado na resposta');
                    throw new Error('Nenhum JSON encontrado na resposta');
                }
                const jsonString = jsonMatch[1] || jsonMatch[0];
                parsed = JSON.parse(jsonString);
            }
            // Se houver erro na resposta
            if (parsed.error) {
                console.warn('Erro na análise:', parsed.error);
                return {};
            }
            const result = {
                lastMessage: parsed.lastMessage && parsed.lastMessage !== 'null' ? parsed.lastMessage : undefined,
                lastMessageSender: parsed.lastMessageSender && parsed.lastMessageSender !== 'null' ? parsed.lastMessageSender : undefined,
                conversationContext: parsed.conversationContext && parsed.conversationContext !== 'null' ? parsed.conversationContext : undefined,
                platform: parsed.platform && parsed.platform !== 'null' ? parsed.platform : undefined,
            };
            console.log('Dados da conversa extraídos:', result);
            return result;
        }
        catch (error) {
            console.error('Erro ao fazer parse dos dados da conversa:', error);
            console.error('Resposta completa:', jsonResponse);
            throw new Error(`Erro ao processar resposta da IA: ${error instanceof Error ? error.message : 'Erro desconhecido'}`);
        }
    }
}
exports.ConversationImageAnalyzerAgent = ConversationImageAnalyzerAgent;
