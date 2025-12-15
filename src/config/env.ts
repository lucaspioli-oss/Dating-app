import dotenv from 'dotenv';

dotenv.config();

export const env = {
  ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY || '',
  PORT: parseInt(process.env.PORT || '3000', 10),
};

if (!env.ANTHROPIC_API_KEY) {
  console.error('ERRO: ANTHROPIC_API_KEY não configurada no arquivo .env');
  process.exit(1);
}
