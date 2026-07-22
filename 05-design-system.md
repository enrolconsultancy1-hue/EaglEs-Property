# EaglEs Property — UI Design System, Wireframes & Widget Library

> Premium enterprise UI. References: Salesforce Lightning, Monday.com, Notion, ClickUp, Linear, Apple HIG, Material 3, Fluent.
> Principle: **dense but calm** — high information density with generous whitespace discipline.

---

## 1. Design Tokens

### 1.1 Color

```dart
// Brand (tenant-overridable via branding config)
static const brandPrimary  = Color(0xFF0B5FFF);  // Eagle Blue
static const brandDeep     = Color(0xFF0A2540);  // Midnight — headers, hero
static const brandAccent   = Color(0xFF00C48C);  // Emerald — success/growth
static const brandGold     = Color(0xFFF5A623);  // Premium highlights (sparingly)

// Semantic
static const success = Color(0xFF17B26A);
static const warning = Color(0xFFF79009);
static const danger  = Color(0xFFF04438);
static const info    = Color(0xFF2E90FA);

// Neutrals — Light                       // Neutrals — Dark
surface        #FFFFFF                    surface        #101828
surfaceAlt     #F8FAFC                    surfaceAlt     #0C1220
surfaceCard    #FFFFFF                    surfaceCard    #1A2233
border         #E4E7EC                    border         #2A3446
textPrimary    #101828                    textPrimary    #F2F4F7
textSecondary  #475467                    textSecondary  #98A2B3
textTertiary   #98A2B3                    textTertiary   #667085
```

`ColorScheme.fromSeed(seed: tenantBranding.primary)` generates the M3 scheme; the tokens above pin semantic and neutral ramps so tenant re-branding never breaks contrast (min 4.5:1 enforced by a build-time contrast test).

**Domain status colors** (used consistently in chips, matrix cells, pipeline):

| Domain | Mapping |
|---|---|
| Unit | available=success, held=info, reserved=warning, sold=brandDeep, rented=violet #7A5AF8, blocked=neutral |
| Deal stage | ramp from info → warning → success |
| Construction | onTrack=success, atRisk=warning, delayed=danger, done=neutral |
| Invoice | draft=neutral, sent=info, overdue=danger, paid=success |

### 1.2 Typography — Inter (Latin) / Noto Sans (fallbacks incl. Ethiopic)

| Token | Size/Height | Weight | Use |
|---|---|---|---|
| display | 32/40 | 700 | dashboard hero numbers |
| headlineL | 24/32 | 600 | page titles |
| headlineS | 20/28 | 600 | section titles, dialog titles |
| titleM | 16/24 | 600 | card titles, table headers |
| bodyL | 16/24 | 400 | reading text |
| bodyM | 14/20 | 400 | default UI text |
| labelM | 13/16 | 500 | buttons, chips, nav |
| caption | 12/16 | 400 | metadata, timestamps |
| mono | 13/20 | 500 | codes (INV-2026-0841), money in tables (tabular figures) |

### 1.3 Spacing, Radius, Elevation

- Spacing scale: 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 (4-pt grid; page gutters 24 desktop, 16 mobile).
- Radius: input 8 · card 12 · modal 16 · pill 999.
- Elevation: flat surfaces + 1px border by default; shadows only on overlays (popover `0 4 6 -2 / 8%`, modal `0 20 24 -4 / 10%`).

### 1.4 Glassmorphism — restrained policy
Used ONLY on: app bar over map/hero imagery, command palette overlay, KPI strip over dashboard header gradient. Recipe: `blur(20) · white 65% / dark #1A2233 55% · 1px border white 40%/8%`. Never on data tables, forms, or dense lists.

### 1.5 Motion
- Durations: micro 120ms · standard 200ms · emphasis 300ms; curve `Curves.easeOutCubic`.
- Page transitions: fade-through (shell), shared-axis (wizards), Hero (listing card → detail image).
- List entrance: 30ms stagger, first page only. Number tickers on KPI cards. Skeleton shimmer while loading. `MediaQuery.disableAnimations` respected.

---

## 2. Wireframes (key screens)

