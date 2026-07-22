# 13 - Auth & Tenant-Switching Logic

## 1. Authentication Flow
**EaglEs Property** uses Firebase Authentication (Email/Password & Google) as the identity provider, augmented with a custom Claims backend.

### Login Sequence
1. **User Login**: Client app authenticates via Firebase SDK.
2. **Claims Fetch**: The client calls a Cloud Function `onUserLogin` to verify current tenant membership.
3. **Token Refresh**: The Cloud Function sets the `tenantId` and `role` in the ID token custom claims.
4. **Access Granted**: The client forces a token refresh to receive the new claims; Firestore rules now allow access.

---

## 2. Custom Claims Management
Claims are the source of truth for the **Security Rules** (`03-security-rules.md`).

| Claim | Type | Description |
| :--- | :--- | :--- |
| `tenantId` | `string` | The active workspace the user is currently working in. |
| `role` | `string` | The user's permission level (e.g., `SalesAgent`). |
| `tenants` | `array` | List of all tenant IDs the user belongs to (for switching). |

---

## 3. Tenant-Switching Logic
Users (e.g., a shared Sales Consultant) may belong to multiple developer tenants.

### Switching Sequence
1. **Selection**: User selects a different organization from the "Switch Workspace" UI.
2. **Update Request**: Client calls `switchTenant(newTenantId)`.
3. **Validation**: Cloud Function verifies the user is a member of `newTenantId`.
4. **Claim Update**: Cloud Function overwrites the `tenantId` and `role` claims.
5. **Re-Authentication**: Client app calls `user.getIdToken(true)` and redirects to the dashboard.

---

## 4. UI/UX: The Workspace Selector
To maintain the "Salesforce" feel, the workspace selector should be accessible from the global profile menu.

- **Visual Cue**: Dashboard branding (Logo, Colors) must update instantly upon switching.
- **State Clearing**: All local caches and module-specific state must be cleared to prevent data leaking between tenants.

---

## 5. Auth Architecture Diagram

```widget title="auth_architecture"
<svg width="100%" viewBox="0 0 680 360">
  <style>
    .comp-box { fill: var(--color-viz-1-soft); stroke: var(--color-viz-1-ink); stroke-width: 1.5; }
    .comp-text { fill: var(--color-viz-1-ink); font-size: 13px; font-weight: 500; }
    .data-text { fill: var(--color-text-secondary); font-size: 11px; }
    .connector { stroke: var(--color-border-primary); stroke-width: 1.5; fill: none; marker-end: url(#arrow); }
  </style>

  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="10" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--color-border-primary)" />
    </marker>
  </defs>

  <!-- Client -->
  <rect x="40" y="40" width="160" height="260" rx="12" class="comp-box" />
  <text x="120" y="65" text-anchor="middle" class="comp-text">Flutter Client</text>
  <text x="120" y="100" text-anchor="middle" class="data-text">Firebase SDK</text>
  <rect x="60" y="220" width="120" height="40" rx="4" style="fill:var(--color-background-primary); stroke:var(--color-border-primary);" />
  <text x="120" y="240" text-anchor="middle" dominant-baseline="central" style="fill:var(--color-text-primary); font-size:11px;">Tenant Switcher</text>

  <!-- Auth Engine -->
  <rect x="260" y="40" width="160" height="80" rx="8" class="comp-box" style="fill:var(--color-brand-soft); stroke:var(--color-brand-border);" />
  <text x="340" y="65" text-anchor="middle" class="comp-text" style="fill:var(--color-brand-ink);">Firebase Auth</text>
  <text x="340" y="85" text-anchor="middle" class="data-text" style="fill:var(--color-brand-ink);">Identity & JWT</text>

  <!-- Custom Claims Backend -->
  <rect x="260" y="180" width="160" height="80" rx="8" class="comp-box" style="fill:var(--color-viz-5-soft); stroke:var(--color-viz-5-ink);" />
  <text x="340" y="205" text-anchor="middle" class="comp-text" style="fill:var(--color-viz-5-ink);">Cloud Functions</text>
  <text x="340" y="225" text-anchor="middle" class="data-text" style="fill:var(--color-viz-5-ink);">Claims Generator</text>

  <!-- Database -->
  <rect x="480" y="180" width="160" height="80" rx="8" class="comp-box" style="fill:var(--color-viz-3-soft); stroke:var(--color-viz-3-ink);" />
  <text x="560" y="205" text-anchor="middle" class="comp-text" style="fill:var(--color-viz-3-ink);">Firestore</text>
  <text x="560" y="225" text-anchor="middle" class="data-text" style="fill:var(--color-viz-3-ink);">Tenant/Staff Records</text>

  <!-- Connectors -->
  <path d="M 200 80 L 260 80" class="connector" />
  <path d="M 340 120 L 340 180" class="connector" />
  <path d="M 420 220 L 480 220" class="connector" />
  <path d="M 200 240 L 260 220" class="connector" />
</svg>
```
