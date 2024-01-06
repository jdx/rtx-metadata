import {createClient} from '@supabase/supabase-js'

export default {
    async fetch(request, env) {
        const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_KEY);

        const plugin = request.url.split("/")[3];
        if (!plugin) return new Response("Not found", {status: 404});

        let url = new URL(request.url);
        url.hostname = "mise-versions-gh.jdx.dev";
        const response = await fetch(url);
        if (response.status !== 200) return response;

        const pluginID = await getOrCreatePlugin(supabase, plugin);
        await supabase.from("version_requests").insert({
            plugin_id: pluginID,
            ip: request.headers.get("cf-connecting-ip"),
            user_agent: request.headers.get("user-agent"),
            country: request.cf.country,
            region: request.cf.region,
            city: request.cf.city,
        });

        return response;
    },
};

async function getOrCreatePlugin(supabase, name) {
    const id = await getPluginID(supabase, name);
    if (id) return id;

    const {data, error} = await supabase.from("plugins").insert({name: name}).select('id').single();
    if (error) throw error;
    return data.id;
}

async function getPluginID(supabase, name) {
    const {data, error} = await supabase.from("plugins").select('id').eq('name', name).maybeSingle();
    if (error) throw error;

    if (data) return data.id;
    return null;
}
