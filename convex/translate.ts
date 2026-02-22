import { action } from "./_generated/server";
import { v } from "convex/values";
import { internal } from "./_generated/api";
import OpenAI from "openai";

const MAX_TRANSLATIONS_PER_MINUTE = 30;
const MAX_INPUT_CHARS = 2000;
const MAX_GLOSSARY_ITEMS = 30;
const MAX_GLOSSARY_TERM_CHARS = 80;

export const translate = action({
  args: {
    text: v.string(),
    detectedLanguage: v.string(),
    glossary: v.optional(
      v.array(
        v.object({
          source: v.string(),
          target: v.string(),
        })
      )
    ),
  },
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    await ctx.runMutation(internal.users.assertApiAccess, {});
    await ctx.runMutation(internal.users.assertAndLogUsage, {
      endpoint: "translate",
      windowMs: 60 * 1000,
      maxRequests: MAX_TRANSLATIONS_PER_MINUTE,
    });

    const normalizedText = args.text.trim();
    if (!normalizedText) {
      throw new Error("Empty text cannot be translated");
    }
    if (normalizedText.length > MAX_INPUT_CHARS) {
      throw new Error(`Text too long (max ${MAX_INPUT_CHARS} characters)`);
    }

    const glossary = sanitizeGlossary(args.glossary ?? []);

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new Error("OPENAI_API_KEY environment variable is not set");
    }

    const openai = new OpenAI({ apiKey });

    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.2,
      max_tokens: 500,
      messages: [
        {
          role: "system",
          content: buildSystemPrompt(glossary),
        },
        {
          role: "user",
          content: `Detected language: ${args.detectedLanguage}\nText: ${normalizedText}`,
        },
      ],
      response_format: { type: "json_object" },
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error("No response from translation model");
    }

    return parseAndValidateTranslationPayload(content);
  },
});

export function parseAndValidateTranslationPayload(content: string): {
  jp: string;
  en: string;
} {
  let parsed: unknown;

  try {
    parsed = JSON.parse(content);
  } catch {
    throw new Error("Translation model returned invalid JSON");
  }

  if (!parsed || typeof parsed !== "object") {
    throw new Error("Translation model output must be a JSON object");
  }

  const jp = getStringField(parsed, "jp");
  const en = getStringField(parsed, "en");

  if (!jp.trim() || !en.trim()) {
    throw new Error("Translation output fields must be non-empty strings");
  }

  return {
    jp: jp.trim(),
    en: en.trim(),
  };
}

function buildSystemPrompt(glossary: Array<{ source: string; target: string }>) {
  const glossarySection = glossary.length
    ? `\nPrefer these glossary mappings when applicable:\n${glossary
        .map((term) => `- ${term.source} => ${term.target}`)
        .join("\n")}`
    : "";

  return `You are a real-time translator for business meetings.
Given transcribed speech and its detected language, output JSON:
{"jp": "...", "en": "..."}
Use formal, natural business language.
Output ONLY valid JSON.${glossarySection}`;
}

function sanitizeGlossary(
  glossary: Array<{ source: string; target: string }>
): Array<{ source: string; target: string }> {
  const deduped = new Map<string, { source: string; target: string }>();

  for (const term of glossary.slice(0, MAX_GLOSSARY_ITEMS)) {
    const source = term.source.trim();
    const target = term.target.trim();
    if (!source || !target) {
      continue;
    }
    if (
      source.length > MAX_GLOSSARY_TERM_CHARS ||
      target.length > MAX_GLOSSARY_TERM_CHARS
    ) {
      continue;
    }

    deduped.set(source.toLowerCase(), { source, target });
  }

  return [...deduped.values()];
}

function getStringField(parsed: object, key: "jp" | "en"): string {
  const value = (parsed as Record<string, unknown>)[key];
  if (typeof value !== "string") {
    throw new Error(`Translation output missing string field: ${key}`);
  }
  return value;
}
