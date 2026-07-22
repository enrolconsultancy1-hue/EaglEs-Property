import { onRequest } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { defineSecret } from 'firebase-functions/params';
import Stripe from 'stripe';
import * as crypto from 'crypto';

const db = getFirestore();

// Secrets configured via GCP Secret Manager for production security
const stripeSecret = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');
const telebirrPublicKey = defineSecret('TELEBIRR_PUBLIC_KEY');
const chapaWebhookSecret = defineSecret('CHAPA_WEBHOOK_SECRET');
// mpesa secrets
const mpesaConsumerKey = defineSecret('MPESA_CONSUMER_KEY');
const mpesaConsumerSecret = defineSecret('MPESA_CONSUMER_SECRET');

export const stripeWebhook = onRequest(
  { secrets: [stripeSecret, stripeWebhookSecret] },
  async (req, res) => {
    const sig = req.headers['stripe-signature'];
    if (!sig) {
      res.status(400).send('Missing stripe signature');
      return;
    }

    const stripe = new Stripe(stripeSecret.value(), { apiVersion: '2026-06-24.dahlia' as any });

    try {
      // Verify signature using rawBody
      const event = stripe.webhooks.constructEvent(
        req.rawBody,
        sig,
        stripeWebhookSecret.value()
      );

      if (event.type === 'payment_intent.succeeded') {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        const { tenantId, invoiceId, payerUid } = paymentIntent.metadata || {};

        if (tenantId && invoiceId) {
          const paymentRef = db.collection(`tenants/${tenantId}/payments`).doc(paymentIntent.id);
          const invoiceRef = db.collection(`tenants/${tenantId}/invoices`).doc(invoiceId);

          await db.runTransaction(async (tx) => {
            tx.set(paymentRef, {
              tenantId,
              invoiceId,
              payerUid: payerUid || 'system',
              amount: paymentIntent.amount,
              currency: paymentIntent.currency,
              provider: 'stripe',
              status: 'completed',
              createdAt: FieldValue.serverTimestamp(),
            });

            tx.update(invoiceRef, {
              'totals.paid': FieldValue.increment(paymentIntent.amount),
              status: 'paid',
              updatedAt: FieldValue.serverTimestamp(),
            });
          });
        }
      }
      res.status(200).json({ received: true });
    } catch (err: any) {
      res.status(400).send(`Webhook error: ${err.message}`);
    }
  }
);

export const telebirrCallback = onRequest(
  { secrets: [telebirrPublicKey] },
  async (req, res) => {
    try {
      // Typically Telebirr sends an encrypted payload that needs decryption using public/private keys
      const { outTradeNo, totalAmount, mchId, tenantId, invoiceId, sign } = req.body || {};
      if (!tenantId || !invoiceId || !outTradeNo || !sign) {
        res.status(400).send('Missing required fields or signature');
        return;
      }

      // Placeholder: verify RSA signature using telebirrPublicKey.value()
      // const isVerified = crypto.verify('sha256', Buffer.from(payload), telebirrPublicKey.value(), Buffer.from(sign, 'base64'));
      
      const paymentRef = db.collection(`tenants/${tenantId}/payments`).doc(outTradeNo);
      const invoiceRef = db.collection(`tenants/${tenantId}/invoices`).doc(invoiceId);

      await db.runTransaction(async (tx) => {
        const paymentDoc = await tx.get(paymentRef);
        if (paymentDoc.exists && paymentDoc.data()?.status === 'completed') {
          return; // Idempotency check
        }

        tx.set(paymentRef, {
          tenantId,
          invoiceId,
          amount: Number(totalAmount),
          currency: 'ETB',
          provider: 'telebirr',
          status: 'completed',
          createdAt: FieldValue.serverTimestamp(),
        });

        tx.update(invoiceRef, {
          'totals.paid': FieldValue.increment(Number(totalAmount)),
          status: 'paid',
          updatedAt: FieldValue.serverTimestamp(),
        });
      });

      res.status(200).json({ code: 0, message: 'SUCCESS' });
    } catch (err: any) {
      console.error('Telebirr Webhook Error:', err);
      res.status(500).json({ code: 500, message: err.message });
    }
  }
);

