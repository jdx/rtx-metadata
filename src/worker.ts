import { createClient, SupabaseClient } from "@supabase/supabase-js";
import { Request } from "@cloudflare/workers-types";
import { Database } from "./database.types.js";

type Env = {
  SUPABASE_URL: string;
  SUPABASE_KEY: string;
};

class Worker {
  constructor(private supabase: SupabaseClient<Database>) {}

  handle(request: Request) {
    const plugin = request.url.split("/")[3];
    if (!plugin) return new Response("Not found", { status: 404 });

    const url = new URL(request.url);
    url.hostname = "mise-versions-gh.jdx.dev";
    const response = await fetch(url);
    if (response.status !== 200) return response;

    const pluginID = await this.getOrCreatePlugin(plugin);
    await this.supabase.from("version_requests").insert({
      plugin_id: pluginID,
      ip: request.headers.get("cf-connecting-ip"),
      user_agent: request.headers.get("user-agent"),
      country: request.cf!.country,
      region: request.cf!.region,
      city: request.cf!.city,
    });

    return response;
  }

  async getOrCreatePlugin(name: string) {
    const id = await this.getPluginID(name);
    if (id) return id;

    const { data, error } = await this.supabase
      .from("plugins")
      .insert({ name: name })
      .select("id")
      .single();
    if (error) throw error;
    return data.id;
  }

  async getPluginID(name: string): Promise<number | null> {
    const { data, error } = await this.supabase
      .from("plugins")
      .select("id")
      .eq("name", name)
      .maybeSingle();
    if (error) throw error;

    if (data) return data.id;
    return null;
  }
}

export default {
  async fetch(request: Request, env: Env) {
    const supabase = createClient<Database>(env.SUPABASE_URL, env.SUPABASE_KEY);
    const worker = new Worker(supabase);
    return worker.handle(request);
  },
};
