# EaglEs Property — Flutter Application Architecture

> Clean Architecture · Feature-first · Riverpod · GoRouter · Offline-first
> Targets: Web, Android, iOS, Windows, macOS, Linux — single codebase.

---

## 1. Layering (Clean Architecture)

```
┌─────────────────────────────────────────────────────────┐
│ PRESENTATION   screens · widgets · controllers (Riverpod │
│                Notifiers) · route guards                 │
├─────────────────────────────────────────────────────────┤
│ DOMAIN         entities · value objects · repository     │
│                interfaces · use cases · failures         │
├─────────────────────────────────────────────────────────┤
│ DATA           DTOs (freezed+json) · repository impls ·  │
│                Firestore/Storage/Functions data sources · │
│                mappers · offline queue                    │
├─────────────────────────────────────────────────────────┤
│ CORE           theme · router · DI · services · utils ·  │
│                shared widgets · l10n · constants          │
└─────────────────────────────────────────────────────────┘
Dependency rule: presentation → domain ← data. Domain imports nothing from Flutter/Firebase.
```

## 2. Folder Structure (feature-first)

```
lib/
├─ main_dev.dart / main_stg.dart / main_prod.dart   # flavor entrypoints
├─ bootstrap.dart                                    # Firebase init, Crashlytics zone, ProviderScope
├─ app.dart                                          # MaterialApp.router, theme, l10n
│
├─ core/
│  ├─ config/            env.dart, flavor.dart, remote_config_keys.dart
│  ├─ constants/         app_constants.dart, collection_paths.dart, enums.dart
│  ├─ errors/            failure.dart, error_mapper.dart, result.dart (sealed Result<T>)
│  ├─ router/            app_router.dart, route_paths.dart, guards/, shell/
│  ├─ theme/             app_theme.dart, tokens/ (color, type, space, radius), glass.dart
│  ├─ l10n/              arb/ (en, am, ar, fr, sw...), l10n.dart
│  ├─ services/
│  │  ├─ firebase/       auth_service, firestore_service, storage_service,
│  │  │                  functions_service, messaging_service, remote_config_service,
│  │  │                  analytics_service, app_check_service, crashlytics_service
│  │  ├─ connectivity_service.dart
│  │  ├─ local_cache_service.dart        # Hive/Isar for prefs & drafts
│  │  ├─ media_service.dart              # pickers, compression, upload queue
│  │  ├─ geo_service.dart                # geohash, distance
│  │  └─ permission_service.dart         # RBAC evaluation client-side (UX only)
│  ├─ providers/         global providers: authState, currentTenant, permissions,
│  │                     connectivity, remoteConfig, themeMode, locale
│  ├─ widgets/           design-system widgets (see docs/05 §5)
│  └─ utils/             formatters (money, date, area), validators, debouncer, ulid
│
├─ features/
│  ├─ auth/                      # sign in/up, SSO, 2FA, forgot, tenant switcher
│  ├─ onboarding/                # tenant creation wizard, invites
│  ├─ shell/                     # adaptive scaffold, nav rail/drawer, command palette
│  ├─ dashboard/                 # role-aware executive dashboards
│  ├─ developer_mgmt/            # company, branches, departments, employees, licenses
│  ├─ projects/                  # project list/detail, phases, master plan
│  ├─ construction/              # schedule+gantt, tasks, milestones, daily reports,
│  │                             # inspections, VOs, photo/drone logs, progress
│  ├─ inventory/                 # buildings, floors, unit matrix, unit detail
│  ├─ crm/                       # leads, pipeline board, activities, ai scoring
│  ├─ deals/                     # reservations, bookings, contracts, e-sign
│  ├─ marketplace/               # public search, map, listing detail, compare,
│  │                             # favorites, mortgage calculator, 360 tours
│  ├─ customer_portal/           # my bookings, payments, contracts, support
│  ├─ rental/                    # leases, renewals, rent collection, vacancy
│  ├─ facilities/                # work orders, assets, preventive maintenance
│  ├─ finance/                   # invoices, payments, expenses, budgets, cashflow
│  ├─ documents/                 # DMS browser, versions, viewer (pdf/cad/img)
│  ├─ communication/             # chat, meetings, announcements, tickets
│  ├─ ai_assistant/              # chat UI, insights feed, doc summarizer
│  ├─ analytics/                 # KPI dashboards, heatmaps, forecasts
│  ├─ notifications/             # inbox, preferences
│  └─ admin/                     # platform admin + tenant admin panels
│
└─ features/<feature>/           # EVERY feature follows this internal layout:
   ├─ domain/
   │  ├─ entities/               unit.dart, unit_status.dart ...
   │  ├─ repositories/           unit_repository.dart (abstract)
   │  └─ usecases/               reserve_unit.dart, watch_unit_matrix.dart ...
   ├─ data/
   │  ├─ dtos/                   unit_dto.dart (freezed + json_serializable)
   │  ├─ sources/                unit_firestore_source.dart, unit_functions_source.dart
   │  └─ repositories/           unit_repository_impl.dart
   └─ presentation/
      ├─ controllers/            unit_matrix_controller.dart (AsyncNotifier)
      ├─ screens/                unit_matrix_screen.dart, unit_detail_screen.dart
      └─ widgets/                unit_card.dart, status_legend.dart
```