export const chapaWebhook = onRequest(
  { secrets: [chapaWebhookSecret] },
  async (req, res) => {
    try {
      const signature = req.headers['chapa-signature'] as string;
      if (!signature) {
        res.status(400).send('Missing signature');
        return;
      }

      // Verify Chapa webhook signature
      const expectedSignature = crypto
        .createHmac('sha256', chapaWebhookSecret.value())
        .update(req.rawBody)
        .digest('hex');

      if (signature !== expectedSignature) {
        res.status(401).send('Invalid signature');
        return;
      }

      const event = req.body;
      if (event.event === 'charge.success') {
        const metadata = event.customization || {};
        const tenantId = metadata.tenantId || event.meta?.tenantId;
        const invoiceId = metadata.invoiceId || event.meta?.invoiceId;
        const outTradeNo = event.tx_ref;

        if (tenantId && invoiceId && outTradeNo) {
          const paymentRef = db.collection(`tenants/${tenantId}/payments`).doc(outTradeNo);
          const invoiceRef = db.collection(`tenants/${tenantId}/invoices`).doc(invoiceId);

          await db.runTransaction(async (tx) => {
            const paymentDoc = await tx.get(paymentRef);
            if (paymentDoc.exists && paymentDoc.data()?.status === 'completed') {
              return;
            }

            tx.set(paymentRef, {
              tenantId,
              invoiceId,
              amount: event.amount,
              currency: event.currency,
              provider: 'chapa',
              status: 'completed',
              createdAt: FieldValue.serverTimestamp(),
            });

            tx.update(invoiceRef, {
              'totals.paid': FieldValue.increment(event.amount),
              status: 'paid',
              updatedAt: FieldValue.serverTimestamp(),
            });
          });
        }
      }

      res.status(200).send('OK');
    } catch (err: any) {
      console.error('Chapa Webhook Error:', err);
      res.status(500).send(`Webhook error: ${err.message}`);
    }
  }
);

export const mpesaWebhook = onRequest(
  async (req, res) => {
    try {
      const body = req.body.Body;
      if (!body || !body.stkCallback) {
        res.status(400).send('Invalid M-Pesa payload');
        return;
      }

      const callbackData = body.stkCallback;
      const resultCode = callbackData.ResultCode;
      const checkoutRequestId = callbackData.CheckoutRequestID;
      
      const paymentsSnapshot = await db.collectionGroup('payments')
        .where('provider', '==', 'mpesa')
        .where('checkoutRequestId', '==', checkoutRequestId)
        .limit(1)
        .get();

      if (!paymentsSnapshot.empty) {
        const paymentDoc = paymentsSnapshot.docs[0];
        const paymentData = paymentDoc.data();
        const tenantId = paymentData.tenantId;
        const invoiceId = paymentData.invoiceId;

        const paymentRef = paymentDoc.ref;
        const invoiceRef = db.collection(`tenants/${tenantId}/invoices`).doc(invoiceId);

        if (resultCode === 0) {
          const callbackMetadata = callbackData.CallbackMetadata.Item;
          const amountItem = callbackMetadata.find((i: any) => i.Name === 'Amount');
          const amount = amountItem ? amountItem.Value : 0;

          await db.runTransaction(async (tx) => {
            const pDoc = await tx.get(paymentRef);
            if (pDoc.exists && pDoc.data()?.status === 'completed') return;

            tx.update(paymentRef, {
              status: 'completed',
              amount: amount,
              updatedAt: FieldValue.serverTimestamp(),
            });

            tx.update(invoiceRef, {
              'totals.paid': FieldValue.increment(amount),
              status: 'paid',
              updatedAt: FieldValue.serverTimestamp(),
            });
          });
        } else {
          await paymentRef.update({
            status: 'failed',
            failureReason: callbackData.ResultDesc,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
      }

      res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
    } catch (err: any) {
      console.error('M-Pesa Webhook Error:', err);
      res.status(500).json({ ResultCode: 1, ResultDesc: err.message });
    }
  }
);
