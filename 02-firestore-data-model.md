# EaglEs Property — Firestore Database Design

> Primary OLTP store. Every tenant-scoped document carries `tenantId`.
> Naming: camelCase fields, plural collection names, ULID-style doc IDs unless noted.

---

## 1. Design Rules

1. **`tenantId` on every tenant-scoped doc** — even inside subcollections (enables collection-group queries + uniform rules).
2. **Audit envelope on every doc**: `createdAt`, `createdBy`, `updatedAt`, `updatedBy`, `isDeleted` (soft delete), `version`.
3. **Reads are modeled, not computed** — dashboards read pre-aggregated docs; lists read denormalized "card" projections.
4. **Money** stored as `{ amount: int (minor units), currency: 'USD' }` — never floats.
5. **Status machines** — every workflow doc has `status` from a closed enum + `statusHistory[]` (last 20) for traceability.
6. **Search fields** — docs synced to Typesense carry `searchTokens` maintained by trigger (fallback prefix search).
7. Collection-group queries used for: `units`, `tasks`, `invoices`, `leads`, `documents`, `payments`.

## 2. Top-Level Collection Map

```
platform/                          ← singleton config docs (plans, feature catalog)
tenants/{tenantId}                 ← tenant registry + everything tenant-scoped below it
users/{uid}                        ← global user profiles
users/{uid}/memberships/{tenantId} ← per-tenant role assignments
publicListings/{listingId}         ← cross-tenant marketplace projection (read-only to clients)
publicTenantProfiles/{tenantId}    ← public directory
auditLogs/{logId}                  ← immutable platform-wide audit (write: functions only)
mail/{id}, sms/{id}                ← outbound message queues (extension-processed)
```

## 3. Tenant Subtree

```
tenants/{tenantId}
├─ organizations/{orgId}              branches & departments (tree via parentId)
├─ employees/{employeeId}             HR-lite: profile, orgId, position, licenses[]
├─ licenses/{licenseId}               company licenses/permits w/ expiry alerts
├─ projects/{projectId}
│   ├─ phases/{phaseId}               master plan phases
│   ├─ schedule/{taskId}              construction schedule (WBS/Gantt)
│   ├─ milestones/{milestoneId}
│   ├─ budgetLines/{lineId}
│   ├─ dailyReports/{reportId}        site diary: weather, manpower, work done
│   ├─ inspections/{inspectionId}
│   ├─ variationOrders/{voId}
│   ├─ photoLogs/{photoId}            geo/time-tagged, incl. drone captures
│   └─ progress/{snapshotId}          weekly % complete snapshots (S-curve)
├─ buildings/{buildingId}
│   └─ floors/{floorId}
├─ units/{unitId}                     ← FLAT (not nested) — the atomic sellable/leasable asset
├─ leads/{leadId}
│   └─ activities/{activityId}        calls, emails, meetings, notes
├─ opportunities/{oppId}              pipeline deals
├─ reservations/{reservationId}
├─ contracts/{contractId}             sale & lease contracts, e-signature envelope
├─ listings/{listingId}               tenant-side listing master (projects → publicListings)
├─ leases/{leaseId}
│   └─ rentSchedule/{periodId}        generated rent periods
├─ workOrders/{workOrderId}           maintenance & FM jobs
├─ assets/{assetId}                   equipment/asset registry, QR-coded
├─ invoices/{invoiceId}
├─ payments/{paymentId}
├─ expenses/{expenseId}
├─ budgets/{budgetId}                 finance budgets (vs project budgetLines)
├─ documents/{documentId}             DMS metadata (file in Storage)
├─ tickets/{ticketId}                 support tickets
│   └─ messages/{messageId}
├─ conversations/{conversationId}
│   └─ messages/{messageId}           chat
├─ announcements/{announcementId}
├─ notifications/{uid}/items/{id}     per-user in-app notifications
├─ approvals/{approvalId}             generic approval workflow instances
├─ aiInsights/{insightId}             AI outputs: risk scores, forecasts, summaries
├─ dashboards/{dashboardId}           saved dashboard configs
├─ aggregates/{aggregateId}           pre-computed KPI docs (see §6)
├─ settings/{settingId}               currencies, taxes, pipelines, workflows, branding
└─ counters/{counterId}               sharded counters + human-readable sequence numbers
```

## 4. Key Document Schemas

