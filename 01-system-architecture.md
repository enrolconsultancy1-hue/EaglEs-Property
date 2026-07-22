# EaglEs Property — System Architecture

> Enterprise Multi-Tenant Real Estate Operating System
> Version 1.0 · Architecture Baseline

---

## 1. Vision & Positioning

EaglEs Property is a **Real Estate Operating System (RE-OS)** — not a listing app. One cloud platform unifies the full property lifecycle:

```
LAND ACQUISITION → DESIGN → CONSTRUCTION → SALES/LEASING → OPERATIONS → FACILITY MGMT → RESALE/REINVESTMENT
```

| Capability domain | Benchmark products replaced |
|---|---|
| Marketplace & search | Zillow, LoopNet |
| Market intelligence | CoStar |
| Property & lease operations | RealPage, Yardi Voyager, Oracle PM |
| CRM & sales pipeline | Salesforce, Microsoft Dynamics |
| Financials & asset accounting | SAP RE-FX |
| Construction management | Procore, Autodesk Construction Cloud |
| Work management | Monday.com |

---

## 2. High-Level Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER (Flutter)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────────┐  │
│  │   Web    │ │ Android  │ │   iOS    │ │ Windows  │ │ macOS/Linux │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └─────────────┘  │
│   Single codebase · Material 3 · Riverpod · GoRouter · Offline-first   │
├────────────────────────────────────────────────────────────────────────┤
│                        EDGE / SECURITY LAYER                           │
│  Firebase App Check · Firebase Auth (custom claims) · Cloud Armor      │
│  Firebase Hosting CDN · Remote Config (feature flags per tenant)       │
├────────────────────────────────────────────────────────────────────────┤
│                          SERVICE LAYER (GCP)                           │
│  ┌──────────────────┐ ┌───────────────────┐ ┌──────────────────────┐  │
│  │ Cloud Functions   │ │ Cloud Functions   │ │ Cloud Run (heavy)    │  │
│  │ (callable APIs)   │ │ (triggers/events) │ │ PDF gen, OCR, AI     │  │
│  └──────────────────┘ └───────────────────┘ └──────────────────────┘  │
│  ┌──────────────────┐ ┌───────────────────┐ ┌──────────────────────┐  │
│  │ Cloud Scheduler   │ │ Cloud Tasks       │ │ Pub/Sub (event bus)  │  │
│  │ (rent runs, KPIs) │ │ (retries, queues) │ │ (module decoupling)  │  │
│  └──────────────────┘ └───────────────────┘ └──────────────────────┘  │
├────────────────────────────────────────────────────────────────────────┤
│                            DATA LAYER                                  │
│  Firestore (primary OLTP) · Firebase Storage (docs/media)              │
│  BigQuery (analytics sink via Firestore export) · Typesense/Algolia    │
│  (full-text + geo search index, synced by Functions)                   │
├────────────────────────────────────────────────────────────────────────┤
│                        INTELLIGENCE LAYER                              │
│  Vertex AI (Gemini) — chat assistant, contract review, summaries       │
│  Vertex AI custom models — price estimation, lead scoring, delay pred. │
│  Cloud Vision — image recognition, OCR  ·  Document AI — contracts     │
├────────────────────────────────────────────────────────────────────────┤
│                        INTEGRATION LAYER                               │
│  Stripe · PayPal · Telebirr · M-Pesa · Chapa (payments)                │
│  Google Maps Platform · Matterport SDK · SendGrid (email) ·            │
│  Twilio (SMS/video) · DocuSign/eSignature · Drone/IoT ingestion API    │
├────────────────────────────────────────────────────────────────────────┤
│                        OBSERVABILITY LAYER                             │
│  Crashlytics · Analytics · Cloud Logging · Cloud Monitoring ·          │
│  Performance Monitoring · Audit Log pipeline (immutable)               │
└────────────────────────────────────────────────────────────────────────┘
```

**Key principle:** Firestore is the single source of truth for operational data. Everything heavy (analytics aggregation, AI inference, PDF rendering, search indexing) is pushed out of the client into Functions/Cloud Run, communicating through Pub/Sub events so modules stay decoupled.

---

## 3. Multi-Tenant Architecture

### 3.1 Tenancy model — *Pooled with logical isolation*

One Firebase project pools all tenants (cost-efficient, single deployment), with **hard logical isolation** enforced at four independent layers:

| Layer | Enforcement |
|---|---|
| 1. Identity | `tenantId` + `roles[]` embedded in Firebase Auth **custom claims** (set only by Cloud Functions) |
| 2. Database | Every document carries `tenantId`; Security Rules reject any read/write where `request.auth.token.tenantId != resource.data.tenantId` |
| 3. Storage | Path convention `/tenants/{tenantId}/...` + Storage Rules matching claims |
| 4. API | Every callable Function derives tenant from **claims, never from client input** |

> Enterprise tier option: dedicated Firebase project per tenant ("silo" mode) using the same codebase + Terraform provisioning. The data model is identical, so migration pooled→silo is an export/import.

### 3.2 Tenant anatomy

```
Tenant (e.g. "Developer A")
├─ Branding        → logo, colors, custom domain, white-label config (Remote Config + tenant doc)
├─ Subscription    → plan, module entitlements, seat count, billing (Stripe)
├─ Organizations   → branches, departments
├─ Users           → memberships with roles (a user may belong to MULTIPLE tenants)
├─ Projects        → developments, construction, inventory
├─ Data            → CRM, finance, documents, analytics — all keyed by tenantId
└─ Settings        → currencies, tax, locale, workflow approval chains, feature flags
```

### 3.3 Cross-tenant surfaces (deliberate exceptions)

Two **public, read-only projections** exist outside tenant isolation:

1. **Marketplace** — `publicListings` collection: denormalized, sanitized copies of listings a tenant explicitly publishes. Written only by Cloud Functions.
2. **Platform directory** — tenant public profiles (name, logo) for discovery.

Buyers/tenants/guests interact with these projections; transactional actions (booking, offer) route back into the owning tenant via Functions.

### 3.4 User ↔ tenant relationship

```
users/{uid}                        ← global profile (1 per human)
users/{uid}/memberships/{tenantId} ← role set per tenant
```
Active tenant is selected at login (tenant switcher); a Function mints fresh custom claims (`tenantId`, `roles`, `permissionsHash`) and the client force-refreshes its ID token. **Claims are the runtime authority; Firestore membership docs are the management source.**

---

## 4. Module Architecture

13 modules, each a bounded context with its own feature folder (Flutter), collection group (Firestore), and function group (backend). Modules communicate **only** through:
- Firestore documents (state)
- Pub/Sub domain events (behavior), e.g. `unit.sold`, `invoice.paid`, `task.overdue`, `lease.expiring`

```
                    ┌────────────── AI ASSISTANT (12) ──────────────┐
                    │        reads all modules via service acct      │
