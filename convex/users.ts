import { internalMutation, mutation, query } from "./_generated/server";
import { v } from "convex/values";

function buildDisplayName(firstName?: string | null, lastName?: string | null) {
  const fullName = `${firstName ?? ""} ${lastName ?? ""}`.trim();
  return fullName.length > 0 ? fullName : undefined;
}

export const ensureUser = mutation({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    const now = Date.now();
    const existing = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", identity.subject))
      .unique();

    if (!existing) {
      await ctx.db.insert("users", {
        clerkId: identity.subject,
        email: identity.email,
        name: identity.name,
        imageUrl: identity.pictureUrl,
        isManuallyApproved: false,
        hasActiveSubscription: false,
        createdAt: now,
        updatedAt: now,
        lastSeenAt: now,
      });
      return { isApproved: false };
    }

    await ctx.db.patch(existing._id, {
      email: identity.email,
      name: identity.name,
      imageUrl: identity.pictureUrl,
      updatedAt: now,
      lastSeenAt: now,
    });

    return {
      isApproved: existing.isManuallyApproved || existing.hasActiveSubscription,
    };
  },
});

export const getMe = query({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      return null;
    }

    return await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", identity.subject))
      .unique();
  },
});

export const assertApiAccess = internalMutation({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    const now = Date.now();
    const existing = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", identity.subject))
      .unique();

    if (!existing) {
      await ctx.db.insert("users", {
        clerkId: identity.subject,
        email: identity.email,
        name: identity.name,
        imageUrl: identity.pictureUrl,
        isManuallyApproved: false,
        hasActiveSubscription: false,
        createdAt: now,
        updatedAt: now,
        lastSeenAt: now,
      });
      throw new Error("Account not approved");
    }

    await ctx.db.patch(existing._id, {
      email: identity.email,
      name: identity.name,
      imageUrl: identity.pictureUrl,
      updatedAt: now,
      lastSeenAt: now,
    });

    if (!existing.isManuallyApproved && !existing.hasActiveSubscription) {
      throw new Error("Account not approved");
    }

    return { isApproved: true };
  },
});

export const assertAndLogUsage = internalMutation({
  args: {
    endpoint: v.union(v.literal("session"), v.literal("translate")),
    windowMs: v.number(),
    maxRequests: v.number(),
  },
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    const now = Date.now();
    const since = now - args.windowMs;

    const recent = await ctx.db
      .query("apiUsageLog")
      .withIndex("by_clerk_endpoint_time", (q) =>
        q.eq("clerkId", identity.subject)
          .eq("endpoint", args.endpoint)
          .gte("accessedAt", since)
      )
      .collect();

    if (recent.length >= args.maxRequests) {
      throw new Error(
        `Rate limit exceeded for ${args.endpoint}. Please wait before retrying.`
      );
    }

    await ctx.db.insert("apiUsageLog", {
      clerkId: identity.subject,
      endpoint: args.endpoint,
      accessedAt: now,
    });
  },
});

export const upsertFromClerkWebhook = internalMutation({
  args: {
    clerkId: v.string(),
    email: v.optional(v.string()),
    firstName: v.optional(v.string()),
    lastName: v.optional(v.string()),
    imageUrl: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const name = buildDisplayName(args.firstName, args.lastName);

    const existing = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", args.clerkId))
      .unique();

    if (!existing) {
      await ctx.db.insert("users", {
        clerkId: args.clerkId,
        email: args.email,
        name,
        imageUrl: args.imageUrl,
        isManuallyApproved: false,
        hasActiveSubscription: false,
        createdAt: now,
        updatedAt: now,
        lastSeenAt: now,
      });
      return;
    }

    await ctx.db.patch(existing._id, {
      email: args.email ?? existing.email,
      name: name ?? existing.name,
      imageUrl: args.imageUrl ?? existing.imageUrl,
      updatedAt: now,
      lastSeenAt: now,
    });
  },
});
