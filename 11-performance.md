# EaglEs Property — Performance Optimization

> Scalability · Latency · Efficiency · High-Density Rendering

---

## 1. Frontend Optimization (Flutter)

### 1.1 Rendering Efficiency
- **Repaint Boundaries**: Used around complex animations (e.g., Gantt chart scrolling, number tickers) to isolate repaints.
- **ListView Optimization**: `ListView.builder` with consistent item heights; `CustomScrollView` for complex pages.
- **Select() Pattern**: Using Riverpod's `ref.watch(provider.select(...))` to avoid rebuilds when unrelated state changes.

### 1.2 Asset & Media Management
- **Progressive Images**: `cached_network_image` with memory caching and disk persistence.
- **Client-Side Compression**: `flutter_image_compress` reduces photo sizes before upload to save bandwidth.
- **SVG over Raster**: All icons and simple illustrations use SVG (flutter_svg) for resolution independence and small bundle size.

---

## 2. Backend & Data Optimization (Firebase)

### 2.1 Firestore Scalability
- **Sharded Counters**: Used for high-frequency aggregates (e.g., project total sales, tenant occupancy) to bypass the 1-write-per-second limit on a single document.
- **Denormalization**: Critical read-models (like the Unit Matrix or Kanban Board) are pre-computed by Cloud Functions to avoid complex client-side joins.
- **Index Management**: Strategic composite indexes to support complex multi-tenant filters (e.g., `tenantId` + `projectId` + `status` + `updatedAt`).

### 2.2 Cloud Functions
- **Cold Start Reduction**: Minimal dependency trees; global initialization of Firebase Admin; keeping high-traffic functions "warm" via periodic pings or reserved concurrency.
- **Idempotency**: All transactional functions (payments, reservations) use request IDs to prevent double-processing on retries.

---

## 3. Network & Content Delivery

### 3.1 Global Latency
- **Hosting CDN**: Static assets (Web app, PDF templates, standard icons) served from edge locations globally.
- **Multi-Region DB**: Database location optimized for the primary target market (e.g., `europe-west3` for African/European clients).

### 3.2 Offline-First Sync
- **Delta Sync**: Only fetching changes since `lastSyncedAt` for large collections (Docs, Leads) to minimize data transfer.
- **Resumable Uploads**: Storage SDK handles network interruptions during large document/video uploads automatically.

---

## 4. Performance Monitoring

- **Firebase Performance Monitoring**: Automated tracking of app start time, screen traces, and network request latency.
- **Custom Traces**: "Time-to-Interactive" measurements for complex screens like the Unit Matrix and Gantt Chart.
- **Slow Query Audit**: Regular review of Firestore usage patterns to identify queries needing index optimization or denormalization.
