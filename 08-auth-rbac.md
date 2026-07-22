# EaglEs Property — Authentication Flow & Role Permission Matrix

> Firebase Auth · custom claims minted only by Cloud Functions · TOTP 2FA · multi-tenant memberships
> Companion to docs/03 (rules) and docs/07 (identity functions).

---

## 1. Role Catalog

Two role planes, never mixed:

**Platform plane** (`plt` claim — cross-tenant, EaglEs staff only)

| Key | Scope |
|---|---|
| `superAdmin` | Full platform control incl. billing config, tenant lifecycle, impersonation (audited) |
| `platformAdmin` | Tenant support ops, logs, AI monitoring — no billing config, no impersonation |

**Tenant plane** (`roles[]` claim — per active tenant, from membership doc)

| Key | Persona | Class |
|---|---|---|
| `tenantOwner` | Owns the tenant, billing authority | staff-admin |
| `orgAdmin` | Organization admin | staff-admin |
| `manager` | General/branch manager | staff |
| `sales` | Sales agent | staff |
| `finance` | Finance officer | staff |
| `marketing` | Marketing officer | staff |
| `constructionManager` | Construction lead | staff |
| `siteEngineer` | Field engineer | staff |
| `architect` | Design consultant | staff |
| `lawyer` | Legal counsel | staff |
| `propertyManager` | FM & rental ops | staff |
| `tenantResident` | Renting resident | external |
| `buyer` | Purchaser | external |
| `investor` | Investor (read-heavy) | external |
| `guest` | Anonymous / marketplace visitor | external (no membership) |

A membership may hold multiple roles (e.g. `["manager","finance"]`); permissions are the union.

## 2. Permission Matrix

Legend: **F** full (CRUD + approve) · **W** create/update within scope · **O** own-records only · **R** read · **–** none.
"Scope" columns already account for rules-level field guards (docs/03) — e.g. sales W on units means *hold fields only*.

| Capability | tenantOwner | orgAdmin | manager | sales | finance | marketing | constrMgr | siteEng | architect | lawyer | propMgr | resident | buyer | investor |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Company profile, branches, depts | F | F | R | R | R | R | R | R | R | R | R | – | – | – |
| Employees & licenses | F | F | W | R | R | R | R | R | R | R | R | – | – | – |
| Projects (create/config) | F | F | W | R | R | R | R | O(team) | O(team) | R | R | – | – | R* |
| Schedule / Gantt / milestones | F | F | W | – | R | – | F | R | R | – | – | – | – | R* |
| Daily reports | F | F | R | – | – | – | F(approve) | W(own) | R | – | – | – | – | – |
| Inspections | F | F | R | – | – | – | W | W | W | – | – | – | – | – |
| Variation orders | F(approve) | F(approve) | W(approve) | – | R | – | W(create) | R | R | R | – | – | – | – |
| Buildings / floors / units | F | F | W | W(hold) | R | R | W | R | R | – | R | – | – | R* |
| Leads | F | F | F | O | – | W | – | – | – | – | – | – | – | – |
| Opportunities / pipeline | F | F | F | O | R | R | – | – | – | – | – | – | – | – |
| Reservations | R | R | R | R(via Fn) | R | – | – | – | – | – | – | – | O | – |
| Contracts | F | F | W | R | R | – | – | – | – | F | R | O | O | – |
| Listings (tenant master) | F | F | W | R | – | F | – | – | – | – | R | – | – | – |
| Publish to marketplace | F | F | W | – | – | W(via Fn) | – | – | – | – | – | – | – | – |
| Leases & rent schedule | F | F | W | – | R | – | – | – | – | R | F | O | – | R* |
| Work orders | F | F | W | – | – | – | – | – | – | – | F | O(create) | O(create) | – |
| Assets registry | F | F | R | – | R | – | – | – | – | – | F | – | – | – |
| Invoices | F | F | R | R(own deals) | F | – | – | – | – | – | R | O | O | – |
| Payments / offline approval | F | F | R | – | F(approve) | – | – | – | – | – | R | O | O | – |
| Expenses & budgets | F | F | R | – | F | – | R(project) | – | – | – | – | – | – | – |
| Documents (DMS) | F | F | W | W | W | W | W | W | W | W | W | O(shared) | O(shared) | O(shared) |
| Chat / tickets / announcements | F | F | W | W | W | F(announce) | W | W | W | W | W | O | O | O |
| AI assistant & insights | F | F | W | W | W | W | W | W | W | W | W | – | – | – |
| Analytics dashboards | F | F | R | R(sales) | R(finance) | R(mktg) | R(constr) | – | – | – | R(fm) | – | – | R* |
| Tenant settings / branding | F | F | – | – | – | – | – | – | – | – | – | – | – | – |
| Billing & subscription | F | – | – | – | – | – | – | – | – | – | – | – | – | – |
| Member invite / role change | F | F | – | – | – | – | – | – | – | – | – | – | – | – |
| Audit log (tenant view) | F | F | – | – | – | – | – | – | – | – | – | – | – | – |

