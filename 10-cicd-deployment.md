# EaglEs Property — CI/CD Pipeline & Deployment Strategy

> GitHub Actions · trunk-lite branching · three Firebase projects (dev/stg/prod) · progressive rollout
> Companion to docs/01 §7 (environments) and docs/09 (quality gates).

---

## 1. Repository & Branching

Monorepo:
```
/app            Flutter workspace
/functions      Cloud Functions (TS)
/rules          firestore.rules, storage.rules, firestore.indexes.json
/infra          Terraform (Firebase projects, Typesense, budgets, alerting)
/permissions    permissions.yaml + codegen (Dart, TS, rules-test fixtures)
/.github        workflows, CODEOWNERS
```

| Branch | Purpose | Deploys to |
|---|---|---|
| `feature/*` → PR | all work; squash merge | — (CI only) |
| `develop` | integration trunk | **dev** (auto, on merge) |
| `release/x.y` | stabilization, cut weekly | **staging** (auto) |
| `main` | tagged production releases | **prod** (manual approval) |
| `hotfix/*` | prod fixes off main | staging → prod fast-lane |

CODEOWNERS: `/rules` and `/permissions` require security-owner review; `/functions/src/finance` requires two reviewers.

## 2. Pipelines

### 2.1 PR pipeline (≤10 min, blocking)
```yaml
jobs:
  flutter:   # melos-style path filter — only affected packages
    - flutter pub get · dart format --set-exit-if-changed · flutter analyze (fatal-infos)
    - flutter test --coverage (unit + widget)
    - dart run build_runner build --delete-conflicting-outputs (drift check)
  functions:
    - npm ci · eslint · tsc --noEmit · vitest (unit)
  rules:
    - firebase emulators:exec "vitest run rules"      # isolation suite (docs/09 §2.1)
  permissions-sync:
    - regen from permissions.yaml → git diff --exit-code   # matrix drift guard
  security:
    - osv-scanner · npm audit --audit-level=high · gitleaks
```

### 2.2 develop pipeline (merge → dev env)
- All PR jobs + goldens + Flutter integration tests (emulator suite in container).
- Coverage gate (80/90/100 tiers, docs/09).
- Deploy: `firebase deploy --project eagles-prop-dev` (rules → indexes → functions), Flutter web to dev Hosting channel, Android APK to Firebase App Distribution (internal testers), iOS to TestFlight internal.

### 2.3 release pipeline (release/x.y → staging)
- Full suite + E2E smoke (Patrol device farm run + Playwright web against staging).
- k6 load smoke.
- Versioning: `x.y.z+build` from tag; changelog generated (conventional commits).
- Deploy staging: same order as prod (below). UAT sign-off checklist issue auto-created.

### 2.4 prod pipeline (tag on main, manual approval gate)
Ordered, each step verified before next:

```
1. terraform plan/apply (infra drift)             — no-op most releases
2. firestore.indexes.json deploy                  — wait until indexes READY
3. firestore/storage rules deploy                 — rules are backward-compatible by convention
4. functions deploy (grouped, --only per module)  — v2 functions get traffic after health check
5. Remote Config: publish min-version + flags     — kill-switches default OFF for new features
6. Flutter web → Hosting preview channel → smoke → promote to live (instant rollback token kept)
7. Android: AAB → Play "internal" → staged rollout 10% → 50% → 100% (Crashlytics-gated)
8. iOS: TestFlight → phased App Store release (7-day automatic phasing)
9. Desktop (Windows/macOS): signed installers to distribution bucket + in-app update feed
```

**Backward compatibility contract:** functions and rules deploy *before* clients; every schema change is additive (new fields nullable, old fields kept until min-version passes); Remote Config `minSupportedBuild` forces upgrade of stragglers.

## 3. Secrets & Config

| Item | Home |
|---|---|
| Gateway keys, AI keys, Typesense | GCP Secret Manager (functions runtime binding) |
| CI deploy identity | Workload Identity Federation (no long-lived JSON keys) |
| Signing (Android keystore, iOS certs) | GitHub encrypted secrets + match-style repo for iOS |
| Per-env Flutter config | `--dart-define-from-file=env/{dev,stg,prod}.json` (no secrets in client) |

## 4. Rollback Playbook

| Failure | Action | Time |
|---|---|---|
| Web regression | `firebase hosting:rollback` (previous release token) | <1 min |
| Function bad deploy | redeploy previous artifact (kept 10 versions in Artifact Registry) | <5 min |
| Rules regression | `firebase deploy --only firestore:rules` from previous tag | <2 min |
| Mobile crash spike | halt staged rollout; Remote Config kill-switch for the feature; hotfix lane | minutes for flags |
| Data corruption | PITR (Firestore point-in-time recovery, 7d) + daily GCS exports (35d) | RPO ≤1h, RTO <4h |

Crashlytics velocity alerts (crash-free users <99.5%) auto-page and freeze rollout progression.

## 5. Observability & Release Health

- Dashboards: function error rate/p95, Firestore doc reads per tenant (cost anomaly alert), payment webhook failure count, reservation conflict rate.
- Alerting: budget alerts per project; uptime checks on Hosting + `healthz` https function; log-based alert on `PERMISSION_DENIED` spikes (possible rules regression or probe).
- Every release: tagged in Crashlytics/Analytics (`app_version` dimension) for cohort comparison.

## 6. Environment Promotion Summary

```
feature PR ──CI──▶ develop ──auto──▶ DEV ──weekly cut──▶ release/x.y ──auto──▶ STAGING
                                                              │ UAT + E2E + load
                                                              ▼
                                             tag vx.y.z on main ──approval──▶ PROD (staged)
```
