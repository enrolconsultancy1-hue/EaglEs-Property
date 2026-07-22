import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onObjectFinalized } from 'firebase-functions/v2/storage';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { defineSecret } from 'firebase-functions/params';

// Note: For actual Vision AI, install @google-cloud/vision
// import vision from '@google-cloud/vision';
// const client = new vision.ImageAnnotatorClient();

const db = getFirestore();
const typesenseApiKey = defineSecret('TYPESENSE_API_KEY');

export const processDocumentOcr = onObjectFinalized(
  { cpu: 2, memory: '1GiB' },
  async (event) => {
    const fileBucket = event.data.bucket;
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    if (!filePath || !contentType) return;
    
    // Only process images/pdfs in the 'documents' directory
    if (!filePath.includes('/documents/')) return;
    if (!contentType.startsWith('image/') && contentType !== 'application/pdf') return;

    try {
      // Mock Vision AI processing
      console.log(`Processing OCR for gs://${fileBucket}/${filePath}`);
      
      /*
      // Real Implementation
      const [result] = await client.documentTextDetection(`gs://${fileBucket}/${filePath}`);
      const fullTextAnnotation = result.fullTextAnnotation;
      const extractedText = fullTextAnnotation ? fullTextAnnotation.text : '';
      */
      
      const extractedText = 'MOCK_OCR_TEXT: This is simulated extracted text from the document.';

      // Extract tenantId and docId from filePath assuming structure: tenants/{tenantId}/documents/{docId}/{filename}
      const parts = filePath.split('/');
      const tenantIndex = parts.indexOf('tenants');
      const docIndex = parts.indexOf('documents');

      if (tenantIndex !== -1 && docIndex !== -1 && parts.length > docIndex + 1) {
        const tenantId = parts[tenantIndex + 1];
        const docId = parts[docIndex + 1];

        // Update the document record in Firestore with extracted text
        await db.doc(`tenants/${tenantId}/documents/${docId}`).set({
          extractedText,
          ocrStatus: 'completed',
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }

    } catch (error) {
      console.error('OCR Processing failed', error);
    }
  }
);

export const syncPropertiesToTypesense = onDocumentWritten(
  { document: 'tenants/{tenantId}/properties/{propertyId}', secrets: [typesenseApiKey] },
  async (event) => {
    const snapshot = event.data;
    const tenantId = event.params.tenantId;
    const propertyId = event.params.propertyId;

    if (!snapshot) return;

    try {
      if (!snapshot.after.exists) {
        // Document deleted, remove from Typesense
        console.log(`Deleting property ${propertyId} from Typesense`);
        /*
        await typesenseClient.collections('properties').documents(propertyId).delete();
        */
        return;
      }

      const propertyData = snapshot.after.data();
      
      // Sync to Typesense
      console.log(`Upserting property ${propertyId} to Typesense index`);
      /*
      await typesenseClient.collections('properties').documents().upsert({
        id: propertyId,
        tenantId: tenantId,
        title: propertyData?.title,
        price: propertyData?.price,
        location: propertyData?.location,
        // ... other searchable fields
      });
      */
    } catch (error) {
      console.error(`Typesense Sync failed for property ${propertyId}`, error);
    }
  }
);
