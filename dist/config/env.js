"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.env = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
exports.env = {
    ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY || '',
    PORT: parseInt(process.env.PORT || '3000', 10),
};
if (!exports.env.ANTHROPIC_API_KEY) {
    console.error('ERRO: ANTHROPIC_API_KEY não configurada no arquivo .env');
    process.exit(1);
}
