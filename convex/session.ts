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

    return {
      sonioxApiKey,
      config: {
        model: "stt-rt-v4",
        languageHints: ["ja", "en"],
      },
    };
  },
});
