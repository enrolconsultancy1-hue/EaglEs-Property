# EaglEs Property — Navigation Structure (GoRouter)

> Deep-linkable, guard-protected, role-aware, shell-based navigation.

---

## 1. Route Tree

```
/                              → marketing/landing (web) or splash (app)
/auth
  /auth/sign-in
  /auth/sign-up
  /auth/forgot
  /auth/verify                 → email/phone verification
  /auth/2fa                    → TOTP challenge
  /auth/tenant-select          → tenant switcher (multi-membership)
/onboarding
  /onboarding/create-tenant    → tenant creation wizard (4 steps)
  /onboarding/invite/:token    → accept invitation

── PUBLIC MARKETPLACE (no auth required) ──────────────────────
/market                        → search home
/market/search                 → results (list|map|split), query in URL params
/market/listing/:listingId     → listing detail
/market/listing/:listingId/tour→ 360/Matterport viewer
/market/compare?ids=a,b,c      → comparison table
/market/mortgage               → mortgage calculator
/market/favorites              → (auth-gated inline)

── APP SHELL (StatefulShellRoute, auth + tenant required) ─────
/app/dashboard                 → role-aware home
/app/projects
  /app/projects/:pid                       → overview tab
  /app/projects/:pid/schedule              → gantt / task list toggle
  /app/projects/:pid/schedule/:taskId      → task inspector (side panel route)
  /app/projects/:pid/milestones
  /app/projects/:pid/budget
  /app/projects/:pid/daily-reports
  /app/projects/:pid/daily-reports/new
  /app/projects/:pid/inspections
  /app/projects/:pid/variation-orders
  /app/projects/:pid/photos                → photo/drone log gallery
  /app/projects/:pid/progress              → S-curve, % complete
/app/inventory
  /app/inventory/:pid/matrix               → unit availability matrix
  /app/inventory/unit/:unitId              → unit detail
/app/crm
  /app/crm/leads                           → list + filters
  /app/crm/leads/:leadId                   → lead 360 view
  /app/crm/pipeline                        → kanban board
  /app/crm/opportunities/:oppId
/app/deals
  /app/deals/reservations
  /app/deals/contracts
  /app/deals/contracts/:contractId
  /app/deals/contracts/:contractId/sign    → e-signature flow
/app/rental
  /app/rental/leases
  /app/rental/leases/:leaseId
  /app/rental/collections                  → rent run, arrears
  /app/rental/vacancy
/app/facilities
  /app/facilities/work-orders
  /app/facilities/work-orders/:woId
  /app/facilities/assets
  /app/facilities/assets/:assetId
/app/finance
  /app/finance/invoices
  /app/finance/invoices/:invoiceId
  /app/finance/payments
  /app/finance/payments/approvals          → offline payment approval queue
  /app/finance/expenses
  /app/finance/budgets
  /app/finance/cashflow
/app/documents
  /app/documents/browse?folder=...
  /app/documents/:docId                    → viewer + versions
/app/comms
  /app/comms/chat
  /app/comms/chat/:conversationId
  /app/comms/meetings
  /app/comms/announcements
  /app/comms/tickets
  /app/comms/tickets/:ticketId
/app/ai
  /app/ai/assistant                        → chat
  /app/ai/insights                         → risk/forecast feed
/app/analytics
  /app/analytics/executive
  /app/analytics/sales
  /app/analytics/occupancy
  /app/analytics/construction
  /app/analytics/heatmap
/app/company                               → developer management
  /app/company/profile
  /app/company/branches
  /app/company/departments
  /app/company/employees
  /app/company/employees/:employeeId
  /app/company/licenses
/app/settings
  /app/settings/profile
  /app/settings/security                   → 2FA setup
  /app/settings/notifications
  /app/settings/tenant                     → branding, locale, workflows (admin)
  /app/settings/users                      → members & roles (admin)
  /app/settings/billing                    → subscription (owner)

── CUSTOMER PORTAL SHELL (buyer/resident roles) ───────────────
/portal/home
/portal/bookings
/portal/payments
/portal/payments/pay/:invoiceId            → gateway checkout
/portal/contracts
/portal/maintenance
/portal/maintenance/new
/portal/support
/portal/chat

── PLATFORM ADMIN SHELL (plt roles only) ──────────────────────
/admin/overview
/admin/tenants
/admin/tenants/:tenantId
/admin/billing
/admin/users
/admin/ai-monitoring
/admin/logs
```

## 2. Router Skeleton

```dart
final appRouter = GoRouter(
  initialLocation: '/app/dashboard',
  refreshListenable: GoRouterRefreshStream(ref.watch(authStateProvider.stream)),
  redirect: (context, state) {
    final auth = ref.read(authStateProvider).valueOrNull;
    final tenant = ref.read(currentTenantProvider).valueOrNull;
    final loc = state.matchedLocation;

    final isPublic = loc.startsWith('/market') || loc == '/' ;
    final inAuth  = loc.startsWith('/auth');

    if (auth == null)       return isPublic || inAuth ? null : '/auth/sign-in?from=$loc';
    if (auth.needs2fa)      return loc == '/auth/2fa' ? null : '/auth/2fa';
    if (tenant == null && loc.startsWith('/app'))
                            return '/auth/tenant-select';
    if (inAuth)             return _homeFor(tenant);          // role-based landing
    return null;
  },
  routes: [
    // 3 independent StatefulShellRoutes: /app, /portal, /admin
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => AdaptiveScaffold(shell: shell),
      branches: [ /* dashboard, projects, crm, ... each a branch w/ preserved state */ ],
    ),
    ...
  ],
);

String _homeFor(TenantContext? t) {
  if (t == null) return '/auth/tenant-select';
  if (t.roles.containsAny(['buyer','tenantResident'])) return '/portal/home';
  if (t.isPlatform) return '/admin/overview';
  return '/app/dashboard';
}
```

## 3. Guard Rules

| Guard | Behavior |
|---|---|
| AuthGuard | unauthenticated → `/auth/sign-in?from=` (post-login return) |
| TwoFactorGuard | 2FA-pending session can only reach `/auth/2fa` |
| TenantGuard | no active tenant claim → tenant selector |
| RoleGuard (per branch) | branch declares `requiredPermission`; lacking it → 403 screen with "request access" CTA. Nav items without permission are **hidden**, not disabled |
| PlanGuard | module not in tenant plan → upgrade paywall screen (Remote Config-driven) |
| VersionGuard | Remote Config `minBuild` > current → force-update screen |

## 4. Navigation UX Rules

- **State preservation**: each shell branch keeps its own Navigator stack (`StatefulShellRoute.indexedStack`) — switching Projects↔CRM never loses scroll/filters.
- **URL as state** on web: search filters, board views, date ranges serialize to query params (shareable links).
- **Side-panel routes** on expanded layouts: detail routes (`:taskId`, `:leadId`) render as right-hand inspector panels instead of full pushes; same URL works as full screen on compact.
- **Command palette** (⌘K / Ctrl+K): fuzzy-jump to any route, entity search (units, leads, projects) via Typesense.
- **Deep links**: FCM notification payloads carry route paths; `/onboarding/invite/:token` and `/market/listing/:id` are the primary external links.
- **Breadcrumbs** on desktop for nested project routes.
```
