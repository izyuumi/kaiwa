import { action } from "./_generated/server";
import { v } from "convex/values";
import OpenAI from "openai";

export const translate = action({
  args: {
    text: v.string(),
    detectedLanguage: v.string(),
  },
  handler: async (ctx, args) => {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new Error("OPENAI_API_KEY environment variable is not set");
    }

    const openai = new OpenAI({ apiKey });

    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.3,
      max_tokens: 500,
      messages: [
        {
          role: "system",
          content: `You are a real-time translator for business meetings.
Given transcribed speech and its detected language, output JSON:
{"jp": "...", "en": "..."}
Use formal, natural business language.
Output ONLY valid JSON.`,
        },
        {
          role: "user",
          content: `Detected language: ${args.detectedLanguage}\nText: ${args.text}`,
        },
      ],
      response_format: { type: "json_object" },
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error("No response from translation model");
    }

    return JSON.parse(content) as { jp: string; en: string };
  },
});
