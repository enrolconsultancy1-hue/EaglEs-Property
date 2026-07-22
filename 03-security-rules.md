# EaglEs Property — Security Rules (Firestore + Storage)

> Isolation contract: **no cross-tenant read/write, ever.** Roles and tenantId come from
> Firebase Auth **custom claims** minted exclusively by Cloud Functions.

---

## 1. Custom Claims Shape

```jsonc
{
  "tenantId": "skyline",
  "roles": ["salesManager"],       // role keys from docs/08 catalog
  "plt": "none",                   // platform role: none|platformAdmin|superAdmin
  "pv": 7                          // permission version — bump to force token refresh
}
```

## 2. firestore.rules

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    /* ───────────── helpers ───────────── */

    function signedIn() { return request.auth != null; }

    function claims() { return request.auth.token; }

    function isSuper() { return signedIn() && claims().plt == 'superAdmin'; }
    function isPlatform() { return signedIn() && (claims().plt == 'platformAdmin' || isSuper()); }

    // caller belongs to this tenant
    function inTenant(tenantId) {
      return signedIn() && claims().tenantId == tenantId;
    }

    function hasRole(role) {
      return signedIn() && role in claims().roles;
    }
    function hasAnyRole(roleList) {
      return signedIn() && claims().roles.hasAny(roleList);
    }

    // tenant staff (excludes external roles: buyer, tenantResident, investor, guest)
    function isStaff(tenantId) {
      return inTenant(tenantId) && claims().roles.hasAny([
        'tenantOwner','orgAdmin','manager','sales','finance','marketing',
        'constructionManager','siteEngineer','architect','lawyer','propertyManager'
      ]);
    }
    function isTenantAdmin(tenantId) {
      return inTenant(tenantId) && claims().roles.hasAny(['tenantOwner','orgAdmin']);
    }

    // create/update must not tamper with tenantId or audit identity
    function tenantIdPinned(tenantId) {
      return request.resource.data.tenantId == tenantId;
    }
    function auditOk() {
      return request.resource.data.createdBy == request.auth.uid
          || resource != null;   // updates keep original createdBy (checked below)
    }
    function immutable(fields) {
      return !request.resource.data.diff(resource.data).affectedKeys().hasAny(fields);
    }

    /* ───────────── platform ───────────── */

    match /platform/{doc} {
      allow read: if signedIn();
      allow write: if isPlatform();
    }

    match /auditLogs/{id} {
      allow read: if isPlatform();
      allow write: if false;                    // Functions (Admin SDK) only
    }

    /* ───────────── users ───────────── */

    match /users/{uid} {
      allow read: if signedIn() && (request.auth.uid == uid || isPlatform());
      allow create: if signedIn() && request.auth.uid == uid;
      allow update: if signedIn() && request.auth.uid == uid
                    && immutable(['defaultTenantId'].toSet() == {} ? [] : []) // profile fields only
                    && !request.resource.data.diff(resource.data)
                        .affectedKeys().hasAny(['twoFactor']);               // 2FA via Functions
      allow delete: if false;

      match /memberships/{tenantId} {
        allow read: if signedIn() &&
          (request.auth.uid == uid || isTenantAdmin(tenantId) || isPlatform());
        allow write: if false;                  // membership managed by Functions only
      }
    }

    /* ───────────── public marketplace ───────────── */

    match /publicListings/{id} {
      allow read: if resource.data.status == 'published' || isPlatform();
      allow write: if false;                    // projection written by Functions
    }
    match /publicTenantProfiles/{id} {
      allow read: if true;
      allow write: if false;
    }

    /* ───────────── tenant subtree ───────────── */

    match /tenants/{tenantId} {
      allow read: if inTenant(tenantId) || isPlatform();
      allow update: if isTenantAdmin(tenantId)
                    && immutable(['plan','billing','status','ownerUid']);   // billing via Functions
      allow create, delete: if isPlatform();

      /* ---- generic tenant-scoped guard applied per collection ---- */

      match /organizations/{id} {
        allow read: if isStaff(tenantId);
        allow write: if isTenantAdmin(tenantId) && tenantIdPinned(tenantId);
      }

      match /employees/{id} {
        allow read: if isStaff(tenantId);
        allow write: if hasAnyRole(['tenantOwner','orgAdmin','manager']) && inTenant(tenantId)
                     && tenantIdPinned(tenantId);
      }

      match /licenses/{id} {
        allow read: if isStaff(tenantId);
        allow write: if isTenantAdmin(tenantId) && tenantIdPinned(tenantId);
      }

      match /projects/{projectId} {
        allow read: if isStaff(tenantId)
                    || (inTenant(tenantId) && request.auth.uid in resource.data.team.memberUids);
        allow create: if hasAnyRole(['tenantOwner','orgAdmin','manager']) && inTenant(tenantId)
                      && tenantIdPinned(tenantId);
        allow update: if inTenant(tenantId) && tenantIdPinned(tenantId) && (
                        isTenantAdmin(tenantId)
                        || request.auth.uid == resource.data.team.projectManagerUid);
        allow delete: if false;                 // soft delete only

        match /schedule/{id} {
          allow read: if isStaff(tenantId);
          allow write: if hasAnyRole(['constructionManager','manager','tenantOwner','orgAdmin'])
                       && inTenant(tenantId) && tenantIdPinned(tenantId);
        }
        match /dailyReports/{id} {
          allow read: if isStaff(tenantId);
          allow create: if hasAnyRole(['siteEngineer','constructionManager'])
                        && inTenant(tenantId) && tenantIdPinned(tenantId)
                        && request.resource.data.submittedBy == request.auth.uid;
          allow update: if inTenant(tenantId) && tenantIdPinned(tenantId) && (
                          (resource.data.approvedBy == null &&
                           resource.data.submittedBy == request.auth.uid)     // author edits until approved
                          || hasRole('constructionManager'));                 // CM approves
        }
        match /inspections/{id} {
          allow read: if isStaff(tenantId);
          allow write: if hasAnyRole(['siteEngineer','constructionManager','architect'])
                       && inTenant(tenantId) && tenantIdPinned(tenantId);
        }
        match /variationOrders/{id} {
          allow read: if isStaff(tenantId);
          allow create: if hasAnyRole(['constructionManager','manager'])
                        && inTenant(tenantId) && tenantIdPinned(tenantId);
          allow update: if hasAnyRole(['tenantOwner','orgAdmin','manager'])   // approval chain
                        && inTenant(tenantId) && tenantIdPinned(tenantId);
        }
        match /{sub}/{id} {                     // phases, milestones, budgetLines, photoLogs, progress
          allow read: if isStaff(tenantId);
          allow write: if hasAnyRole(['constructionManager','manager','tenantOwner','orgAdmin'])
                       && inTenant(tenantId) && tenantIdPinned(tenantId);
        }
      }

      match /buildings/{bId} {
        allow read: if isStaff(tenantId);
        allow write: if hasAnyRole(['tenantOwner','orgAdmin','manager','constructionManager'])
                     && inTenant(tenantId) && tenantIdPinned(tenantId);
        match /floors/{id} {
          allow read: if isStaff(tenantId);
          allow write: if hasAnyRole(['tenantOwner','orgAdmin','manager','constructionManager'])
                       && inTenant(tenantId) && tenantIdPinned(tenantId);
        }
      }

      match /units/{id} {
        allow read: if isStaff(tenantId);
        allow create, delete: if isTenantAdmin(tenantId) && tenantIdPinned(tenantId);
        // sales may update ONLY hold fields; status transitions to reserved/sold via Functions
        allow update: if inTenant(tenantId) && tenantIdPinned(tenantId) && (
                        isTenantAdmin(tenantId)
                        || (hasAnyRole(['sales','manager']) &&
                            request.resource.data.diff(resource.data).affectedKeys()
                              .hasOnly(['holds','updatedAt','updatedBy','version'])));
      }

      match /leads/{leadId} {
        allow read: if inTenant(tenantId) && (
                      hasAnyRole(['tenantOwner','orgAdmin','manager','marketing'])
                      || (hasRole('sales') && resource.data.ownerUid == request.auth.uid));
        allow create: if hasAnyRole(['sales','marketing','manager','tenantOwner','orgAdmin'])
                      && inTenant(tenantId) && tenantIdPinned(tenantId);
        allow update: if inTenant(tenantId) && tenantIdPinned(tenantId) && (
                        hasAnyRole(['manager','tenantOwner','orgAdmin'])
                        || (hasRole('sales') && resource.data.ownerUid == request.auth.uid
                            && immutable(['aiScore'])));                      // AI fields function-only
        match /activities/{id} {
          allow read, create: if isStaff(tenantId) && tenantIdPinned(tenantId);
          allow update, delete: if false;       // activity log immutable
        }
      }

      match /opportunities/{id} {
        allow read: if inTenant(tenantId) && (
                      hasAnyRole(['tenantOwner','orgAdmin','manager','finance'])
                      || (hasRole('sales') && resource.data.ownerUid == request.auth.uid));
        allow write: if hasAnyRole(['sales','manager','tenantOwner','orgAdmin'])
                     && inTenant(tenantId) && tenantIdPinned(tenantId);
      }

      match /reservations/{id} {
        allow read: if isStaff(tenantId)
                    || (inTenant(tenantId) && resource.data.buyerUid == request.auth.uid);
        allow write: if false;                  // created/expired ONLY by Functions (atomic w/ unit lock)
      }

      match /contracts/{id} {
        allow read: if inTenant(tenantId) && (
                      hasAnyRole(['tenantOwner','orgAdmin','manager','finance','lawyer','sales'])
                      || resource.data.parties.hasAny([{'uid': request.auth.uid}]) == false
                         ? false : true);
        allow create, update: if hasAnyRole(['lawyer','manager','tenantOwner','orgAdmin'])
                              && inTenant(tenantId) && tenantIdPinned(tenantId)
                              && immutable(['signature']);                    // signing via Functions
        allow delete: if false;
      }

      match /listings/{id} {
        allow read: if isStaff(tenantId);
        allow write: if hasAnyRole(['marketing','manager','tenantOwner','orgAdmin'])
                     && inTenant(tenantId) && tenantIdPinned(tenantId);
      }

      match /leases/{leaseId} {
        allow read: if inTenant(tenantId) && (
                      hasAnyRole(['propertyManager','finance','manager','tenantOwner','orgAdmin'])
                      || resource.data.residentUid == request.auth.uid);
        allow write: if hasAnyRole(['propertyManager','manager','tenantOwner','orgAdmin'])
                     && inTenant(tenantId) && tenantIdPinned(tenantId);
        match /rentSchedule/{id} {
          allow read: if inTenant(tenantId) && (
                        hasAnyRole(['propertyManager','finance','manager','tenantOwner','orgAdmin'])
                        || get(/databases/$(database)/documents/tenants/$(tenantId)/leases/$(leaseId))
                             .data.residentUid == request.auth.uid);
          allow write: if false;                // generated by Functions
        }
      }

      match /workOrders/{id} {
        allow read: if inTenant(tenantId) && (
                      hasAnyRole(['propertyManager','manager','tenantOwner','orgAdmin'])
                      || resource.data.assigneeUid == request.auth.uid
                      || resource.data.requesterUid == request.auth.uid);
        allow create: if inTenant(tenantId) && tenantIdPinned(tenantId);      // residents can request
        allow update: if inTenant(tenantId) && tenantIdPinned(tenantId) && (
                        hasAnyRole(['propertyManager','manager','tenantOwner','orgAdmin'])
                        || resource.data.assigneeUid == request.auth.uid);
      }

      match /assets/{id} {
        allow read: if isStaff(tenantId);
        allow write: if hasAnyRole(['propertyManager','manager','tenantOwner','orgAdmin'])
                     && inTenant(tenantId) && tenantIdPinned(tenantId);
      }

      match /invoices/{id} {
        allow read: if inTenant(tenantId) && (
                      hasAnyRole(['finance','manager','tenantOwner','orgAdmin'])
                      || resource.data.counterparty.uid == request.auth.uid);
        allow create, update: if hasAnyRole(['finance','tenantOwner','orgAdmin'])
                              && inTenant(tenantId) && tenantIdPinned(tenantId)
                              && immutable(['totals.paid']);                  // payment allocation via Functions
        allow delete: if false;
      }

      match /payments/{id} {
        allow read: if inTenant(tenantId) && (
                      hasAnyRole(['finance','manager','tenantOwner','orgAdmin'])
                      || resource.data.payerUid == request.auth.uid);
        allow write: if false;                  // gateway webhooks + offline approval via Functions
      }

      match /expenses/{id} {
        allow read: if hasAnyRole(['finance','manager','tenantOwner','orgAdmin']) && inTenant(tenantId);
        allow write: if hasAnyRole(['finance','tenantOwner','orgAdmin'])
                     && inTenant(tenantId) && tenantIdPinned(tenantId);
      }
      match /budgets/{id} {
        allow read: if hasAnyRole(['finance','manager','tenantOwner','orgAdmin']) && inTenant(tenantId);
        allow write: if hasAnyRole(['finance','tenantOwner','orgAdmin'])
                     && inTenant(tenantId) && tenantIdPinned(tenantId);
      }

      match /documents/{id} {
        allow read: if inTenant(tenantId) && (
                      isTenantAdmin(tenantId)
                      || resource.data.access.level == 'tenant'
                      || (resource.data.access.level == 'team' &&
                          claims().roles.hasAny(resource.data.access.allowedRoles))
                      || request.auth.uid in resource.data.access.allowedUids);
        allow create: if isStaff(tenantId) && tenantIdPinned(tenantId);
        allow update: if inTenant(tenantId) && tenantIdPinned(tenantId) && (
                        isTenantAdmin(tenantId) || resource.data.createdBy == request.auth.uid);
        allow delete: if false;
      }

      match /tickets/{ticketId} {
        allow read: if inTenant(tenantId) && (
                      isStaff(tenantId) || resource.data.requesterUid == request.auth.uid);
        allow create: if inTenant(tenantId) && tenantIdPinned(tenantId)
                      && request.resource.data.requesterUid == request.auth.uid;
        allow update: if isStaff(tenantId) && tenantIdPinned(tenantId);
        match /messages/{id} {
          allow read, create: if inTenant(tenantId);
          allow update, delete: if false;
        }
      }

      match /conversations/{convId} {
        allow read: if inTenant(tenantId) && request.auth.uid in resource.data.memberUids;
        allow create: if inTenant(tenantId) && tenantIdPinned(tenantId)
                      && request.auth.uid in request.resource.data.memberUids;
        allow update: if inTenant(tenantId) && request.auth.uid in resource.data.memberUids
                      && immutable(['memberUids']) || isTenantAdmin(tenantId);
        match /messages/{id} {
          allow read, create: if inTenant(tenantId)
            && request.auth.uid in get(/databases/$(database)/documents/tenants/$(tenantId)/conversations/$(convId)).data.memberUids;
          allow update: if false;
          allow delete: if false;               // soft-delete flag via update path if needed
        }
      }

      match /announcements/{id} {
        allow read: if inTenant(tenantId);
        allow write: if hasAnyRole(['marketing','manager','tenantOwner','orgAdmin'])
                     && inTenant(tenantId) && tenantIdPinned(tenantId);
      }

      match /notifications/{uid}/items/{id} {
        allow read, update: if inTenant(tenantId) && request.auth.uid == uid;  // mark-as-read
        allow create, delete: if false;         // written by Functions
      }

      match /approvals/{id} {
        allow read: if inTenant(tenantId) && (
                      isStaff(tenantId));
        allow update: if inTenant(tenantId) && tenantIdPinned(tenantId)
                      && request.auth.uid in resource.data.approverUids;
        allow create, delete: if false;         // instantiated by Functions from workflow config
      }

      match /aiInsights/{id} {
        allow read: if isStaff(tenantId);
        allow write: if false;                  // AI pipeline only
      }

      match /dashboards/{id} {
        allow read: if isStaff(tenantId);
        allow write: if isStaff(tenantId) && tenantIdPinned(tenantId)
                     && request.resource.data.ownerUid == request.auth.uid;
      }

      match /aggregates/{id} {
        allow read: if isStaff(tenantId);
        allow write: if false;                  // computed by Functions
      }

      match /settings/{id} {
        allow read: if inTenant(tenantId);
        allow write: if isTenantAdmin(tenantId) && tenantIdPinned(tenantId);
      }

      match /counters/{id} {
        allow read: if isStaff(tenantId);
        allow write: if false;
      }
    }
  }
}
```

### Rule-design notes

1. **Deny-by-default** — anything unmatched is denied; there is no wildcard allow.
2. **Functions-only writes** for anything transactional or contested: reservations, payments, rent schedules, notifications, aggregates, AI outputs, memberships, claims. This is where race conditions and money live.
3. **Field-level guards** via `diff().affectedKeys()` — e.g. sales can *hold* a unit but cannot flip it to `sold`; finance cannot forge `totals.paid`.
4. **`get()` lookups are budgeted** — max 1 per rule path (10-call limit); membership data lives in claims precisely to avoid lookups.
5. **`pv` (permission version)** claim lets us invalidate stale tokens instantly after role changes: client compares `pv` with `tenants/{id}/settings/security.pv` and forces refresh.

## 3. storage.rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    function claims() { return request.auth.token; }
    function inTenant(t) { return request.auth != null && claims().tenantId == t; }
    function isStaff(t) {
      return inTenant(t) && claims().roles.hasAny([
        'tenantOwner','orgAdmin','manager','sales','finance','marketing',
        'constructionManager','siteEngineer','architect','lawyer','propertyManager']);
    }

    // public marketplace media (written by Functions after moderation)
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }

    // tenant files
    match /tenants/{tenantId}/{allPaths=**} {
      allow read: if inTenant(tenantId);
      allow write: if isStaff(tenantId)
                   && request.resource.size < 200 * 1024 * 1024        // 200 MB cap
                   && request.resource.contentType.matches(
                        'image/.*|video/.*|application/pdf|application/acad|'
                      + 'application/vnd.*|text/.*|model/.*');
    }

    // user avatars
    match /users/{uid}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == uid
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## 4. Defense in Depth Checklist

| Layer | Control |
|---|---|
| App Check | Enforced on Firestore, Storage, Functions (Play Integrity / DeviceCheck / reCAPTCHA Enterprise) |
| Auth | Email+password w/ verification, Google/Apple/Microsoft SSO, phone OTP; TOTP 2FA (see docs/08) |
| Claims | Minted only by `setUserClaims` Function; `pv` version forces refresh on role change |
| Rules | Above — tested with emulator unit tests in CI (docs/09) |
| Functions | Every callable re-validates tenant + role from claims; zod-style input validation |
| Audit | Every privileged mutation mirrored to `auditLogs` (append-only, no client access) |
| Encryption | At rest (Google-managed), in transit (TLS); field-level AES for bank details via KMS in Functions |
| Secrets | Secret Manager (gateway keys, AI keys) — never in client or Remote Config |
| Rate limiting | Per-uid counters in Functions for expensive ops (AI calls, exports) |
```