### 2.1 Executive Dashboard (desktop, expanded)
```
┌────────┬──────────────────────────────────────────────────────────────┐
│        │ ⌕ Search (⌘K)                    🔔 3   ⚙   [Tenant ▾] [SB] │
│  LOGO  ├──────────────────────────────────────────────────────────────┤
│        │ Good morning, Sara            [This Month ▾] [⬇ Export]      │
│ ▣ Dash │ ┌─────────┐┌─────────┐┌─────────┐┌─────────┐┌─────────┐      │
│ ▢ Proj │ │ REVENUE ││ UNITS   ││ OCCUP.  ││ LEADS   ││ CONSTR. │      │
│ ▢ Inv  │ │ $4.2M   ││ 214/620 ││ 87.3%   ││ 412 new ││ 43.5%   │      │
│ ▢ CRM  │ │ ▲12.4%  ││ sold    ││ ▲2.1%   ││ 38 conv ││ SPI .94 │      │
│ ▢ Deals│ └─────────┘└─────────┘└─────────┘└─────────┘└─────────┘      │
│ ▢ Rent │ ┌───────────────────────────────┐ ┌────────────────────────┐ │
│ ▢ FM   │ │ Sales Performance      [⋮]    │ │ AI INSIGHTS        [→] │ │
│ ▢ Fin  │ │   ▁▂▄▆█▆▄▆█  (bar+line)      │ │ ⚠ Tower 2 delay risk   │ │
│ ▢ Docs │ │                               │ │   rose to 31%          │ │
│ ▢ Comms│ └───────────────────────────────┘ │ ● 12 leases expire in  │ │
│ ▢ AI   │ ┌──────────────┐┌───────────────┐ │   60 days              │ │
│ ▢ Anlyt│ │ Cash Flow    ││ Project Map   │ │ ● Hot lead: A. Tesfaye │ │
│ ──────  │ │ in/out area  ││ pins+clusters │ └────────────────────────┘ │
│ ▢ Setts│ └──────────────┘└───────────────┘ [Activity feed ───────── ] │
└────────┴──────────────────────────────────────────────────────────────┘
```

### 2.2 Unit Availability Matrix (inventory)
```
┌ Bole Sky Towers ▾  Tower 2 ▾          Legend: ■Avail ■Held ■Res ■Sold │
│ Floor 14  [A ■][B ■][C ■][D ■][E ■][F ■]     Filters: 3BR ▾  Price ▾ │
│ Floor 13  [A ■][B ■][C ■][D ■][E ■][F ■]      ┌─ Unit BST-T2-14-A ──┐│
│ Floor 12  [A ■][B ■][C ■][D ■][E ■][F ■]      │ 3BR · 142.5m² · City ││
│   ...                                          │ ETB 12.5M   [Hold]  ││
│ Hover/tap cell → inspector panel (right)       │ AI est: 13.1M ▲     ││
└────────────────────────────────────────────────┴─────────────────────┘
```

### 2.3 CRM Pipeline (kanban)
```
┌ Pipeline ▾  My deals ▾  ⌕            + New Lead   [Board|Table|Chart] │
│ NEW (120)      QUALIFIED (60)   PROPOSAL (24)     CLOSING (9)         │
│ ┌──────────┐   ┌──────────┐    ┌──────────┐      ┌──────────┐        │
│ │A. Tesfaye│   │M. Alemu  │    │K. Yusuf  │      │S. Chen   │        │
│ │🔥 87 hot │   │3BR Bole  │    │ETB 12.5M │      │Contract  │        │
│ │2 visits  │   │Follow 2d │    │Unit 14-A │      │sent ✍    │        │
│ └──────────┘   └──────────┘    └──────────┘      └──────────┘        │
│  drag between columns → stage change + activity log                   │
└───────────────────────────────────────────────────────────────────────┘
```

### 2.4 Construction — Gantt + progress
```
┌ Bole Sky Towers · Schedule     [Gantt|List|Board]  ⚠ AI: 31% delay risk│
│ WBS Task              │ J F M A M J J A S O N D                       │
│ 3.1  Foundations   ✔  │ ████████                                      │
│ 3.2  Structure 60%    │      ██████████░░░░  ← critical path (red)    │
│ 3.2.1 L14 slab  60%   │           ████░░  👷24  [photos 12]           │
│ 4.1  MEP rough-in     │               ░░░░░░░░ dep: 3.2 FS+2          │
│ Milestones: ◆ Topping-out Oct 12   ◆ Handover Q3'27                   │
└───────────────────────────────────────────────────────────────────────┘
```

