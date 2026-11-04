# BridanX Business Manager — cloud database setup

This repository now includes a Supabase schema for secure, separate business accounts.

## What the schema provides
- Supabase Auth-compatible user profiles (passwords are handled by Supabase Auth).
- Separate tables for transactions, sales, inventory and customers.
- Row Level Security (RLS) policies so a signed-in user can access only rows belonging to their own user ID.
- Currency and country preferences stored per business profile.

## Setup required before cloud accounts can be switched on
1. Create a dedicated Supabase project for BridanX Business Manager.
2. In that project's SQL Editor, run the complete script in `supabase/schema.sql`.
3. In Supabase Authentication settings, configure the allowed sign-in method and your deployed site's redirect URL.
4. Copy the project's Project URL and its publishable/anon key into the app's public client configuration when the cloud-auth integration is added.
5. Never put a Supabase `service_role` secret in browser code or commit it to GitHub.

## Important
The current dashboard still uses browser localStorage. Adding the schema does not itself activate cloud login, cloud syncing, or migrate existing local records. Those steps require the dedicated Supabase project URL and publishable/anon key, followed by implementation and live testing of authentication, data isolation, and migration.
