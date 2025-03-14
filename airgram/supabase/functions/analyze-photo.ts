// supabase/functions/get-openai-key/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

serve(async (req) => {
  const OPENAI_KEY = Deno.env.get("OPENAI_KEY")!;
  
  return new Response(
    JSON.stringify({ key: OPENAI_KEY }),
    { headers: { "Content-Type": "application/json" } }
  )
})