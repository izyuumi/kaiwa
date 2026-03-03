import { mutation, query, internalQuery } from "./_generated/server";

export const ensureUser = mutation({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    const clerkId = identity.subject;
    const existing = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", clerkId))
      .unique();

    const now = Date.now();

    if (existing) {
      await ctx.db.patch(existing._id, { lastSeenAt: now, updatedAt: now });
      return { isApproved: existing.isManuallyApproved || existing.hasActiveSubscription };
    }

    await ctx.db.insert("users", {
      clerkId,
      email: identity.email,
      name: identity.name,
      isManuallyApproved: false,
      hasActiveSubscription: false,
      createdAt: now,
      updatedAt: now,
      lastSeenAt: now,
    });

    return { isApproved: false };
  },
});

export const getMe = query({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      return null;
    }

    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", identity.subject))
      .unique();

    return user;
  },
});

export const getApprovalStatus = internalQuery({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", identity.subject))
      .unique();

    if (!user || (!user.isManuallyApproved && !user.hasActiveSubscription)) {
      throw new Error("Account not approved");
    }

    return { isApproved: true };
  },
});
