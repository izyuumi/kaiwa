import { action } from "./_generated/server";
import { internal } from "./_generated/api";

export const getSessionAuth = action({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    // Check approval status
    await ctx.runQuery(internal.users.getApprovalStatus);

    const sonioxApiKey = process.env.SONIOX_API_KEY;
    if (!sonioxApiKey) {
      throw new Error("SONIOX_API_KEY environment variable is not set");
    }

    // Create an ephemeral Soniox API key (max 1 hour)
    const response = await fetch("https://api.soniox.com/v1/auth/temporary-api-key", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${sonioxApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        usage_type: "transcribe_websocket",
        expires_in_seconds: 3600,
      }),
    });

    if (!response.ok) {
      throw new Error(`Failed to create temporary Soniox key: ${response.status}`);
    }

    const { api_key: tempKey } = await response.json() as { api_key: string };

    return {
      sonioxApiKey: tempKey,
      config: {
        model: "stt-rt-v4",
        languageHints: ["ja", "en"],
      },
    };
  },
});
