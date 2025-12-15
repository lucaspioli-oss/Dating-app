import Fastify from 'fastify';
import { env } from './config/env';
import { analyzeMessage } from './services/anthropic';
import { AnalyzeRequest, AnalyzeResponse } from './types';

const fastify = Fastify({
  logger: true,
});

const analyzeSchema = {
  body: {
    type: 'object',
    required: ['text', 'tone'],
    properties: {
      text: { type: 'string', minLength: 1 },
      tone: {
        type: 'string',
        enum: ['engraçado', 'ousado', 'romântico', 'casual', 'confiante'],
      },
    },
  },
};

fastify.post<{ Body: AnalyzeRequest }>(
  '/analyze',
  { schema: analyzeSchema },
  async (request, reply) => {
    try {
      const { text, tone } = request.body;

      const analysis = await analyzeMessage({ text, tone });

      const response: AnalyzeResponse = {
        analysis,
      };

      return reply.code(200).send(response);
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: 'Erro ao processar análise',
        message: error instanceof Error ? error.message : 'Erro desconhecido',
      });
    }
  }
);

fastify.get('/health', async (request, reply) => {
  return { status: 'ok', timestamp: new Date().toISOString() };
});

const start = async () => {
  try {
    await fastify.listen({ port: env.PORT, host: '0.0.0.0' });
    console.log(`🚀 Servidor rodando na porta ${env.PORT}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
