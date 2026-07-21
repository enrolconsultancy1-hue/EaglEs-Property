# Cloud Functions implementation notes

## Membership source
The callable functions expect active memberships at:

`users/{uid}/memberships/{tenantId}`

The tenant-scoped membership mirror, if used for admin UI, is:

`tenants/{tenantId}/memberships/{uid}`

Example document:

```json
{
  "active": true,
  "role": "SalesAgent"
}
```

## Client token refresh
After `switchTenant` returns, the client must call `getIdToken(true)` before querying tenant-scoped Firestore data. This prevents stale claims from being used in the next request.
