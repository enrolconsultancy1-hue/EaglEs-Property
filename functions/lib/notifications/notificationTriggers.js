"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onPaymentStatusNotification = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const messaging_1 = require("firebase-admin/messaging");
const firebase_functions_1 = require("firebase-functions");
const messaging = (0, messaging_1.getMessaging)();
exports.onPaymentStatusNotification = (0, firestore_1.onDocumentWritten)('tenants/{tenantId}/payments/{paymentId}', async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    if (!after)
        return;
    // Check if status changed to 'completed' or 'success'
    if (after.status === 'completed' && before?.status !== 'completed') {
        const tenantId = event.params.tenantId;
        const amount = after.amount ?? 0;
        const currency = after.currency ?? 'ETB';
        const payerName = after.payerName ?? 'Valued Customer';
        firebase_functions_1.logger.info(`Payment notification trigger fired for tenant ${tenantId}, amount ${amount} ${currency}`);
        // Dispatch FCM Push Notification topic
        try {
            await messaging.send({
                topic: `tenant_${tenantId}_finance`,
                notification: {
                    title: 'Payment Confirmation Received',
                    body: `Payment of ${amount} ${currency} from ${payerName} was successfully processed.`,
                },
                data: {
                    paymentId: event.params.paymentId,
                    type: 'payment_success',
                },
            });
            firebase_functions_1.logger.info(`FCM payment notification sent successfully to topic tenant_${tenantId}_finance`);
        }
        catch (err) {
            firebase_functions_1.logger.error('Failed to send FCM payment notification:', err);
        }
    }
});
