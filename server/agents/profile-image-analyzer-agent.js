"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProfileImageAnalyzerAgent = void 0;
const base_agent_1 = require("./base-agent");
class ProfileImageAnalyzerAgent extends base_agent_1.BaseAgent {
    async execute(input, userContext) {
        const systemPrompt = this.buildSystemPrompt();
        return await this.analyzeImage(input, systemPrompt);
    }
    async analyzeImageAndParse(input) {
        const result = await this.execute(input);
        return this.parseExtractedData(result);
    }
    buildSystemPrompt() {
        return `Você é um especialista em extrair informações de screenshots de perfis de apps de namoro e redes sociais.

Sua função é analisar a imagem fornecida e extrair TODAS as informações visíveis:

INFORMAÇÕES A EXTRAIR:
1. **Nome**: Nome completo ou primeiro nome
2. **Idade**: Se estiver visível
3. **Bio/Descrição**: Todo o texto da bio, exatamente como está escrito
4. **Fotos**: Descreva cada foto visível (ex: "na praia", "com cachorro", "selfie", etc)
5. **Localização**: Cidade/distância se visível
6. **Ocupação/Educação**: Trabalho, faculdade, etc
7. **Interesses/Hobbies**: Tags, badges, ou mencionados na bio
8. **Outras informações**: Altura, idiomas, etc

FORMATO DA RESPOSTA:
Retorne APENAS um objeto JSON válido, sem texto adicional antes ou depois.
Use null para campos não visíveis.

{
  "name": "Nome extraído ou null",
  "username": "@usuario ou null (para Instagram/redes sociais)",
  "age": "Idade ou null",
  "bio": "Bio completa ou null",
  "photoDescriptions": ["descrição foto 1", "descrição foto 2", ...] ou null,
  "location": "Localização ou null",
  "occupation": "Trabalho/faculdade ou null",
  "interests": ["interesse 1", "interesse 2", ...] ou null,
  "additionalInfo": "Outras informações relevantes ou null",
  "faceDescription": "Breve descrição da aparência (cabelo, etnia, etc) ou null",
  "facePosition": {"centerX": 15, "centerY": 8, "size": 12} ou null
}

IMPORTANTE:
- Retorne APENAS o JSON, nada mais
- Seja PRECISO e extraia exatamente o que está escrito
- Se algo não estiver visível, use null
- Nas descrições de fotos, seja específico e útil
- Capture TUDO que possa ser útil para criar uma primeira mensagem
- Para facePosition: Localize o ROSTO HUMANO principal visível na imagem. Retorne coordenadas como porcentagem (0-100) da IMAGEM INTEIRA.
  - centerX: centro horizontal do ROSTO (0=borda esquerda, 50=meio, 100=borda direita)
  - centerY: centro vertical do ROSTO (0=topo, 50=meio, 100=base)
  - size: LARGURA DO ROSTO como % da largura total da imagem
  - Screenshots de INSTAGRAM: A foto de perfil circular fica no canto superior esquerdo. O rosto está DENTRO desse círculo. Coordenadas típicas: centerX≈15, centerY≈13, size≈18
  - Screenshots de TINDER/BUMBLE/HINGE: O rosto ocupa boa parte da foto. Coordenadas típicas: centerX≈50, centerY≈30, size≈35
  - Fotos individuais: O rosto geralmente está centralizado. Coordenadas típicas: centerX≈50, centerY≈35, size≈40
  - SEMPRE retorne facePosition se houver qualquer rosto visível, mesmo que pequeno
  - Se realmente não houver nenhum rosto visível na imagem, use null`;
    }
    async analyzeImage(input, systemPrompt) {
        const message = await this.client.messages.create({
            model: 'claude-sonnet-4-5-20250929',
            max_tokens: 2048,
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
                            text: `Analise este screenshot de perfil${input.platform ? ` do ${input.platform.toUpperCase()}` : ''} e extraia todas as informações visíveis no formato JSON especificado.`,
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
            console.log('Resposta da IA:', jsonResponse);
            let parsed;
            // Tentar parse direto primeiro
            try {
                parsed = JSON.parse(jsonResponse);
            }
            catch {
                // Se falhar, tentar extrair JSON da resposta (pode vir com markdown ou texto extra)
                // Tentar extrair de bloco de código markdown
                let jsonMatch = jsonResponse.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/);
                if (!jsonMatch) {
                    // Tentar extrair qualquer objeto JSON
                    jsonMatch = jsonResponse.match(/\{[\s\S]*\}/);
                }
                if (!jsonMatch) {
                    console.error('Nenhum JSON encontrado na resposta');
                    throw new Error('Nenhum JSON encontrado na resposta');
                }
                const jsonString = jsonMatch[1] || jsonMatch[0];
                parsed = JSON.parse(jsonString);
            }
            const result = {
                name: parsed.name && parsed.name !== 'null' ? parsed.name : undefined,
                username: parsed.username && parsed.username !== 'null' ? parsed.username : undefined,
                age: parsed.age && parsed.age !== 'null' ? parsed.age : undefined,
                bio: parsed.bio && parsed.bio !== 'null' ? parsed.bio : undefined,
                photoDescriptions: parsed.photoDescriptions && parsed.photoDescriptions !== 'null' ? parsed.photoDescriptions : undefined,
                location: parsed.location && parsed.location !== 'null' ? parsed.location : undefined,
                occupation: parsed.occupation && parsed.occupation !== 'null' ? parsed.occupation : undefined,
                interests: parsed.interests && parsed.interests !== 'null' ? parsed.interests : undefined,
                additionalInfo: parsed.additionalInfo && parsed.additionalInfo !== 'null' ? parsed.additionalInfo : undefined,
                faceDescription: parsed.faceDescription && parsed.faceDescription !== 'null' ? parsed.faceDescription : undefined,
                facePosition: parsed.facePosition && parsed.facePosition !== 'null' && typeof parsed.facePosition === 'object' ? parsed.facePosition : undefined,
            };
            console.log('Dados extraídos:', result);
            return result;
        }
        catch (error) {
            console.error('Erro ao fazer parse dos dados extraídos:', error);
            console.error('Resposta completa:', jsonResponse);
            throw new Error(`Erro ao processar resposta da IA: ${error instanceof Error ? error.message : 'Erro desconhecido'}`);
        }
    }
}
exports.ProfileImageAnalyzerAgent = ProfileImageAnalyzerAgent;
