import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    clerkId: v.string(),
    email: v.optional(v.string()),
    name: v.optional(v.string()),
    isManuallyApproved: v.boolean(),
    hasActiveSubscription: v.boolean(),
    createdAt: v.float64(),
    updatedAt: v.optional(v.float64()),
    lastSeenAt: v.optional(v.float64()),
  }).index("by_clerkId", ["clerkId"]),
});