┌─────────────┐  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐
│ 1 Developer │  │ 2 Project   │→ │ 3 Construction│→ │ 4 Inventory │
│   Mgmt      │  │   Mgmt      │  │   Mgmt        │  │  (units)    │
└─────────────┘  └─────────────┘  └──────────────┘  └──────┬──────┘
                                                            ↓
┌─────────────┐  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐
│ 8 Rental    │← │ 6 Marketplace│← │ 5 Sales CRM  │← │ 7 Customer  │
│   Mgmt      │  │   (public)   │  │              │  │   Portal    │
└──────┬──────┘  └─────────────┘  └──────┬───────┘  └─────────────┘
       ↓                                  ↓
┌─────────────┐  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐
│ 9 Facilities│  │ 10 Finance  │  │ 11 Documents │  │ 13 Analytics│
│   Mgmt      │→ │             │← │              │  │  (BigQuery) │
└─────────────┘  └─────────────┘  └──────────────┘  └─────────────┘
```

**Event examples driving cross-module automation:**

| Event | Producers | Consumers |
|---|---|---|
| `unit.reserved` | Sales CRM | Inventory (lock unit), Finance (deposit invoice), Notifications |
| `milestone.completed` | Construction | Finance (progress billing), Analytics, Customer Portal (progress update) |
| `invoice.paid` | Finance/payments webhook | CRM (advance pipeline), Rental (receipt), Notifications |
| `lease.expiring(60d)` | Scheduler | Rental (renewal workflow), CRM (retention task) |
| `inspection.failed` | Construction | Tasks (rework), AI (delay risk re-score) |

---

## 5. Scalability & Reliability

| Concern | Strategy |
|---|---|
| Firestore hot-spots | No sequential doc IDs; shard counters for high-write aggregates (views, KPIs) |
| Query fan-out | Denormalized read models (e.g. `unitCards`, `pipelineBoard`) maintained by triggers |
| Search at scale | Typesense/Algolia index (text + geo + facets); Firestore never used for search scans |
| Analytics at scale | Firestore → BigQuery streaming export; dashboards query aggregate docs written back by scheduled jobs |
| Large files | Storage + resumable uploads; CDN via Hosting; thumbnails by Function |
| Regional latency | Multi-region Firestore (nam5/eur3 by deployment); Hosting CDN global |
| Availability | Serverless everywhere → autoscaling; idempotent functions + Cloud Tasks retries |
| Cost control | Aggregate-first reads (dashboard reads 1 doc, not 10k), pagination everywhere, Remote Config kill-switches |

## 6. Offline-First Strategy

- Firestore persistence enabled on all platforms (IndexedDB on web).
- Repository layer returns **streams**; UI renders cached data instantly, syncs when online.
- Mutations queue through Firestore's built-in offline write queue; UI shows `pending sync` chips.
- Conflict policy: last-write-wins for simple fields; **Functions-mediated transactions** for contested resources (unit reservation, payment allocation) — these require connectivity and the UI degrades gracefully ("requires connection" state).
- Site-engineer flows (daily reports, photo logs, inspections) are fully offline-capable: media staged locally, uploaded by background queue.

## 7. Environments

| Env | Firebase project | Purpose |
|---|---|---|
| `dev` | eagles-prop-dev | developer sandbox, emulator-first |
| `staging` | eagles-prop-stg | QA, integration tests, UAT |
| `prod` | eagles-prop-prod | production, App Check enforced |

Flutter flavors (`--dart-define=ENV=`) map 1:1 to projects. See `docs/10-cicd-deployment.md`.

---

*Companion documents: 02 data model · 03 security rules · 04 Flutter architecture · 05 design system · 06 navigation · 07 cloud functions · 08 auth & RBAC · 09 testing · 10 CI/CD · 11 performance · 12 roadmap.*