## 3. State Management (Riverpod 2, codegen)

### Global providers (core/providers)
```dart
@Riverpod(keepAlive: true)
Stream<AuthUser?> authState(Ref ref) =>
    ref.watch(authServiceProvider).authStateChanges();

@Riverpod(keepAlive: true)
class CurrentTenant extends _$CurrentTenant {
  @override
  Future<TenantContext?> build() async {
    final user = await ref.watch(authStateProvider.future);
    if (user == null) return null;
    final claims = await user.claims();                    // tenantId, roles, pv
    final tenant = await ref.watch(tenantRepoProvider).get(claims.tenantId);
    return TenantContext(tenant: tenant, roles: claims.roles);
  }

  Future<void> switchTenant(String tenantId) async {
    await ref.read(functionsServiceProvider)
        .call('setActiveTenant', {'tenantId': tenantId});
    await ref.read(authServiceProvider).refreshToken();    // pick up new claims
    ref.invalidateSelf();
  }
}

@riverpod
PermissionSet permissions(Ref ref) {
  final ctx = ref.watch(currentTenantProvider).valueOrNull;
  return PermissionSet.fromRoles(ctx?.roles ?? const []);  // mirrors docs/08 matrix
}
```

### Feature controller pattern
```dart
@riverpod
class UnitMatrixController extends _$UnitMatrixController {
  @override
  Stream<List<Unit>> build(String projectId) {
    final tenantId = ref.watch(currentTenantProvider).requireValue!.tenant.id;
    return ref.watch(unitRepositoryProvider)
        .watchByProject(tenantId: tenantId, projectId: projectId);
  }

  Future<Result<void>> holdUnit(String unitId) =>
      ref.read(reserveUnitUseCaseProvider).hold(unitId);   // optimistic; stream reconciles
}
```

**Conventions**
- Streams for anything shown live (Firestore snapshots) → `StreamProvider`/`build() => Stream`.
- Commands go through use cases returning `Result<T>` (sealed `Ok/Err(Failure)`), never throw into UI.
- `AsyncValue.guard` + `ref.invalidate` for refresh; `select()` to minimize rebuilds.
- Controllers are per-feature; no global mutable app state beyond auth/tenant/theme.

## 4. Repository & API Layer

```dart
abstract class UnitRepository {
  Stream<List<Unit>> watchByProject({required String tenantId, required String projectId});
  Stream<Unit> watch(String tenantId, String unitId);
  Future<Result<Unit>> get(String tenantId, String unitId);
}

class UnitRepositoryImpl implements UnitRepository {
  UnitRepositoryImpl(this._fs);
  final FirestoreService _fs;

  @override
  Stream<List<Unit>> watchByProject({required tenantId, required projectId}) =>
      _fs.collection('tenants/$tenantId/units')
         .where('projectId', isEqualTo: projectId)
         .where('isDeleted', isEqualTo: false)
         .orderBy('code')
         .snapshots(includeMetadataChanges: true)          // expose pending-write state
         .map((s) => s.docs.map((d) => UnitDto.fromJson(d.data()).toEntity(
                pendingSync: d.metadata.hasPendingWrites)).toList());
}
```

**Two write paths, strictly separated:**

| Path | When | Mechanism |
|---|---|---|
| Direct Firestore write | Simple, owner-scoped data (draft note, profile field, daily report) | Repository `set/update`, offline-queued automatically |
| Callable Function | Transactional / contested / financial (reserve unit, allocate payment, sign contract, change role) | `FunctionsService.call()` → typed request/response DTOs, requires connectivity, UI shows blocking progress |

