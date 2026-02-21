import { action, internalMutation, internalQuery } from "./_generated/server";
import { internal } from "./_generated/api";
import { v } from "convex/values";

/** Maximum key requests per user per hour */
const MAX_REQUESTS_PER_HOUR = 10;

/** Key validity window in milliseconds (5 minutes) */
const KEY_TTL_MS = 5 * 60 * 1000;

export const logKeyAccess = internalMutation({
  args: { clerkId: v.string(), accessedAt: v.number() },
  handler: async (ctx, args) => {
    await ctx.db.insert("keyAccessLog", {
      clerkId: args.clerkId,
      accessedAt: args.accessedAt,
    });
  },
});

export const countRecentAccesses = internalQuery({
  args: { clerkId: v.string(), since: v.number() },
  handler: async (ctx, args) => {
    const logs = await ctx.db
      .query("keyAccessLog")
      .withIndex("by_clerkId_time", (q) =>
        q.eq("clerkId", args.clerkId).gte("accessedAt", args.since)
      )
      .collect();
    return logs.length;
  },
});

export const getSessionAuth = action({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    // Check approval status
    await ctx.runQuery(internal.users.getApprovalStatus);

    const now = Date.now();
    const clerkId = identity.subject;

    // Rate limit: max requests per hour
    const oneHourAgo = now - 60 * 60 * 1000;
    const recentCount = await ctx.runQuery(
      internal.session.countRecentAccesses,
      { clerkId, since: oneHourAgo }
    );
    if (recentCount >= MAX_REQUESTS_PER_HOUR) {
      throw new Error(
        "Rate limit exceeded. Please wait before requesting a new session."
      );
    }

    const sonioxApiKey = process.env.SONIOX_API_KEY;
    if (!sonioxApiKey) {
      throw new Error("SONIOX_API_KEY environment variable is not set");
    }

    // Audit log
    await ctx.runMutation(internal.session.logKeyAccess, {
      clerkId,
      accessedAt: now,
    });

    console.info(
      `[key-access] user=${clerkId} email=${identity.email ?? "unknown"} time=${new Date(now).toISOString()}`
    );

    return {
      sonioxApiKey,
      expiresAt: now + KEY_TTL_MS,
      config: {
        model: "stt-rt-v4",
        languageHints: ["ja", "en"],
      },
    };
  },
});