\* `investor` reads only through **investor-shared dashboards/projects** explicitly granted via `access.allowedUids` — not blanket access.

**Enforcement stack** (same matrix, three layers):
1. `PermissionSet.fromRoles()` in Flutter — UX gating (nav, buttons, form fields).
2. Firestore/Storage Rules — hard enforcement (docs/03).
3. Callable Functions `assertAnyRole()` — transactional operations.
A single generated source (`permissions.yaml` → codegen for Dart + TS + rules test fixtures) keeps the three in sync.

## 3. Authentication Methods

| Method | Audience | Notes |
|---|---|---|
| Email + password | all | email verification required before workspace access |
| Google / Apple / Microsoft SSO | staff & customers | Apple required for iOS release |
| Phone OTP | buyers/residents (mobile-first markets) | fallback + primary in ET/KE |
| TOTP 2FA | staff (enforced for admin roles, optional otherwise) | secret KMS-encrypted; recovery codes issued once |
| Anonymous | marketplace guests | upgradeable via linkWithCredential (favorites survive) |

## 4. Auth Flows

### 4.1 Sign-up & first login (staff, invited)
```
Admin → inviteMember(email, roles)          [Fn: seat check, invitation doc, email]
User clicks /auth/invite/:token
 → create account (any method) → verify email
 → acceptInvite(token)                      [Fn: membership doc, claims {tenantId, roles, pv}]
 → client refreshes ID token → guards pass → role landing (docs/06 §7)
```

### 4.2 Tenant provisioning (self-serve)
```
/auth/sign-up → /onboarding wizard:
 1 company info → 2 plan select (Stripe checkout) → 3 branding → 4 first project (optional) → 5 invite team
provisionTenant Fn: tenant doc + settings seed + counters + pipelines + caller = tenantOwner + claims
```

### 4.3 Login with 2FA
```
password/SSO ok → claims say totpEnrolled
 → /auth/2fa (6-digit) → verifyTotp Fn → session flag (secure storage, per-device, 30d trust option)
 → failed x5 → lockout 15m + email alert + audit
```

### 4.4 Tenant switch
```
switcher → setActiveTenant(tenantId)        [Fn validates membership, re-mints claims, bumps nothing]
 → force token refresh → CurrentTenant invalidated → router redirect re-runs → branded theme swaps
```

### 4.5 Claims lifecycle & revocation
- Role change → `setMemberRoles` Fn updates membership, re-mints claims, bumps tenant `settings/security.pv`.
- Clients listen to `settings/security` doc; on `pv` mismatch with token → silent `getIdToken(true)`.
- Suspension → membership `status: suspended` + claims stripped + `revokeRefreshTokens(uid)`; rules deny within ≤1h token expiry, client kick within seconds via pv listener.
- Password reset / suspected compromise → refresh-token revocation + re-auth required for sensitive ops (`reauthenticateWithCredential` before billing/role screens).

### 4.6 Session security
- ID token: 1h life, auto-refresh; refresh token revocable server-side.
- Web: `browserLocalPersistence` default, `browserSessionPersistence` for shared-device mode.
- App Check enforced on all backends; suspected-bot sign-ins hit reCAPTCHA Enterprise step-up.
- Every auth event (login, 2FA fail, role change, impersonation) → `auditLogs`.

## 5. Impersonation (support)

`superAdmin` only: `impersonateStart(tenantId, uid)` mints short-lived (15 min) claims copy flagged `imp: true`; banner shown in UI; all writes audited with both identities; no access to payment methods or 2FA settings.
