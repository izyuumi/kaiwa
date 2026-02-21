import { action, internalMutation, internalQuery } from "./_generated/server";
import { internal } from "./_generated/api";
import { v } from "convex/values";

/** Maximum key requests per user per hour */
const MAX_REQUESTS_PER_HOUR = 10;

/** Temporary key duration in seconds (5 minutes) */
const TEMP_KEY_EXPIRES_IN_SECONDS = 300;

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

    // Create a temporary API key via Soniox REST API
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
          client_reference_id: clerkId,
        }),
      }
    );

    if (!tempKeyResponse.ok) {
      const errorText = await tempKeyResponse.text();
      console.error(
        `[temp-key-error] user=${clerkId} status=${tempKeyResponse.status} body=${errorText}`
      );
      throw new Error("Failed to create temporary API key");
    }

    const tempKey = (await tempKeyResponse.json()) as {
      api_key: string;
      expires_at: string;
    };

    // Audit log
    await ctx.runMutation(internal.session.logKeyAccess, {
      clerkId,
      accessedAt: now,
    });

    console.info(
      `[key-access] user=${clerkId} email=${identity.email ?? "unknown"} time=${new Date(now).toISOString()} temp_key_expires=${tempKey.expires_at}`
    );

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
