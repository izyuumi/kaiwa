import { mutation, query, internalQuery, internalMutation } from "./_generated/server";
import { v, Validator } from "convex/values";
import type { UserJSON } from "@clerk/backend";

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

    if (existing) {
      return { isApproved: existing.isApproved };
    }

    await ctx.db.insert("users", {
      clerkId,
      email: identity.email,
      name: identity.name,
      isApproved: false,
      createdAt: Date.now(),
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

export const upsertFromClerk = internalMutation({
  args: { data: v.any() as Validator<UserJSON> },
  async handler(ctx, { data }) {
    const userAttributes = {
      clerkId: data.id,
      email: data.email_addresses[0]?.email_address,
      name:
        `${data.first_name ?? ""} ${data.last_name ?? ""}`.trim() || undefined,
    };

    const existing = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", data.id))
      .unique();

    if (existing) {
      await ctx.db.patch(existing._id, userAttributes);
    } else {
      await ctx.db.insert("users", {
        ...userAttributes,
        isApproved: false,
        createdAt: Date.now(),
      });
    }
  },
});

export const deleteFromClerk = internalMutation({
  args: { clerkUserId: v.string() },
  async handler(ctx, { clerkUserId }) {
    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", clerkUserId))
      .unique();

    if (user) {
      await ctx.db.delete(user._id);
    } else {
      console.warn(
        `Can't delete user, there is none for Clerk user ID: ${clerkUserId}`
      );
    }
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

    if (!user || !user.isApproved) {
      throw new Error("Account not approved");
    }

    return { isApproved: true };
  },
});
