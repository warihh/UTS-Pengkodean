// Masukkan URL dan anon/publishable key. Jangan taruh service_role key di frontend.
const SUPABASE_URL = "https://brbdmfnmgxgucjqojxpd.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_rF8QWTDfyXscpnjM8K3QqQ_tMMi-r_v";
const USE_SUPABASE = true;
const supabaseClient = (USE_SUPABASE && SUPABASE_URL && SUPABASE_ANON_KEY && window.supabase)
 ? window.supabase.createClient(SUPABASE_URL,SUPABASE_ANON_KEY) : null;
