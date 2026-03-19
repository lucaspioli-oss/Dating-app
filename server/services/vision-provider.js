"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.analyzeImageWithVision = analyzeImageWithVision;
exports.getVisionProvider = getVisionProvider;

const sdk_1 = __importDefault(require("@anthropic-ai/sdk"));

// VISION_PROVIDER env var: "claude" or "gemini" (default: "claude")
function getVisionProvider() {
    return (process.env.VISION_PROVIDER || 'claude').toLowerCase();
}

/**
 * Analyze an image using the configured vision provider.
 * Switch between Claude Vision and Gemini Vision via VISION_PROVIDER env var.
 */
async function analyzeImageWithVision({ imageBase64, imageMediaType, systemPrompt, userPrompt, maxTokens = 2048, temperature = 0.3 }) {
    const provider = getVisionProvider();

    if (provider === 'gemini') {
        return await analyzeWithGemini({ imageBase64, imageMediaType, systemPrompt, userPrompt, maxTokens, temperature });
    }

    return await analyzeWithClaude({ imageBase64, imageMediaType, systemPrompt, userPrompt, maxTokens, temperature });
}

async function analyzeWithClaude({ imageBase64, imageMediaType, systemPrompt, userPrompt, maxTokens, temperature }) {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) throw new Error('ANTHROPIC_API_KEY not configured');

    const client = new sdk_1.default({ apiKey });
    const message = await client.messages.create({
        model: process.env.CLAUDE_VISION_MODEL || 'claude-sonnet-4-5-20250929',
        max_tokens: maxTokens,
        temperature,
        system: systemPrompt,
        messages: [{
            role: 'user',
            content: [
                {
                    type: 'image',
                    source: { type: 'base64', media_type: imageMediaType, data: imageBase64 },
                },
                { type: 'text', text: userPrompt },
            ],
        }],
    });

    const content = message.content[0];
    if (content.type === 'text') return content.text;
    throw new Error('Unexpected response from Claude Vision');
}

async function analyzeWithGemini({ imageBase64, imageMediaType, systemPrompt, userPrompt, maxTokens, temperature }) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) throw new Error('GEMINI_API_KEY not configured. Set it in .env to use Gemini Vision.');

    const model = process.env.GEMINI_VISION_MODEL || 'gemini-2.0-flash';
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            systemInstruction: { parts: [{ text: systemPrompt }] },
            contents: [{
                parts: [
                    { inlineData: { mimeType: imageMediaType, data: imageBase64 } },
                    { text: userPrompt },
                ],
            }],
            generationConfig: {
                maxOutputTokens: maxTokens,
                temperature,
            },
        }),
    });

    if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`Gemini API error (${response.status}): ${errorBody}`);
    }

    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) throw new Error('Empty response from Gemini Vision');

    return text;
}
