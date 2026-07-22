# Mr. EaglEs — developer-contracted property sales agent

## Product decision

Mr. EaglEs should be implemented as a **humanized sales-agent operating system**, not as an autonomous promise-making bot. It can represent a developer within an explicitly approved mandate, qualify and nurture buyers, present approved property information, coordinate viewings, maintain attribution evidence, and move a qualified opportunity toward reservation or sale. A human developer representative remains the approval point for price exceptions, legal commitments, contract execution, refunds, and disputed commission outcomes.

## Value proposition

For real estate developers:

- More qualified buyer conversations without adding equivalent front-office headcount.
- Consistent, approved property information across channels.
- Traceable lead ownership from first contact to signed sale.
- A contract-controlled commission ledger instead of informal spreadsheets.
- Human escalation when a buyer or transaction requires judgment.

For buyers:

- A warm, responsive guide who understands the project and their needs.
- Clear next steps, transparent availability, and a human contact when needed.
- No fabricated availability, pricing, discounts, approvals, or legal advice.

For EaglEs Property:

- A repeatable supply-side service that can be sold to developers.
- A measurable link between marketing activity, attributed leads, closed sales, and agent payouts.

## Role definition

**Role name:** Mr. EaglEs Sales Agent

**Principal:** the contracted real estate developer or authorized project owner.

**Operating mode:** AI-assisted workflow with human supervision and developer-approved content.

**Core objective:** create and progress attributable buyer opportunities to a developer-approved sales milestone, then calculate and route commission according to the signed agreement.

### In scope

1. Publish and explain approved project, unit, amenity, location, and availability information.
2. Capture buyer consent and contact details.
3. Ask qualification questions: preferred project, unit type, budget range, timing, financing readiness, and viewing preference.
4. Match buyers to currently available units without reserving a unit unless the platform's reservation authority is active.
5. Schedule and confirm site visits or human calls.
6. Follow up using an approved cadence and record every material interaction.
7. Hand off qualified buyers to the developer's named representative.
8. Track attribution, milestone evidence, contract status, commission accrual, approval, and payout.

### Out of scope unless explicitly authorized

- Binding price changes, discounts, guarantees, or investment-return claims.
- Legal, tax, lending, immigration, or construction-safety advice.
- Signing a buyer sale contract as the developer.
- Accepting buyer money or holding deposits.
- Marking a unit sold without the developer's authoritative confirmation.
- Claiming commission merely because a conversation occurred.

## Humanized interaction standard

Mr. EaglEs should sound like a capable, respectful property professional:

- Use the buyer's name only after the buyer provides it.
- Ask one useful question at a time.
- Explain why a question helps with the recommendation.
- State uncertainty plainly: “I need the developer team to confirm that.”
- Give a clear next action after each interaction.
- Offer a human handoff whenever the buyer asks, shows confusion, raises a complaint, or requests a commitment outside the mandate.
- Identify itself as an AI-assisted representative of the contracted developer; do not impersonate an individual human employee.
- Never pressure a buyer with false scarcity or invented deadlines.

## Developer service agreement — minimum commercial terms

The platform should not generate a legally binding agreement without jurisdiction-specific legal review. It should provide a structured agreement record and an exportable draft for authorized parties to review and sign.

Required fields:

- Developer legal name, registration/contact details, authorized signatory.
- EaglEs contracting entity and authorized signatory.
- Project(s), territory, channels, and approved inventory scope.
- Effective date, term, renewal, termination, and post-termination tail period.
- Agent mandate: marketing only, lead generation, appointment setting, reservation support, or broader authority.
- Approved content and price source of truth.
- Lead attribution rule and duplicate-lead rule.
- Commission basis: fixed amount, percentage, tier, or hybrid.
- Commission trigger: qualified lead, attended viewing, reservation, signed sale, cleared payment, or another unambiguous milestone.
- Payment timing, currency, taxes/withholding, bank/payment details, and payout minimum if any.
- Cancellation, refund, buyer default, clawback, and commission reversal rules.
- Data processing, consent, privacy, retention, security, and marketing-contact permissions.
- Complaint handling, prohibited claims, audit rights, confidentiality, intellectual property, and dispute process.
- Human approval requirements and named developer contacts.

## Contract-to-payout workflow

```text
Draft agreement
  -> Developer review
  -> Approved / signed agreement
  -> Active mandate
  -> Approved inventory + content published
  -> Buyer consent + lead captured
  -> Attribution window starts
  -> Qualification / viewing / handoff
  -> Developer accepts or rejects attribution
  -> Reservation or sale confirmed by developer
  -> Payment milestone verified
  -> Commission accrued
  -> Developer approves payout
  -> Payout initiated
  -> Paid / reversed / disputed
```

### Attribution rules

Attribution must be evidence-based and deterministic:

- Generate a unique lead ID at first consented capture.
- Store source, campaign, channel, timestamp, consent evidence, and assigned agreement.
- Require a duplicate check against existing leads using approved matching fields.
- Let the developer accept, reject, or reassign attribution with a reason.
- Freeze the attribution decision after the contract-defined review period unless a dispute is opened.
- Preserve an append-only event history for every status change.

### Commission states

`not_eligible` → `pending_validation` → `accrued` → `developer_approved` → `scheduled` → `paid`

Exception states: `rejected`, `disputed`, `reversed`, `cancelled`.

A commission record must reference the agreement version, lead, project, unit, sale/reservation evidence, amount basis, calculation snapshot, approver, and payout event. Never recalculate historical payouts from today's contract terms.

## Minimum platform model

Add these entities after the existing lead, unit, invoice, and document models:

### `AgentAgreement`

- `id`, `tenantId`, `agentProfileId`
- `status`: draft, review, signed, active, suspended, expired, terminated
- `projects`, `channels`, `mandate`, `effectiveFrom`, `effectiveTo`
- `attributionWindowDays`, `tailWindowDays`
- `commissionRuleSnapshot`
- `signedDocumentId`, `signedAt`, `version`

### `LeadAttribution`

- `id`, `tenantId`, `agreementId`, `leadId`
- `source`, `campaign`, `channel`, `capturedAt`, `consentAt`
- `status`: pending, accepted, rejected, reassigned, frozen, disputed
- `developerDecision`, `decidedBy`, `decidedAt`

### `SalesMilestone`

- `id`, `tenantId`, `leadId`, `agreementId`, `projectId`, `unitId`
- `type`: qualified, viewing, reservation, signed_sale, cleared_payment
- `status`, `occurredAt`, `verifiedAt`, `verifiedBy`, `evidenceDocumentId`

### `CommissionLedgerEntry`

- `id`, `tenantId`, `agreementId`, `leadId`, `milestoneId`
- `unitId`, `basisAmount`, `rateOrFixedAmount`, `commissionAmount`, `currency`
- `status`, `calculationSnapshot`, `approvedBy`, `approvedAt`, `payoutId`

### `AgentInteraction`

- `id`, `tenantId`, `leadId`, `channel`, `direction`, `summary`
- `nextAction`, `createdAt`, `humanHandoff`, `consentEvidenceId`

## Minimum UI surfaces

1. **Developer → Agreements:** create/review/sign/activate agreement; show mandate and commission terms.
2. **Mr. EaglEs workspace:** approved projects, buyer conversations, qualification queue, follow-ups, handoffs.
3. **Lead detail:** attribution badge, consent, interaction timeline, milestones, documents, invoices, and human owner.
4. **Developer approval queue:** accept attribution, verify milestone, approve/reject commission, resolve disputes.
5. **Commission ledger:** accrued, approved, scheduled, paid, reversed, and disputed totals with evidence links.
6. **Buyer-facing disclosure:** AI-assisted representative disclosure, developer identity, privacy/marketing consent, and human contact option.

## Security and governance

- Tenant isolation must apply to agreements, leads, documents, milestones, and ledger entries.
- Only developer-authorized roles can activate agreements, approve attribution, verify sale milestones, or approve payouts.
- Mr. EaglEs may read only currently approved content and inventory.
- All outbound claims should be traceable to an approved content/version record.
- Payouts should be initiated only by a server-side function after approval; never by client-side Firestore writes.
- Keep immutable audit events for agreement changes, attribution decisions, milestone verification, and payout transitions.
- Treat payment and identity data as sensitive; store only what the workflow requires.

## Lowest-token implementation sequence

### Slice 1 — safest foundation

Add the four core models, Firestore streams, status enums, and read-only agreement/ledger screens. Use existing leads, units, invoices, and documents. No messaging provider or payment gateway yet.

### Slice 2 — revenue control

Add server-side callable functions for attribution acceptance, milestone verification, commission calculation snapshot, and payout approval. Add Firestore rules and audit events.

### Slice 3 — humanized agent workflow

Add approved response templates, qualification checklist, interaction timeline, human handoff, and developer content approval. Keep the AI behavior constrained to retrieved approved data.

### Slice 4 — integrations

Only after the contract and ledger are tested: add messaging channels, e-signature, payment provider, notifications, and automated follow-up.

## Recommended product positioning

> **Mr. EaglEs is the developer's contracted, AI-assisted property sales representative: it brings approved inventory to qualified buyers, hands serious opportunities to the developer's team, and turns verified sales milestones into transparent, contract-based commission payouts.**

This positioning is stronger and safer than claiming an autonomous agent can “sign contracts” or independently guarantee a sale. The platform can manage and evidence the contract; authorized humans or approved e-signature workflows execute the legally binding agreement.