### tenants/{tenantId}
```jsonc
{
  "name": "Skyline Developments PLC",
  "slug": "skyline",
  "type": "developer",              // developer|broker|bank|government|contractor|propertyManager
  "status": "active",               // active|suspended|trial|churned
  "plan": { "id": "enterprise", "seats": 250, "modules": ["projects","construction","crm","finance","rental","fm","ai"] },
  "billing": { "stripeCustomerId": "cus_x", "cycle": "annual", "nextInvoiceAt": 0 },
  "branding": { "logoUrl": "", "primaryColor": "#0B5FFF", "accentColor": "#00C48C", "customDomain": "portal.skyline.com" },
  "locale": { "defaultCurrency": "USD", "currencies": ["USD","ETB"], "timezone": "Africa/Addis_Ababa", "languages": ["en","am"] },
  "limits": { "storageGb": 500, "apiCallsPerDay": 100000 },
  "ownerUid": "uid_x",
  "createdAt": 0, "updatedAt": 0
}
```

### users/{uid} + memberships
```jsonc
// users/{uid}
{
  "displayName": "Sara Bekele", "email": "sara@skyline.com", "phone": "+2519...",
  "photoUrl": "", "defaultTenantId": "skyline",
  "notificationPrefs": { "push": true, "email": true, "sms": false },
  "twoFactor": { "enabled": true, "method": "totp" },
  "presence": { "state": "online", "lastSeen": 0 }
}
// users/{uid}/memberships/{tenantId}
{
  "tenantId": "skyline",
  "roles": ["salesManager"],           // see docs/08 role catalog
  "orgId": "branch_addis",
  "employeeId": "emp_123",
  "status": "active",                  // invited|active|suspended
  "invitedBy": "uid_y", "joinedAt": 0
}
```

### projects/{projectId}
```jsonc
{
  "tenantId": "skyline",
  "code": "PRJ-0042", "name": "Bole Sky Towers",
  "type": "mixedUse",                  // residential|commercial|mixedUse|industrial|hotel|smartCity
  "stage": "construction",             // planning|design|approval|construction|handover|operating
  "location": { "geo": {"lat": 8.99,"lng": 38.79}, "geohash": "sc21x", "address": {...}, "city": "Addis Ababa", "country": "ET" },
  "landAreaSqm": 12000, "gfaSqm": 86000,
  "budget": { "total": {"amount": 250000000000, "currency": "ETB"}, "committed": {...}, "spent": {...} },
  "dates": { "start": 0, "plannedEnd": 0, "forecastEnd": 0 },
  "progress": { "physicalPct": 43.5, "financialPct": 39.2, "spi": 0.94, "cpi": 1.02, "asOf": 0 },
  "team": { "projectManagerUid": "u1", "memberUids": ["u1","u2"] },  // used by rules for project-scoped access
  "aiRisk": { "delayProbability": 0.31, "riskLevel": "medium", "topFactors": ["supplier delay","rain season"], "scoredAt": 0 },
  "counts": { "buildings": 4, "units": 620, "unitsSold": 214 },
  "media": { "coverUrl": "", "masterPlanUrl": "" }
}
```

### units/{unitId} — the central asset doc
```jsonc
{
  "tenantId": "skyline",
  "code": "BST-T2-14-A",
  "projectId": "prj1", "buildingId": "b2", "floorId": "f14",
  "type": "apartment",                 // apartment|villa|townhouse|condo|office|shop|warehouse|parking|land|hotelRoom|...
  "purpose": "sale",                   // sale|rent|leaseToOwn
  "status": "reserved",                // available|held|reserved|sold|rented|blocked|underMaintenance
  "specs": { "bedrooms": 3, "bathrooms": 2, "areaSqm": 142.5, "balconySqm": 12, "floorNumber": 14,
             "view": "city", "finishing": "premium", "parkingSlots": 1 },
  "pricing": {
    "listPrice": {"amount": 1250000000, "currency": "ETB"},
    "pricePerSqm": {"amount": 8771930, "currency": "ETB"},
    "aiEstimate": {"amount": 1310000000, "currency": "ETB", "confidence": 0.82, "asOf": 0},
    "paymentPlanIds": ["pp_2080"]
  },
  "holds": { "heldBy": "uid_sales1", "holdExpiresAt": 0 },   // transactional lock fields
  "currentDeal": { "reservationId": "res9", "buyerName": "A. Tesfaye" },
  "listing": { "isListed": true, "publicListingId": "pl_88" },
  "media": { "coverUrl": "", "gallery": [], "floorPlanUrl": "", "tour3dUrl": "" },
  "searchTokens": ["bst","t2","3br","bole"]
}
```

