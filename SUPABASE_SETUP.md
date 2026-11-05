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


## Automatic school payment detection

The connected BridanX Business Manager Supabase project has the school-payment foundation:
- Each existing student receives a unique `payment_reference` (shown in the student's fee profile and demand note).
- Authenticated webhook events are stored in `school_payment_webhook_events` with duplicate transaction protection.
- The `school-payment-webhook` Edge Function matches a successful notification to the student's payment reference and records it in `school_fee_payments`. The fee balance and receipt history then use the normal school ledger.
- The Edge Function does not collect, hold, transfer, or initiate funds. Parents pay the school's merchant/bank account directly.

### Required server configuration

In Supabase Dashboard → Edge Functions → Secrets, add:
- `BX_SCHOOL_PAYMENT_WEBHOOK_SECRET`: a long random secret known only to the server-side payment connector and the webhook function.

The function URL is:

`https://yuzzpyellyqicyezjvka.supabase.co/functions/v1/school-payment-webhook`

The function accepts a normalized successful-payment notification using HTTPS POST, with the shared secret in the `x-bx-webhook-secret` header. Expected JSON fields:

```json
{
  "provider": "MTN Mobile Money",
  "transaction_id": "provider-unique-transaction-id",
  "payment_reference": "BX-XXXXXXXXXX",
  "amount": 25000,
  "currency": "UGX",
  "status": "SUCCESS",
  "paid_at": "2026-11-05T12:30:00+03:00",
  "payer_phone": "2567XXXXXXXX"
}
```

Use `Airtel Money` or `Bank` for the other provider values. Transaction IDs are deduplicated so provider retries do not create duplicate fee receipts.

### Provider onboarding still required before live automatic detection

This endpoint is the secure common recording endpoint; it is not itself an MTN, Airtel, or bank merchant connection. Before live payments can flow automatically, configure a server-side adapter for the school's actual provider account:
- MTN MoMo Collections production access and callback configuration.
- Airtel Money merchant/API production access and callback configuration.
- The school's bank-specific collection notification/API, or a payment aggregator that supports the school's bank settlement account.

Each adapter must verify the provider's own callback signature/status or query the provider transaction-status API before forwarding a normalized `SUCCESS` event. Never trust a browser-submitted payment confirmation, and never put provider credentials or the webhook secret in `index.html`, localStorage, or GitHub. Test in each provider's sandbox before enabling production callbacks.

**Settlement rule:** configure each provider/aggregator to settle directly to the school's nominated merchant or bank account. BridanX only verifies and records the payment notification.
