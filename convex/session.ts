import { action } from "./_generated/server";

export const getSessionAuth = action({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    const sonioxApiKey = process.env.SONIOX_API_KEY;
    if (!sonioxApiKey) {
      throw new Error("SONIOX_API_KEY environment variable is not set");
    }

    return {
      sonioxApiKey,
      config: {
        model: "stt-rt-v4",
        languageHints: ["ja", "en"],
      },
    };
  },
});
