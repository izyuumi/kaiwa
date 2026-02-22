import { action } from "./_generated/server";
import { internal } from "./_generated/api";

const MAX_SESSION_AUTH_REQUESTS_PER_HOUR = 10;
const TEMP_KEY_EXPIRES_IN_SECONDS = 300;

export const getSessionAuth = action({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    await ctx.runMutation(internal.users.assertApiAccess, {});
    await ctx.runMutation(internal.users.assertAndLogUsage, {
      endpoint: "session",
      windowMs: 60 * 60 * 1000,
      maxRequests: MAX_SESSION_AUTH_REQUESTS_PER_HOUR,
    });

    const sonioxApiKey = process.env.SONIOX_API_KEY;
    if (!sonioxApiKey) {
      throw new Error("SONIOX_API_KEY environment variable is not set");
    }

    const tempKeyResponse = await fetch(
      "https://api.soniox.com/v1/auth/temporary-api-key",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${sonioxApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          usage_type: "transcribe_websocket",
          expires_in_seconds: TEMP_KEY_EXPIRES_IN_SECONDS,
          client_reference_id: identity.subject,
        }),
      }
    );

    if (!tempKeyResponse.ok) {
      const errorText = await tempKeyResponse.text();
      console.error(
        `[temp-key-error] user=${identity.subject} status=${tempKeyResponse.status} body=${errorText}`
      );
      throw new Error("Failed to create temporary API key");
    }

    const tempKey = (await tempKeyResponse.json()) as {
      api_key?: string;
      expires_at?: string;
    };

    if (!tempKey.api_key || !tempKey.expires_at) {
      throw new Error("Temporary API key response was missing required fields");
    }

    return {
      sonioxApiKey: tempKey.api_key,
      expiresAt: new Date(tempKey.expires_at).getTime(),
      config: {
        model: "stt-rt-v4",
        languageHints: ["ja", "en"],
      },
    };
  },
});
