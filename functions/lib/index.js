"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.reserveUnit = exports.onUserSignedIn = exports.switchTenant = exports.syncUserClaims = exports.listTenantMemberships = void 0;
const https_1 = require("firebase-functions/v2/https");
const identity_1 = require("firebase-functions/v2/identity");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const app_1 = require("firebase-admin/app");
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const auth = (0, auth_1.getAuth)();
function requireAuth(request) {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Authentication is required.');
    }
    return request.auth;
}
async function getMembership(uid, tenantId) {
    const membership = await db.doc(`users/${uid}/memberships/${tenantId}`).get();
    if (!membership.exists || membership.data()?.active !== true) {
        throw new https_1.HttpsError('permission-denied', 'The user is not an active member of this tenant.');
    }
    const data = membership.data() ?? {};
    return {
        tenantId,
        role: String(data.role ?? 'SalesAgent'),
        active: true,
    };
}
exports.listTenantMemberships = (0, https_1.onCall)(async (request) => {
    const currentUser = requireAuth(request);
    const memberships = await db.collection(`users/${currentUser.uid}/memberships`)
        .where('active', '==', true)
        .get();
    return memberships.docs.map((doc) => ({
        id: doc.id,
        name: String(doc.data().tenantName ?? doc.data().name ?? doc.id),
    }));
});
exports.syncUserClaims = (0, https_1.onCall)(async (request) => {
    const currentUser = requireAuth(request);
    const memberships = await db.collection(`users/${currentUser.uid}/memberships`)
        .where('active', '==', true)
        .get();
    if (memberships.empty) {
        throw new https_1.HttpsError('failed-precondition', 'No active tenant memberships were found.');
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
exports.switchTenant = (0, https_1.onCall)(async (request) => {
    const currentUser = requireAuth(request);
    const tenantId = request.data?.tenantId;
    if (typeof tenantId !== 'string' || tenantId.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'A tenantId is required.');
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
exports.onUserSignedIn = (0, identity_1.beforeUserSignedIn)(async (event) => {
    const user = event.data;
    const membership = await db.collection(`users/${user.uid}/memberships`)
        .where('active', '==', true)
        .limit(1)
        .get();
    if (membership.empty) {
        return;
    }
    const firstMembership = membership.docs[0];
    const role = String(firstMembership.data().role ?? 'SalesAgent');
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
exports.reserveUnit = (0, https_1.onCall)(async (request) => {
    const currentUser = requireAuth(request);
    const tenantId = String(currentUser.token.tenantId ?? '');
    const { projectId, unitId, leadId } = request.data ?? {};
    if (!tenantId || !projectId || !unitId || !leadId) {
        throw new https_1.HttpsError('invalid-argument', 'tenantId, projectId, unitId, and leadId are required.');
    }
    const unitRef = db.doc(`tenants/${tenantId}/projects/${projectId}/units/${unitId}`);
    const leadRef = db.doc(`tenants/${tenantId}/leads/${leadId}`);
    await db.runTransaction(async (transaction) => {
        const [unit, lead] = await Promise.all([
            transaction.get(unitRef),
            transaction.get(leadRef),
        ]);
        if (!unit.exists || !lead.exists) {
            throw new https_1.HttpsError('not-found', 'The unit or lead does not exist.');
        }
        if (unit.data()?.status !== 'Available') {
            throw new https_1.HttpsError('failed-precondition', 'The unit is not available.');
        }
        transaction.update(unitRef, {
            status: 'Reserved',
            currentLeadId: leadId,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        transaction.update(leadRef, {
            'pipeline.stage': 'Reservation',
            'unitReservation.projectId': projectId,
            'unitReservation.unitId': unitId,
            'unitReservation.reservedAt': firestore_1.FieldValue.serverTimestamp(),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
    });
    return { status: 'Reserved', projectId, unitId, leadId };
});
