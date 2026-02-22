import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    clerkId: v.string(),
    email: v.optional(v.string()),
    name: v.optional(v.string()),
    imageUrl: v.optional(v.string()),
    isManuallyApproved: v.boolean(),
    hasActiveSubscription: v.boolean(),
    createdAt: v.number(),
    updatedAt: v.number(),
    lastSeenAt: v.number(),
  }).index("by_clerkId", ["clerkId"]),
  keyAccessLog: defineTable({
    clerkId: v.string(),
    accessedAt: v.number(),
  }).index("by_clerkId_time", ["clerkId", "accessedAt"]),
  apiUsageLog: defineTable({
    clerkId: v.string(),
    endpoint: v.union(v.literal("session"), v.literal("translate")),
    accessedAt: v.number(),
  }).index("by_clerk_endpoint_time", ["clerkId", "endpoint", "accessedAt"]),
});
