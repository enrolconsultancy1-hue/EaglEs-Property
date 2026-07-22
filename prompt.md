# EaglEs Property — Master Design Prompt

You are an award-winning Principal Software Architect, Enterprise Solution Architect, Flutter Tech Lead, Firebase Architect, UX Architect, AI Engineer and Product Designer.

Your mission is to design and build a world-class enterprise SaaS platform called

# EaglEs Property

Do NOT build a simple property listing application.

Build an Enterprise Multi-Tenant Real Estate Operating System that combines the capabilities of:

• Zillow
• LoopNet
• CoStar
• RealPage
• Yardi Voyager
• Salesforce CRM
• SAP Real Estate
• Autodesk Construction Cloud
• Procore
• Monday.com
• Microsoft Dynamics
• Oracle Property Management

into one unified cloud platform.

==================================================
PRIMARY GOAL
==================================================

EaglEs Property enables Real Estate Developers, Property Owners, Brokers, Investors, Banks, Contractors, Architects, Consultants, Lawyers, Tenants and Buyers to collaborate inside one ecosystem.

This is a Software-as-a-Service (SaaS) platform built for global use.

==================================================
TECH STACK
==================================================

Frontend

• Flutter latest stable
• Material 3
• Riverpod
• Go Router
• Responsive Layout
• Desktop
• Android
• iOS
• Web

Backend

Firebase

Use

• Authentication
• Firestore
• Cloud Functions
• Firebase Storage
• Firebase Messaging
• Analytics
• Remote Config
• App Check
• Crashlytics

Use Firestore as the primary database.

==================================================
MULTI TENANT ARCHITECTURE
==================================================

The system MUST support unlimited tenants.

Tenant examples

Developer A

Developer B

Developer C

Government

Bank

Broker Company

Construction Company

Each tenant has

• own users
• own projects
• own branding
• own permissions
• own reports
• own storage
• own dashboards

No tenant can access another tenant's data.

Every Firestore document must include tenantId.

Support:

• Super Admin
• Platform Admin
• Tenant Owner
• Organization Admin
• Manager
• Sales
• Finance
• Marketing
• Construction Manager
• Site Engineer
• Architect
• Lawyer
• Property Manager
• Tenant
• Buyer
• Investor
• Guest

==================================================
MODULES
==================================================

1. Developer Management

Company Profile, Branches, Departments, Employees, Licenses, Documents

2. Project Management

Residential, Commercial, Mixed Use, Industrial, Hotels, Smart Cities, Master Plans

3. Construction Management

Project Schedule, Tasks, Gantt, Milestones, Budget, Site Progress, Inspection, Variation Orders, Daily Reports, Photo Logs, Drone Images

4. Inventory

Buildings, Blocks, Floors, Units, Shops, Parking, Warehouses, Land, Offices

5. Sales CRM

Lead Capture, Sales Pipeline, Opportunities, Reservations, Bookings, Contracts, Digital Signature, Follow-up, AI Lead Scoring

6. Property Marketplace

Property Listings, Search, Map Search, Virtual Tour, Favorites, Recommendations, Comparison, Mortgage Calculator

7. Customer Portal

Bookings, Payments, Contracts, Invoices, Support, Maintenance Requests, Chat, Notifications

8. Rental Management

Lease, Renewal, Rent Collection, Deposit, Vacancy, Tenant Portal

9. Facilities Management

Maintenance, Cleaning, Security, Equipment, Assets

10. Financial Module

Invoices, Receipts, Expenses, Budget, Revenue, Cashflow, Reports

11. Document Management

Blueprints, CAD, Contracts, Permits, Certificates, PDF, Photos, Videos

12. AI Assistant

Project Analysis, Construction Risk, Sales Prediction, Demand Forecast, Market Insights, Chat Assistant, Document Summaries

13. Analytics Dashboard

Executive KPIs, Sales, Occupancy, Revenue, Construction Progress, Cash Flow, Heat Maps, Forecasts

==================================================
PROPERTY FEATURES
==================================================

Support

Residential, Commercial, Office, Mall, Warehouse, Hospital, Hotel, School, Factory, Land, Farm, Industrial Park, Apartment, Villa, Townhouse, Condominium

==================================================
INTERACTIVE MAPS
==================================================

Google Maps, Property Pins, Clusters, Nearby Services, Schools, Hospitals, Banks, Roads, Satellite, Street View, Distance, Drawing Tools

==================================================
3D FEATURES
==================================================

Support

Matterport, 360 Tours, Floor Plans, Building Viewer, Future Digital Twin Integration

==================================================
AI FEATURES
==================================================

AI Property Recommendation, AI Price Estimation, AI Investment Score, AI Construction Delay Prediction, AI Customer Assistant, AI Contract Review, AI Image Recognition, AI Document OCR, AI Chatbot

==================================================
COMMUNICATION
==================================================

Chat, Video Meeting, Email, SMS, Push Notification, Announcement, Support Tickets

==================================================
PAYMENTS
==================================================

Stripe, PayPal, Bank Transfer, Mobile Money, Telebirr, M-Pesa, Chapa, Offline Payment Approval

==================================================
SECURITY
==================================================

Firebase Authentication, Role Based Access, Firestore Security Rules, Audit Logs, Encryption, Activity Tracking, 2FA Ready

==================================================
ADMIN PANEL
==================================================

Platform Dashboard, Tenant Dashboard, Billing, Subscription, User Management, Permissions, Logs, AI Monitoring, Analytics

==================================================
UI DESIGN
==================================================

Premium enterprise UI.

Inspired by: Salesforce, Monday.com, Notion, ClickUp, Linear, Apple, Google Material 3, Microsoft Fluent

Use glassmorphism carefully. Professional spacing. Excellent typography. Responsive. Beautiful animations. Dark Mode. Light Mode.

==================================================
ARCHITECTURE
==================================================

Use Clean Architecture. Feature-first folder structure. Repository Pattern. Riverpod. Dependency Injection. Service Layer. Offline First. Scalable. Highly Testable. Enterprise Ready.

==================================================
DELIVERABLES
==================================================

Generate

1. Complete System Architecture
2. Firestore Database Design
3. Firestore Collections
4. Security Rules
5. Flutter Folder Structure
6. Navigation Structure
7. Wireframes
8. UI Design System
9. Reusable Widgets
10. API Layer
11. Firebase Integration
12. Cloud Functions
13. Authentication Flow
14. Role Permission Matrix
15. State Management
16. Testing Strategy
17. CI/CD Pipeline
18. Deployment Strategy
19. Performance Optimization
20. Implementation Roadmap

Do NOT skip architecture.

Do NOT generate placeholder code.

Design every module completely before implementation.

Every feature must be enterprise-grade and production-ready.
