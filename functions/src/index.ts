import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { beforeUserSignedIn } from 'firebase-functions/v2/identity';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { initializeApp } from 'firebase-admin/app';

initializeApp();

const db = getFirestore();
const auth = getAuth();

type Membership = {
  tenantId: string;
  role: string;
  active: boolean;
};

function requireAuth(request: { auth?: { uid: string; token: Record<string, unknown> } }) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
  return request.auth;
}

async function getMembership(uid: string, tenantId: string): Promise<Membership> {
  const membership = await db.doc(`users/${uid}/memberships/${tenantId}`).get();
  if (!membership.exists || membership.data()?.active !== true) {
    throw new HttpsError('permission-denied', 'The user is not an active member of this tenant.');
  }

  const data = membership.data() ?? {};
  return {
    tenantId,
    role: String(data.role ?? 'SalesAgent'),
    active: true,
  };
}

export const listTenantMemberships = onCall(async (request) => {
  const currentUser = requireAuth(request);
  const memberships = await db.collection(`users/${currentUser.uid}/memberships`)
    .where('active', '==', true)
    .get();

  return memberships.docs.map((doc) => ({
    id: doc.id,
    name: String(doc.data().tenantName ?? doc.data().name ?? doc.id),
  }));
});

export const syncUserClaims = onCall(async (request) => {
  const currentUser = requireAuth(request);
  const memberships = await db.collection(`users/${currentUser.uid}/memberships`)
    .where('active', '==', true)
    .get();

  if (memberships.empty) {
    throw new HttpsError('failed-precondition', 'No active tenant memberships were found.');
  }

  const activeTenantId = String(currentUser.token.tenantId ?? memberships.docs[0].id);
  const selected = memberships.docs.find((doc) => doc.id === activeTenantId) ?? memberships.docs[0];
  const role = String(selected.data().role ?? 'SalesAgent');
  const tenantIds = memberships.docs.map((doc) => doc.id);

  await auth.setCustomUserClaims(currentUser.uid, {
    tenantId: selected.id,
    role,
    tenants: tenantIds,
  });

  return { tenantId: selected.id, role, tenants: tenantIds };
});

export const switchTenant = onCall(async (request) => {
  const currentUser = requireAuth(request);
  const tenantId = request.data?.tenantId;

  if (typeof tenantId !== 'string' || tenantId.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'A tenantId is required.');
  }

  const membership = await getMembership(currentUser.uid, tenantId);
  await auth.setCustomUserClaims(currentUser.uid, {
    tenantId: membership.tenantId,
    role: membership.role,
    tenants: Array.isArray(currentUser.token.tenants)
      ? currentUser.token.tenants
      : [membership.tenantId],
  });

  return {
    tenantId: membership.tenantId,
    role: membership.role,
    requiresTokenRefresh: true,
  };
});

export const onUserSignedIn = beforeUserSignedIn(async (event) => {
  const user = event.data;

  // Fix for TS18048: user is possibly undefined
  if (!user) {
    return;
  }

  const membership = await db.collection(`users/${user.uid}/memberships`)
    .where('active', '==', true)
    .limit(1)
    .get();

  if (membership.empty) {
    return;
  }

  const firstMembership = membership.docs[0];
  const role = String(firstMembership.data().role ?? 'SalesAgent');
  
  // Re-fetch memberships to set the list of authorized tenants in claims
  const memberships = await db.collection(`users/${user.uid}/memberships`)
    .where('active', '==', true)
    .get();

  return {
    customClaims: {
      tenantId: firstMembership.id,
      role,
      tenants: memberships.docs.map((doc) => doc.id),
    },
  };
});

export const reserveUnit = onCall(async (request) => {
  const currentUser = requireAuth(request);
  const tenantId = String(currentUser.token.tenantId ?? '');
  const { projectId, unitId, leadId } = request.data ?? {};

  if (!tenantId || !projectId || !unitId || !leadId) {
    throw new HttpsError('invalid-argument', 'tenantId, projectId, unitId, and leadId are required.');
  }

  const unitRef = db.doc(`tenants/${tenantId}/projects/${projectId}/units/${unitId}`);
  const leadRef = db.doc(`tenants/${tenantId}/leads/${leadId}`);

  await db.runTransaction(async (transaction) => {
    const [unit, lead] = await Promise.all([
      transaction.get(unitRef),
      transaction.get(leadRef),
    ]);

    if (!unit.exists || !lead.exists) {
      throw new HttpsError('not-found', 'The unit or lead does not exist.');
    }
    if (unit.data()?.status !== 'Available') {
      throw new HttpsError('failed-precondition', 'The unit is not available.');
    }

    transaction.update(unitRef, {
      status: 'Reserved',
      currentLeadId: leadId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(leadRef, {
      'pipeline.stage': 'Reservation',
      'unitReservation.projectId': projectId,
      'unitReservation.unitId': unitId,
      'unitReservation.reservedAt': FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return { status: 'Reserved', projectId, unitId, leadId };
});

export * from './finance/paymentWebhooks';
export * from './pipelines/dataPipelines';
export * from './ai/aiAssistant';
export * from './notifications/notificationTriggers';