### 2.5 Marketplace search (public, split view)
```
┌ EaglEs Market   ⌕ "3 bedroom bole"   [Buy|Rent]  Price▾ Type▾ Beds▾ ⚙ │
│ ┌───────────── results (342) ───────────┐ ┌──────── map ────────────┐ │
│ │ ┌────┐ 3BR Apt · Bole Sky Towers      │ │      (12)               │ │
│ │ │img │ ETB 12.5M · 142m² · ★Verified  │ │   (5)    ●              │ │
│ │ └────┘ ♡  [360°] [Compare]            │ │       ●      (23)       │ │
│ │ ┌────┐ Villa · Summit Gardens ...     │ │  clusters · draw tool   │ │
│ │ └────┘                                │ │  schools/hospitals ▢    │ │
│ └───────────────────────────────────────┘ └─────────────────────────┘ │
```

### 2.6 Customer portal — payments (mobile, compact)
```
┌ ◀  My Payments      ┐   Progress: ████████░░ 8/36 paid
│ NEXT DUE            │   ┌ Pay with ────────────┐
│ Installment 9/36    │   │ ◉ Telebirr           │
│ ETB 347,222         │   │ ○ Bank transfer      │
│ Due Aug 1 · in 10d  │   │ ○ Card (Stripe)      │
│ [ Pay Now ]         │   └──────────────────────┘
│ History ▾ (receipts)│   Offline? Upload proof → Finance approves
└─────────────────────┘
```

---

## 3. Reusable Widget Library (`core/widgets/`)

### Layout & shell
| Widget | Purpose |
|---|---|
| `AdaptiveScaffold` | breakpoint-aware shell: bottom-nav / rail / sidebar + secondary pane |
| `PageHeader` | title, breadcrumbs, actions, filter row — consistent on every screen |
| `MasterDetailLayout` | list + inspector panel with URL-synced selection |
| `AppSection` | titled card section w/ optional collapse + "see all" |
| `GlassPanel` | policy-compliant glassmorphism container |

### Data display
| Widget | Purpose |
|---|---|
| `KpiCard` | metric, delta arrow, sparkline, tap-through; number ticker animation |
| `DataTableX` | sortable, sticky header, column picker, row selection, CSV export, → cards on compact |
| `StatusChip` | domain-status → color token mapping (single source of truth) |
| `EntityTile` | avatar/thumb + title + meta + trailing — leads, units, docs, invoices |
| `TimelineList` | activity feeds, status history |
| `ProgressRing` / `SCurveChart` / `CashflowChart` / `HeatmapCalendar` | analytics primitives on fl_chart |
| `GanttView` | zoomable timeline, drag-resize (desktop), critical-path highlight |
| `UnitMatrixGrid` | floor × unit grid, status-colored, pinch-zoom |
| `MapView` | pins, clusters, draw-to-search, nearby-services layer toggles |
| `MoneyText` | tabular figures, currency-aware, compact notation option |
| `SyncBadge` | offline pending-write indicator |

### Input & workflow
| Widget | Purpose |
|---|---|
| `AppForm` + `AppTextField/Select/DatePicker/MoneyField/PhoneField` | validated, autosave-draft aware |
| `StepFlow` | multi-step wizards (tenant onboarding, contract creation) |
| `FilterBar` | chips + advanced filter sheet, serializes to query params |
| `KanbanBoard` | generic drag-drop board (pipeline, work orders) |
| `ApprovalCard` | approve/reject w/ comment, chain visualization |
| `SignaturePad` | e-sign capture + typed signature |
| `MediaUploader` | multi-file, progress, compression, offline queue |
| `CommandPalette` | ⌘K fuzzy navigation + entity search |

### Feedback
| Widget | Purpose |
|---|---|
| `EmptyState` | illustration + primary CTA (never a blank screen) |
| `SkeletonLoader` | shimmer placeholders per layout type |
| `FailureView` | Failure → copy + retry |
| `ConfirmDialog` | destructive-action confirmation w/ typed-name gate for critical ops |
| `AppSnack` | success/info/error toasts, offline-queued indicator |
| `PaywallCard` | plan-gated feature upsell |

Every widget: light+dark, RTL-ready, keyboard/focus support on desktop-web, semantics labels, golden-tested (docs/09).
```
