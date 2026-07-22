# EaglEs Property — Cloud Functions Design

> Node.js 20 · TypeScript · Functions v2 · Region: multi (us-central1 primary, europe-west1 mirror for EU tenants)
> Structure mirrors app modules. All callables enforce App Check + claims validation + zod input schemas.

---

## 1. Codebase Layout

```
functions/
├─ src/
│  ├─ index.ts                     # exports grouped by module
│  ├─ lib/
│  │  ├─ auth.ts                   # assertTenant(), assertRole(), claims helpers
│  │  ├─ audit.ts                  # writeAudit() — every privileged mutation
│  │  ├─ events.ts                 # publishEvent() → Pub/Sub topic 'domain-events'
│  │  ├─ money.ts                  # minor-unit arithmetic, FX table
│  │  ├─ counters.ts               # transactional sequence numbers
│  │  ├─ validation.ts             # zod schemas per callable
│  │  └─ firestore.ts              # typed converters, batch helpers
│  ├─ identity/                    # claims, memberships, invitations, 2FA
│  ├─ tenancy/                     # tenant provisioning, branding, plans
│  ├─ crm/                         # lead intake, scoring trigger, assignment
│  ├─ deals/                       # reservation tx, contract lifecycle, e-sign webhooks
│  ├─ construction/                # schedule rollups, report approval, delay scoring
│  ├─ rental/                      # rent schedule generation, rent run, reminders
│  ├─ finance/                     # invoicing, payment webhooks, allocation, offline approval
│  ├─ marketplace/                 # listing publish/unpublish projection, view counters
│  ├─ documents/                   # thumbnails, OCR pipeline, virus scan hook
│  ├─ comms/                       # FCM fanout, email/SMS queue, announcement fanout
│  ├─ ai/                          # assistant, price estimate, lead score, contract review
│  ├─ analytics/                   # aggregate builders (scheduled + incremental)
│  └─ housekeeping/                # backups, purges, license expiry alerts, GDPR erasure
└─ test/                           # vitest + firebase emulator suites
```

## 2. Function Catalog

### Identity & tenancy
| Function | Type | Purpose |
|---|---|---|
| `provisionTenant` | callable | Create tenant, seed settings/counters/pipelines, make caller `tenantOwner`, mint claims |
| `inviteMember` | callable | Create invitation doc + email; validates seat limits |
| `acceptInvite` | callable | Token → membership doc + claims refresh signal |
| `setMemberRoles` | callable | Admin-only; updates membership, bumps `pv`, revokes if suspended |
| `setActiveTenant` | callable | Re-mints claims for chosen membership |
| `onUserCreated` | auth trigger | Global profile bootstrap, welcome email |
| `enrollTotp` / `verifyTotp` | callable | 2FA lifecycle (secret in KMS-encrypted doc) |

### Deals & sales (transactional core)
| Function | Type | Purpose |
|---|---|---|
| `reserveUnit` | callable | **Atomic tx**: verify unit `available/held-by-caller` → create reservation + deposit invoice + set unit `reserved` + counters + event `unit.reserved`. Conflict → `ConflictFailure` |
| `cancelReservation` | callable + scheduled sweep | Release unit, void deposit invoice if unpaid |
| `convertReservationToContract` | callable | Generates contract from template + payment schedule |
| `sendForSignature` / `onSignatureWebhook` | callable + https | e-sign envelope lifecycle; on complete → contract `active`, unit `sold`, event |
| `onLeadWritten` | trigger | enqueue AI scoring; SLA follow-up task creation |
| `assignLead` | callable | round-robin / territory assignment honoring working hours |

### Finance
| Function | Type | Purpose |
|---|---|---|
| `createInvoice` | callable | Sequence number, tax calc, PDF render (Cloud Run), event |
| `stripeWebhook` / `paypalWebhook` / `telebirrCallback` / `mpesaCallback` / `chapaCallback` | https | Signature-verified; idempotency keys; → `recordPayment` core |
| `recordPayment` | internal | **Atomic tx**: payment doc + invoice allocation + balances + receipts + event `invoice.paid` |
| `approveOfflinePayment` | callable | Finance role; proof doc required; then `recordPayment` |
| `generateRentRun` | scheduled (monthly) | Materialize rent invoices from active leases; escalations applied |
| `sendPaymentReminders` | scheduled (daily) | Overdue ladder: T-3 email → T0 push → T+3 SMS → T+14 escalate |

### Construction & rental ops
| Function | Type | Purpose |
|---|---|---|
| `onScheduleTaskWritten` | trigger | Roll up progress % to project; recompute critical path flag queue |
| `approveDailyReport` | callable | CM sign-off; locks report; photos → gallery index |
| `onInspectionFailed` | trigger | Create rework task; notify; AI risk re-score enqueue |
| `leaseLifecycle` | scheduled (daily) | Flag `expiring` at T-60/T-30; renewal workflow instantiation; vacancy stats |

### Marketplace & search
| Function | Type | Purpose |
|---|---|---|
| `publishListing` | callable | Sanitize tenant listing → `publicListings` projection + Typesense upsert + media copy to `/public` |
| `onListingSourceChanged` | trigger | Price/status sync to projection; sold-out auto-pause |
| `trackListingView` | callable (rate-limited) | Sharded counter increment; hourly rollup to `stats` |
| `syncSearchIndex` | trigger (units, leads, docs, listings) | Typesense upsert/delete |

