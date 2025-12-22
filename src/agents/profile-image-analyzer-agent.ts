import { BaseAgent, UserContext } from './base-agent';
import Anthropic from '@anthropic-ai/sdk';

export interface ProfileImageAnalysisInput {
  imageBase64: string;
  imageMediaType: 'image/jpeg' | 'image/png' | 'image/gif' | 'image/webp';
  platform?: 'tinder' | 'bumble' | 'hinge' | 'instagram' | 'outro';
}

export interface ExtractedProfileData {
  name?: string;
  username?: string;           // Para Instagram (@usuario)
  age?: string;
  bio?: string;
  photoDescriptions?: string[];
  location?: string;
  occupation?: string;
  interests?: string[];
  additionalInfo?: string;
  faceDescription?: string;    // Descrição facial detalhada para identificação
}

export class ProfileImageAnalyzerAgent extends BaseAgent {
  async execute(input: ProfileImageAnalysisInput, userContext?: UserContext): Promise<string> {
    const systemPrompt = this.buildSystemPrompt();
    return await this.analyzeImage(input, systemPrompt);
  }

  async analyzeImageAndParse(input: ProfileImageAnalysisInput): Promise<ExtractedProfileData> {
    const result = await this.execute(input);
    return this.parseExtractedData(result);
  }

  private buildSystemPrompt(): string {
    return `Você é um especialista em extrair informações de screenshots de perfis de apps de namoro e redes sociais.

Sua função é analisar a imagem fornecida e extrair TODAS as informações visíveis:

INFORMAÇÕES A EXTRAIR:
1. **Nome**: Nome completo ou primeiro nome
2. **Username**: Para Instagram, o @usuario (sem o @). Para outros apps, null.
3. **Idade**: Se estiver visível (número apenas, ex: "25")
4. **Bio/Descrição**: Todo o texto da bio, exatamente como está escrito
5. **Fotos**: Descreva cada foto visível (ex: "na praia", "com cachorro", "selfie", etc)
6. **Localização**: Cidade/distância se visível
7. **Ocupação/Educação**: Trabalho, faculdade, etc
8. **Interesses/Hobbies**: Tags, badges, ou mencionados na bio
9. **Outras informações**: Altura, idiomas, etc
10. **Descrição Facial**: Descreva o rosto da pessoa na foto principal de forma detalhada para identificação futura (cor do cabelo, comprimento do cabelo, cor dos olhos se visível, formato do rosto, características marcantes como barba, óculos, piercings, tatuagens visíveis no rosto/pescoço, sorriso, expressão)

FORMATO DA RESPOSTA:
Retorne APENAS um objeto JSON válido, sem texto adicional antes ou depois.
Use null para campos não visíveis.

{
  "name": "Nome extraído ou null",
  "username": "username sem @ (só para Instagram) ou null",
  "age": "Idade (número) ou null",
  "bio": "Bio completa ou null",
  "photoDescriptions": ["descrição foto 1", "descrição foto 2", ...] ou null,
  "location": "Localização ou null",
  "occupation": "Trabalho/faculdade ou null",
  "interests": ["interesse 1", "interesse 2", ...] ou null,
  "additionalInfo": "Outras informações relevantes ou null",
  "faceDescription": "Descrição facial detalhada ou null"
}

IMPORTANTE:
- Retorne APENAS o JSON, nada mais
- Seja PRECISO e extraia exatamente o que está escrito
- Se algo não estiver visível, use null
- Nas descrições de fotos, seja específico e útil
- A descrição facial deve ser detalhada o suficiente para identificar a pessoa visualmente
- Capture TUDO que possa ser útil para criar uma primeira mensagem`;
  }

  private async analyzeImage(
    input: ProfileImageAnalysisInput,
    systemPrompt: string
  ): Promise<string> {
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
              text: `Analise este screenshot de perfil${
                input.platform ? ` do ${input.platform.toUpperCase()}` : ''
              } e extraia todas as informações visíveis no formato JSON especificado.`,
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

  private parseExtractedData(jsonResponse: string): ExtractedProfileData {
    try {
      console.log('Resposta da IA:', jsonResponse);

      let parsed: any;

      // Tentar parse direto primeiro
      try {
        parsed = JSON.parse(jsonResponse);
      } catch {
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

      const result: ExtractedProfileData = {
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
      };

      console.log('Dados extraídos:', result);
      return result;
    } catch (error) {
      console.error('Erro ao fazer parse dos dados extraídos:', error);
      console.error('Resposta completa:', jsonResponse);
      throw new Error(`Erro ao processar resposta da IA: ${error instanceof Error ? error.message : 'Erro desconhecido'}`);
    }
  }
}
