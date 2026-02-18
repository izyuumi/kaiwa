import { action } from "./_generated/server";

export const getSessionAuth = action({
  args: {},
  handler: async () => {
    const sonioxApiKey = process.env.SONIOX_API_KEY;
    if (!sonioxApiKey) {
      throw new Error("SONIOX_API_KEY environment variable is not set");
    }

    // Return the Soniox API key for the client to establish a WebSocket connection.
    // In production, this should be replaced with ephemeral token generation
    // once Soniox supports it, to avoid exposing the long-lived key.
    return {
      sonioxApiKey,
      config: {
        model: "stt-rt-v4",
        languageHints: ["ja", "en"],
      },
    };
  },
});