### leads / opportunities (CRM)
```jsonc
// leads/{leadId}
{
  "tenantId": "skyline",
  "name": "Abel Tesfaye", "phone": "+2519...", "email": "",
  "source": "website",                 // website|walkIn|referral|social|portal|campaign|import
  "interest": { "projectIds": ["prj1"], "unitTypes": ["apartment"], "budgetMax": {"amount":0,"currency":"ETB"}, "purpose": "sale" },
  "stage": "qualified",                // new|contacted|qualified|negotiation|converted|lost
  "ownerUid": "uid_sales1",
  "aiScore": { "value": 87, "band": "hot", "reasons": ["budget match","2 site visits"], "scoredAt": 0 },
  "nextFollowUpAt": 0, "lastActivityAt": 0,
  "consent": { "marketing": true, "recordedAt": 0 }          // GDPR
}
// opportunities/{oppId}
{
  "tenantId": "skyline", "leadId": "lead1", "unitId": "unit1", "projectId": "prj1",
  "stage": "proposal",                 // configurable pipeline; stageOrder for board sort
  "value": {"amount": 1250000000, "currency": "ETB"},
  "probability": 0.6, "expectedCloseAt": 0, "ownerUid": "uid_sales1",
  "lostReason": null
}
```

### reservations → contracts
```jsonc
// reservations/{reservationId}
{
  "tenantId": "skyline", "unitId": "unit1", "leadId": "lead1", "oppId": "opp1",
  "status": "active",                  // pendingPayment|active|converted|expired|cancelled
  "depositInvoiceId": "inv55", "expiresAt": 0, "createdBy": "uid_sales1"
}
// contracts/{contractId}
{
  "tenantId": "skyline",
  "type": "sale",                      // sale|lease|construction|serviceAgreement
  "status": "signing",                 // draft|review|signing|active|completed|terminated
  "parties": [ {"role":"seller","tenantSide":true}, {"role":"buyer","uid":"uid_buyer","name":"..."} ],
  "unitId": "unit1", "projectId": "prj1",
  "value": {"amount":0,"currency":"ETB"},
  "paymentPlan": { "downPct": 20, "installments": 36, "scheduleGenerated": true },
  "signature": { "provider": "docusign", "envelopeId": "env1", "signedBy": [], "completedAt": null },
  "documentId": "doc_912",
  "aiReview": { "riskFlags": ["missing penalty clause"], "summary": "...", "reviewedAt": 0 }
}
```

### construction: schedule tasks & daily reports
```jsonc
// projects/{p}/schedule/{taskId}
{
  "tenantId": "skyline", "projectId": "prj1",
  "wbs": "3.2.1", "name": "Tower 2 — Level 14 slab pour",
  "parentTaskId": "t_32", "dependsOn": [{"taskId":"t_313","type":"FS","lagDays":2}],
  "plannedStart": 0, "plannedEnd": 0, "actualStart": 0, "actualEnd": null,
  "durationDays": 6, "progressPct": 60, "isCritical": true,
  "assignee": { "uid": "uid_se1", "contractorId": "ctr_4" },
  "cost": { "budget": {...}, "actual": {...} },
  "status": "inProgress"               // notStarted|inProgress|blocked|done|cancelled
}
// projects/{p}/dailyReports/{reportId}
{
  "tenantId": "skyline", "projectId": "prj1", "date": "2026-07-22",
  "weather": { "condition": "rain", "tempC": 21, "workStoppedHrs": 2 },
  "manpower": [{"trade":"steel fixer","count":24}], "equipment": [{"name":"tower crane","hrs":8}],
  "workDone": "...", "blockers": "...", "safetyIncidents": 0,
  "photoIds": ["ph1","ph2"], "submittedBy": "uid_se1", "approvedBy": null
}
```

### leases & rent
```jsonc
// leases/{leaseId}
{
  "tenantId": "skyline", "unitId": "unit9", "contractId": "c77",
  "residentUid": "uid_tenant1", "residentName": "M. Alemu",
  "term": { "start": 0, "end": 0, "noticeDays": 60, "autoRenew": false },
  "rent": { "amount": {"amount": 4500000, "currency":"ETB"}, "frequency": "monthly", "escalationPct": 8, "dueDay": 1 },
  "deposit": { "amount": {...}, "status": "held" },
  "status": "active",                  // draft|active|expiring|renewed|terminated|evicted
  "balances": { "outstanding": {...}, "lastPaymentAt": 0 }
}
```

### finance
```jsonc
// invoices/{invoiceId}
{
  "tenantId": "skyline", "number": "INV-2026-00841",
  "type": "installment",               // deposit|installment|rent|serviceCharge|maintenance|custom
  "counterparty": { "uid": "uid_buyer", "name": "...", "kind": "customer" },
  "links": { "contractId": "c77", "unitId": "unit1", "leaseId": null, "projectId": "prj1" },
  "lines": [{"description":"Installment 4/36","qty":1,"unitPrice":{...},"taxPct":15,"total":{...}}],
  "totals": { "subtotal": {...}, "tax": {...}, "grand": {...}, "paid": {...}, "due": {...} },
  "dueAt": 0, "status": "partiallyPaid",   // draft|sent|overdue|partiallyPaid|paid|void
  "pdf": { "documentId": "doc_1", "url": "" }
}
// payments/{paymentId}
{
  "tenantId": "skyline", "invoiceId": "inv841",
  "method": "telebirr",                // stripe|paypal|bankTransfer|telebirr|mpesa|chapa|cash|cheque
  "gateway": { "provider": "telebirr", "txnRef": "TB123", "raw": {...} },
  "amount": {...}, "status": "confirmed",  // initiated|pendingApproval|confirmed|failed|refunded
  "offlineProof": { "receiptDocumentId": "doc_2", "approvedBy": "uid_fin1", "approvedAt": 0 },
  "receivedAt": 0
}
```

