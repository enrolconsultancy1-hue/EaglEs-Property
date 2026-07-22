import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';

const messaging = getMessaging();

export const onPaymentStatusNotification = onDocumentWritten(
  'tenants/{tenantId}/payments/{paymentId}',
  async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();

    if (!after) return;

    // Check if status changed to 'completed' or 'success'
    if (after.status === 'completed' && before?.status !== 'completed') {
      const tenantId = event.params.tenantId;
      const amount = after.amount ?? 0;
      const currency = after.currency ?? 'ETB';
      const payerName = after.payerName ?? 'Valued Customer';

      logger.info(`Payment notification trigger fired for tenant ${tenantId}, amount ${amount} ${currency}`);

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
        logger.info(`FCM payment notification sent successfully to topic tenant_${tenantId}_finance`);
      } catch (err) {
        logger.error('Failed to send FCM payment notification:', err);
      }
    }
  }
);
