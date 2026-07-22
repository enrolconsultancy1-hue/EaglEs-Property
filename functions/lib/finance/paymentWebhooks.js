"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.mpesaWebhook = exports.chapaWebhook = exports.telebirrCallback = exports.stripeWebhook = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const params_1 = require("firebase-functions/params");
const stripe_1 = __importDefault(require("stripe"));
const crypto = __importStar(require("crypto"));
const db = (0, firestore_1.getFirestore)();
// Secrets configured via GCP Secret Manager for production security
const stripeSecret = (0, params_1.defineSecret)('STRIPE_SECRET_KEY');
const stripeWebhookSecret = (0, params_1.defineSecret)('STRIPE_WEBHOOK_SECRET');
const telebirrPublicKey = (0, params_1.defineSecret)('TELEBIRR_PUBLIC_KEY');
const chapaWebhookSecret = (0, params_1.defineSecret)('CHAPA_WEBHOOK_SECRET');
// mpesa secrets
const mpesaConsumerKey = (0, params_1.defineSecret)('MPESA_CONSUMER_KEY');
const mpesaConsumerSecret = (0, params_1.defineSecret)('MPESA_CONSUMER_SECRET');
exports.stripeWebhook = (0, https_1.onRequest)({ secrets: [stripeSecret, stripeWebhookSecret] }, async (req, res) => {
    const sig = req.headers['stripe-signature'];
    if (!sig) {
        res.status(400).send('Missing stripe signature');
        return;
    }
    const stripe = new stripe_1.default(stripeSecret.value(), { apiVersion: '2026-06-24.dahlia' });
    try {
        // Verify signature using rawBody
        const event = stripe.webhooks.constructEvent(req.rawBody, sig, stripeWebhookSecret.value());
        if (event.type === 'payment_intent.succeeded') {
            const paymentIntent = event.data.object;
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
                        createdAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                    tx.update(invoiceRef, {
                        'totals.paid': firestore_1.FieldValue.increment(paymentIntent.amount),
                        status: 'paid',
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                });
            }
        }
        res.status(200).json({ received: true });
    }
    catch (err) {
        res.status(400).send(`Webhook error: ${err.message}`);
    }
});
exports.telebirrCallback = (0, https_1.onRequest)({ secrets: [telebirrPublicKey] }, async (req, res) => {
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
                createdAt: firestore_1.FieldValue.serverTimestamp(),
            });
            tx.update(invoiceRef, {
                'totals.paid': firestore_1.FieldValue.increment(Number(totalAmount)),
                status: 'paid',
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            });
        });
        res.status(200).json({ code: 0, message: 'SUCCESS' });
    }
    catch (err) {
        console.error('Telebirr Webhook Error:', err);
        res.status(500).json({ code: 500, message: err.message });
    }
});
exports.chapaWebhook = (0, https_1.onRequest)({ secrets: [chapaWebhookSecret] }, async (req, res) => {
    try {
        const signature = req.headers['chapa-signature'];
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
                        createdAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                    tx.update(invoiceRef, {
                        'totals.paid': firestore_1.FieldValue.increment(event.amount),
                        status: 'paid',
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                });
            }
        }
        res.status(200).send('OK');
    }
    catch (err) {
        console.error('Chapa Webhook Error:', err);
        res.status(500).send(`Webhook error: ${err.message}`);
    }
});
exports.mpesaWebhook = (0, https_1.onRequest)(async (req, res) => {
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
                const amountItem = callbackMetadata.find((i) => i.Name === 'Amount');
                const amount = amountItem ? amountItem.Value : 0;
                await db.runTransaction(async (tx) => {
                    const pDoc = await tx.get(paymentRef);
                    if (pDoc.exists && pDoc.data()?.status === 'completed')
                        return;
                    tx.update(paymentRef, {
                        status: 'completed',
                        amount: amount,
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                    tx.update(invoiceRef, {
                        'totals.paid': firestore_1.FieldValue.increment(amount),
                        status: 'paid',
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
                    });
                });
            }
            else {
                await paymentRef.update({
                    status: 'failed',
                    failureReason: callbackData.ResultDesc,
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                });
            }
        }
        res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
    }
    catch (err) {
        console.error('M-Pesa Webhook Error:', err);
        res.status(500).json({ ResultCode: 1, ResultDesc: err.message });
    }
});
