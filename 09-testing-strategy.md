# EaglEs Property — Testing Strategy

> Test what breaks trust first: tenant isolation, money, contested state.
> Everything runs against the **Firebase Emulator Suite** — no test ever touches a live project.

---

## 1. Test Pyramid & Targets

| Layer | Tooling | Scope | Volume / gate |
|---|---|---|---|
| 1. Dart unit | `flutter_test`, mocktail | entities, use cases, mappers, formatters, PermissionSet | fast, thousands; **domain 90%+ coverage** |
| 2. Provider/controller | riverpod test utils, ProviderContainer overrides | controllers, guards, Result flows | per feature |
| 3. Widget | `flutter_test` + fake repos | screens, widgets, empty/error/loading states | key flows per feature |
| 4. Golden | `alchemist`/golden_toolkit | design-system widgets light+dark+RTL, 4 breakpoints | every `core/widgets` component |
| 5. Rules tests | `@firebase/rules-unit-testing` (vitest) | **every match block, every role** | isolation suite is CI-blocking |
| 6. Functions tests | vitest + emulator (Firestore/Auth/PubSub) | callables, triggers, webhooks, transactions | money paths 100% |
| 7. Integration (Flutter) | `integration_test` + emulator suite, seeded fixtures | cross-layer flows incl. offline | ~20 core journeys |
| 8. E2E smoke | Patrol (mobile) / Playwright (web) on staging | release gate journeys | 6–8 scripts |

Overall repo coverage gate: **80% lines** (domain 90%, functions money paths 100%). Coverage is a floor, not a goal — critical-path checklist below is the real gate.

## 2. Critical-Path Suites (CI-blocking)

### 2.1 Tenant-isolation suite (rules)
For every tenant-scoped collection, auto-generated cases assert:
```
✗ tenantB staff reads /tenants/A/** → PERMISSION_DENIED
✗ tenantB staff writes /tenants/A/** → PERMISSION_DENIED
✗ user without claims reads anything tenant-scoped → DENIED
✗ create with body.tenantId != path tenantId → DENIED  (tenantIdPinned)
✗ role X writes field guarded from X (e.g. sales sets unit.status=sold) → DENIED
✓ role X allowed matrix cases (from permissions.yaml fixtures) → ALLOWED
```
The suite is generated from the same `permissions.yaml` that drives Dart/TS codegen (docs/08 §2) — a matrix change without a matching rules change fails CI.

### 2.2 Money suite (functions)
- `reserveUnit`: concurrent double-reservation race (two tx in parallel → exactly one wins, `ConflictFailure` for the other); deposit invoice math in minor units; counters uniqueness under contention.
- `recordPayment`: allocation across partial payments; over-payment rejection; idempotent webhook replay (same `gateway.txnRef` twice → single payment doc).
- Gateway webhooks: signature verification failure → 401 + no writes; malformed payload → no partial state.
- `generateRentRun`: escalation %, proration for mid-month start, no duplicate invoices on re-run (idempotency window).
- FX: invoice pins issuance rate; totals recompute never drift (property-based tests on line/tax math).

### 2.3 Claims & auth suite
- acceptInvite mints claims matching membership; setMemberRoles bumps `pv`; suspended member callable access → denied; impersonation TTL expiry.

## 3. Flutter Test Conventions

```
test/                         mirrors lib/ structure
├─ features/crm/domain/...    pure unit
├─ features/crm/presentation/ widget + controller
├─ core/widgets/goldens/      golden per widget × (light|dark) × (compact|expanded)
integration_test/
├─ flows/reserve_unit_test.dart
├─ flows/offline_daily_report_test.dart
└─ fixtures/seed.ts           emulator seed script (same fixtures as functions tests)
```

- Fake repositories implement domain interfaces (no Firestore mocks in widget tests).
- One `TestApp` harness: ProviderScope overrides + fake router + fixed locale/theme; screens tested at 2+ breakpoints via `tester.binding.window` sizing.
- Offline tests: emulator network toggled (`disableNetwork`) → write → assert pending-sync chip → re-enable → assert reconciliation.
- Every `Failure` subtype has a widget test proving `FailureView` copy + retry behavior.

## 4. Integration Journeys (emulator-seeded)

1. Sign-in → tenant select → dashboard renders aggregates.
2. Lead → qualify → hold unit → reserveUnit → deposit invoice appears → pay (fake gateway) → unit `sold`.
3. Site engineer offline: daily report draft autosave → submit offline → sync → CM approves.
4. Lease creation → rent run generation → resident portal shows invoice → offline payment proof → finance approves.
5. Publish listing → appears in `/market/search` → guest favorite → sign-up upgrade keeps favorites.
6. Role change mid-session → pv bump → UI permissions update without relogin.

## 5. Non-Functional Testing

| Concern | Method |
|---|---|
| Performance budgets | `integration_test` timeline: dashboard first-frame < 1.5s on mid Android; frame build < 16ms on scroll of 1k-row DataTableX (docs/11) |
| Contrast/a11y | build-time contrast test on token pairs (4.5:1); `flutter_test` semantics audits on key screens |
| Load (backend) | k6 scripts against staging: 500 rps marketplace reads, 50 concurrent reservations on one project |
| Security | OWASP checklist per release; rules suite; dependency audit (`osv-scanner`, `npm audit`) in CI |
| Chaos-lite | functions tests inject Firestore aborts/timeouts → verify retry/idempotency |

## 6. Quality Gates in CI (see docs/10)

PR → `analyze` + `format` + unit/widget + rules suite + functions unit (≤10 min).
Merge to `develop` → + goldens + integration (emulator) + coverage gate.
Release branch → + E2E smoke on staging + load smoke.
A red isolation or money suite **blocks all merges — no override label exists.**