`FunctionsService` wraps `cloud_functions` with: automatic `pv` retry (stale claims), error-code → `Failure` mapping, request logging to Analytics.

## 5. Offline-First Implementation

- `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true, cacheSizeBytes: 100MB)`; web uses `enablePersistentCacheIndexAutoCreation`.
- Every list tile can render a **sync chip** from `pendingSync` metadata.
- **Media upload queue**: `media_service` stages files in app documents dir + Isar queue; a background worker (workmanager on mobile) retries uploads, then patches the Firestore doc with URLs.
- **Draft store**: long forms (daily report, inspection) autosave to Isar every 5s; restored on relaunch.
- Connectivity provider gates Function-backed actions with a consistent "Requires connection" affordance.

## 6. Firebase Integration Map

| Firebase | Usage |
|---|---|
| Auth | Email/pass, Google, Apple, Microsoft SSO, phone OTP; custom claims for tenant+roles; TOTP 2FA via Functions |
| Firestore | Primary DB, offline persistence, collection-group queries, snapshots-as-streams |
| Functions | All transactional writes, claims, payments, AI endpoints, projections (docs/07) |
| Storage | Tenant-scoped media/docs, resumable uploads, thumbnail pipeline |
| Messaging | FCM push: per-user tokens in `users/{uid}/devices`; topics per tenant/project; foreground in-app banner |
| Remote Config | Feature flags per plan/tenant, kill switches, min-version force update |
| App Check | Enforced all environments except emulator |
| Analytics | Screen + business events (`lead_created`, `unit_reserved`, `payment_confirmed`) with tenantId user property |
| Crashlytics | Zone-guarded main, riverpod ProviderObserver breadcrumbs, non-fatal Failure reporting |

## 7. Dependency Injection

Pure Riverpod — no service locator. Services are `@Riverpod(keepAlive: true)` providers; repositories depend on services; use cases depend on repositories; controllers depend on use cases. Tests override any node with `ProviderScope(overrides:[...])`. Flavor config injected at bootstrap via `EnvScope`.

## 8. Error Handling & Result

```dart
sealed class Failure { const Failure(this.message, {this.code});
  final String message; final String? code; }
class NetworkFailure extends Failure {...}
class PermissionFailure extends Failure {...}     // maps firestore permission-denied
class ConflictFailure extends Failure {...}       // unit already reserved, version mismatch
class ValidationFailure extends Failure {...}

typedef Result<T> = ({T? ok, Failure? err});      // or sealed Ok/Err classes
```
UI renders failures through a single `FailureView`/`showFailureSnack` mapping — consistent copy, retry affordances, Crashlytics non-fatal logging for unexpected codes.

## 9. Responsive Strategy

Breakpoints (Material 3 window size classes):

| Class | Width | Shell |
|---|---|---|
| compact | <600 | bottom nav (5 tabs max) + drawers |
| medium | 600–839 | nav rail collapsed |
| expanded | 840–1199 | nav rail extended + 2-pane master/detail |
| large | ≥1200 | persistent sidebar + 3-pane (list/detail/inspector) |

`AdaptiveScaffold` in `features/shell` owns this; screens declare `body` + optional `secondaryBody` and never handle breakpoints themselves. Data tables become card lists on compact; Gantt & unit matrix get horizontal-scroll + pinch zoom on touch.

## 10. Packages (curated)

| Concern | Package |
|---|---|
| State | flutter_riverpod, riverpod_annotation |
| Models | freezed, json_serializable |
| Routing | go_router |
| Firebase | firebase_core/auth/cloud_firestore/storage/functions/messaging/remote_config/app_check/analytics/crashlytics |
| Local DB | isar (drafts, media queue) |
| Maps | google_maps_flutter, geoflutterfire-style geohash utils |
| Charts | fl_chart (+ syncfusion_flutter_charts for Gantt/heatmap if licensed) |
| Media | image_picker, file_picker, flutter_image_compress, cached_network_image |
| PDF view | pdfx / syncfusion_flutter_pdfviewer |
| 360/3D | panorama_viewer, webview (Matterport embed) |
| Intl | intl, flutter_localizations |
| Misc | url_launcher, connectivity_plus, flutter_secure_storage, ulid |
```
