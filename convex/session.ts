import { action } from "./_generated/server";

export const getSessionAuth = action({
  args: {},
  handler: async () => {
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