### documents (DMS)
```jsonc
{
  "tenantId": "skyline",
  "name": "Tower2-L14-structural.dwg",
  "category": "blueprint",             // blueprint|cad|contract|permit|certificate|photo|video|report|invoice|other
  "storagePath": "tenants/skyline/projects/prj1/docs/xxx.dwg",
  "mime": "application/acad", "sizeBytes": 4823000,
  "links": { "projectId": "prj1", "contractId": null, "unitId": null },
  "versions": [{"v":3,"path":"...","by":"uid","at":0,"note":"rev C"}],
  "access": { "level": "team", "allowedRoles": ["architect","constructionManager"], "allowedUids": [] },
  "ocr": { "status": "done", "textPreview": "...", "language": "en" },
  "ai": { "summary": "...", "tags": ["structural","tower2"] }
}
```

### publicListings/{listingId} — marketplace projection
```jsonc
{
  "sourceTenantId": "skyline", "sourceListingId": "lst1", "sourceUnitId": "unit1",
  "title": "3BR Apartment — Bole Sky Towers", "purpose": "sale",
  "propertyType": "apartment",
  "price": {"amount":0,"currency":"ETB"}, "areaSqm": 142.5, "bedrooms": 3, "bathrooms": 2,
  "location": { "geo": {...}, "geohash": "sc21x", "city": "Addis Ababa", "country": "ET" },
  "media": { "coverUrl": "", "gallery": [], "tour3dUrl": "", "matterportId": "" },
  "amenities": ["gym","pool","backup power"],
  "developer": { "tenantId": "skyline", "name": "Skyline", "logoUrl": "", "verified": true },
  "stats": { "views": 0, "favorites": 0 },      // sharded counters roll up here hourly
  "status": "published",               // published|paused|soldOut
  "publishedAt": 0
}
```

### aggregates/{aggregateId} — dashboard read models
Doc ID convention: `{domain}_{period}_{key}` e.g. `sales_monthly_2026-07`, `occupancy_current_prj1`.
```jsonc
{
  "tenantId": "skyline", "domain": "sales", "period": "2026-07",
  "metrics": { "leadsNew": 412, "conversions": 38, "revenue": {...}, "avgDealDays": 21,
               "pipelineByStage": {"new": 120, "qualified": 60, ...},
               "topAgents": [{"uid":"u1","deals":9}] },
  "computedAt": 0
}
```
Written by scheduled Functions + incremental triggers. **Dashboards read 3–6 aggregate docs — never scan collections.**

## 5. ID & Numbering Strategy

- Doc IDs: client-generated ULIDs (sortable, no hotspots).
- Human numbers (`INV-2026-00841`, `PRJ-0042`): issued transactionally from `counters/{type}` by Functions.

## 6. Composite Indexes (representative)

| Collection (group) | Fields |
|---|---|
| units (CG) | tenantId ASC, projectId ASC, status ASC, pricing.listPrice.amount ASC |
| units (CG) | tenantId, type, status, specs.bedrooms |
| leads | tenantId, ownerUid, stage, nextFollowUpAt |
| leads | tenantId, stage, aiScore.value DESC |
| invoices (CG) | tenantId, status, dueAt |
| schedule (CG) | tenantId, projectId, status, plannedEnd |
| publicListings | status, propertyType, purpose, price.amount |
| publicListings | status, location.geohash (range) |
| workOrders | tenantId, status, priority, dueAt |
| conversations | tenantId, memberUids (array-contains), lastMessageAt DESC |

Geo queries: geohash range queries client-side (geoflutterfire pattern) for map viewport; precision widening for clusters. Full facet/geo search offloaded to Typesense.

## 7. Data Lifecycle

- **Soft delete** (`isDeleted`) everywhere; hard purge by scheduled Function after retention window (tenant-configurable, default 90d).
- **GDPR**: user erasure Function anonymizes PII across CG queries; consent tracked on leads/users.
- **Backups**: daily Firestore export to GCS (35-day retention) + weekly cross-region copy.
- **BigQuery sink**: Firestore export extension on key collections for analytics/AI training.
