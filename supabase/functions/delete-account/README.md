# delete-account (Supabase Edge Function)

This function deletes the currently authenticated user's account.

What it does:
1. Verifies the caller using the JWT sent by the client.
2. Best-effort deletes the user's app profile row from table `user` (by email).
3. Deletes the Supabase Auth user using the Admin API (service role).

## Required secrets
Supabase reserves the `SUPABASE_` prefix and the CLI blocks setting secrets that start with `SUPABASE_`.

Set these as Edge Function secrets (do NOT put them in your Flutter app):
- `PROJECT_URL` (your project URL)
- `ANON_KEY` (your anon/public key)
- `SERVICE_ROLE_KEY` (your service role key)

## Deploy (Supabase CLI)
From the repo root:

```bash
supabase login
supabase link --project-ref <your-project-ref>

supabase secrets set PROJECT_URL="https://<project>.supabase.co"
supabase secrets set ANON_KEY="<your-anon-key>"
supabase secrets set SERVICE_ROLE_KEY="<your-service-role-key>"

supabase functions deploy delete-account
```

## Client call
The Flutter app calls:
- `Supabase.instance.client.functions.invoke('delete-account')`

Supabase automatically includes the user session JWT in the request.
