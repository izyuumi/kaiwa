import { httpRouter } from "convex/server";
import { httpAction } from "./_generated/server";
import { internal } from "./_generated/api";
import { Webhook } from "svix";

type ClerkUserPayload = {
  id: string;
  email_addresses?: Array<{ email_address: string }>;
  first_name?: string | null;
  last_name?: string | null;
  image_url?: string;
};

type ClerkSessionPayload = {
  user_id: string;
};

type ClerkWebhookEvent = {
  type: string;
  data: ClerkUserPayload | ClerkSessionPayload;
};

const http = httpRouter();

http.route({
  path: "/clerk/webhook",
  method: "POST",
  handler: httpAction(async (ctx, req) => {
    const webhookSecret = process.env.CLERK_WEBHOOK_SIGNING_SECRET;
    if (!webhookSecret) {
      return new Response("Missing CLERK_WEBHOOK_SIGNING_SECRET", {
        status: 500,
      });
    }

    const svixId = req.headers.get("svix-id");
    const svixTimestamp = req.headers.get("svix-timestamp");
    const svixSignature = req.headers.get("svix-signature");

    if (!svixId || !svixTimestamp || !svixSignature) {
      return new Response("Missing Svix headers", { status: 400 });
    }

    const payload = await req.text();

    let event: ClerkWebhookEvent;
    try {
      event = new Webhook(webhookSecret).verify(payload, {
        "svix-id": svixId,
        "svix-timestamp": svixTimestamp,
        "svix-signature": svixSignature,
      }) as ClerkWebhookEvent;
    } catch {
      return new Response("Invalid signature", { status: 400 });
    }

    if (event.type === "user.created" || event.type === "user.updated") {
      const data = event.data as ClerkUserPayload;
      await ctx.runMutation(internal.users.upsertFromClerkWebhook, {
        clerkId: data.id,
        email: data.email_addresses?.[0]?.email_address,
        firstName: data.first_name ?? undefined,
        lastName: data.last_name ?? undefined,
        imageUrl: data.image_url,
      });
      return new Response("ok", { status: 200 });
    }

    if (event.type === "session.created") {
      const data = event.data as ClerkSessionPayload;
      await ctx.runMutation(internal.users.upsertFromClerkWebhook, {
        clerkId: data.user_id,
      });
      return new Response("ok", { status: 200 });
    }

    return new Response("ignored", { status: 200 });
  }),
});

export default http;