### AI pipeline
| Function | Type | Purpose |
|---|---|---|
| `aiAssistantChat` | callable (streaming) | Gemini w/ tenant-scoped RAG (Vertex AI Search over tenant docs + aggregates); tool-calling into read-only queries; per-tenant quota |
| `aiScoreLead` | task queue | Features: budget fit, engagement, recency, source quality → score+reasons |
| `aiEstimatePrice` | task queue (nightly + on-demand) | Comparables regression (BigQuery features) → `pricing.aiEstimate` |
| `aiPredictDelay` | task queue (weekly) | Schedule slippage, weather, supplier, inspection failures → project `aiRisk` |
| `aiReviewContract` | callable | Document AI parse → clause checklist → risk flags + summary |
| `aiOcrDocument` | Storage trigger | Vision OCR → `ocr.*` fields → search index |
| `aiInvestmentScore` | task queue | Yield, appreciation forecast, liquidity → listing score |

### Analytics & housekeeping
| Function | Type | Purpose |
|---|---|---|
| `buildAggregates` | scheduled (hourly/daily) | sales, occupancy, cashflow, construction KPI docs per tenant |
| `onDomainEvent` | Pub/Sub | incremental aggregate patches + notification fanout routing |
| `exportToBigQuery` | extension | analytics sink |
| `dailyBackup` | scheduled | Firestore export to GCS |
| `purgeSoftDeleted` | scheduled | retention-window hard delete |
| `licenseExpiryAlerts` | scheduled | company licenses & permits T-30 alerts |
| `gdprEraseUser` | callable (platform) | PII anonymization across collection groups |

## 3. Reference Implementation — `reserveUnit`

```ts
export const reserveUnit = onCall({ enforceAppCheck: true, region: REGION }, async (req) => {
  const { tenantId, uid, roles } = assertTenantMember(req.auth);
  assertAnyRole(roles, ['sales', 'manager', 'tenantOwner', 'orgAdmin']);

  const input = ReserveUnitSchema.parse(req.data);   // { unitId, leadId, oppId?, holdMinutes? }

  const db = getFirestore();
  const unitRef = db.doc(`tenants/${tenantId}/units/${input.unitId}`);
  const resRef  = db.collection(`tenants/${tenantId}/reservations`).doc(ulid());
  const invRef  = db.collection(`tenants/${tenantId}/invoices`).doc(ulid());

  const result = await db.runTransaction(async (tx) => {
    const unit = (await tx.get(unitRef)).data();
    if (!unit) throw new HttpsError('not-found', 'UNIT_NOT_FOUND');
    const holdOk = unit.status === 'available' ||
      (unit.status === 'held' && unit.holds?.heldBy === uid && unit.holds.holdExpiresAt > Date.now());
    if (!holdOk) throw new HttpsError('failed-precondition', 'UNIT_NOT_AVAILABLE');

    const settings = (await tx.get(db.doc(`tenants/${tenantId}/settings/sales`))).data()!;
    const invoiceNumber = await nextSequence(tx, tenantId, 'invoice');   // counters tx
    const deposit = calcDeposit(unit.pricing.listPrice, settings.depositPct);

    tx.update(unitRef, { status: 'reserved', holds: FieldValue.delete(),
      currentDeal: { reservationId: resRef.id }, updatedAt: now(), updatedBy: uid, version: FieldValue.increment(1) });
    tx.set(resRef, reservationDoc({ tenantId, unit, input, uid, invRef, expiresAt: now() + settings.reservationTtlMs }));
    tx.set(invRef, depositInvoiceDoc({ tenantId, number: invoiceNumber, deposit, resRef, unit, uid }));
    return { reservationId: resRef.id, invoiceId: invRef.id, deposit };
  });

  await Promise.all([
    writeAudit({ tenantId, uid, action: 'unit.reserve', target: input.unitId, meta: result }),
    publishEvent('unit.reserved', { tenantId, ...result, unitId: input.unitId, leadId: input.leadId }),
  ]);
  return result;
});
```

**Patterns enforced everywhere:** claims-derived tenant (never from input) · zod validation · transactions for contested state · idempotency keys on webhooks (`gateway.txnRef` unique index doc) · audit + event after commit · typed HttpsError codes the client maps to `Failure`s.

## 4. Payment Gateway Abstraction

```
PaymentProvider (interface)
├─ StripeProvider     (cards, Apple/Google Pay)  — PaymentIntents + webhook
├─ PayPalProvider     — Orders API + webhook
├─ TelebirrProvider   — H5/USSD initiation + notify URL callback
├─ MpesaProvider      — STK push + callback
├─ ChapaProvider      — hosted checkout + webhook
└─ OfflineProvider    — proof upload → finance approval queue
```
Uniform lifecycle: `initiate → pending → confirmed|failed → (refund)`. All callbacks verify signatures, check idempotency, then call the same `recordPayment` transaction. FX conversion uses a daily-rate table doc; invoices pin the rate at issuance.

## 5. Messaging Fanout

`onDomainEvent` routes events → notification templates → per-user channel prefs → FCM (device tokens), `mail/` queue (SendGrid extension), `sms/` queue (Twilio). In-app copies written to `notifications/{uid}/items`. Announcement fanout batches at 500 writes/batch with Cloud Tasks continuation.
```
