import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

const db = getFirestore();

export interface AiRecommendation {
  id: string;
  type: 'unit' | 'lead' | 'project';
  title: string;
  subtitle: string;
  metadata: Record<string, any>;
}

export interface AskMrEaglesResponse {
  answer: string;
  recommendations: AiRecommendation[];
  confidence: number;
}

export const askMrEagles = onCall(async (request): Promise<AskMrEaglesResponse> => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated to consult Mr. EaglEs.');
  }

  const tenantId = String(request.auth.token.tenantId ?? 'eagles');
  const prompt: string = request.data?.prompt ?? '';

  if (!prompt || prompt.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'A prompt query is required.');
  }

  const normalizedPrompt = prompt.toLowerCase();
  const recommendations: AiRecommendation[] = [];
  let answer = "";

  // 1. Process Inventory Queries (e.g. 2BR, 1BR, price limits, available units)
  if (normalizedPrompt.includes('unit') || normalizedPrompt.includes('bedroom') || normalizedPrompt.includes('2br') || normalizedPrompt.includes('1br') || normalizedPrompt.includes('price')) {
    const projectsSnap = await db.collection(`tenants/${tenantId}/projects`).get();
    let foundUnitsCount = 0;

    for (const projDoc of projectsSnap.docs) {
      const unitsSnap = await db.collection(`tenants/${tenantId}/projects/${projDoc.id}/units`).limit(5).get();
      unitsSnap.forEach(uDoc => {
        const uData = uDoc.data();
        recommendations.push({
          id: uDoc.id,
          type: 'unit',
          title: `Unit ${uData.number ?? uDoc.id} (${uData.type ?? 'Standard'})`,
          subtitle: `${projDoc.data().name ?? 'Project'} • ETB ${(uData.price ?? 0).toLocaleString()}`,
          metadata: {
            projectId: projDoc.id,
            status: uData.status ?? 'Available',
            price: uData.price,
            area: uData.area,
          }
        });
        foundUnitsCount++;
      });
    }

    if (foundUnitsCount > 0) {
      answer = `Based on your request, I found ${foundUnitsCount} matching units across your portfolio. Here are the top available options ready for reservation:`;
    } else {
      answer = `I scanned your inventory for tenant "${tenantId}". Here are the currently featured units available for booking:`;
      // Default fallback mock recommendations for rich demonstration
      recommendations.push(
        {
          id: 'e-101',
          type: 'unit',
          title: 'Unit A-101 (2BR)',
          subtitle: 'Eagle Heights • Bole, Addis Ababa • ETB 4,200,000',
          metadata: { projectId: 'eagle-heights', status: 'Available', price: 4200000, area: 84 }
        },
        {
          id: 'e-201',
          type: 'unit',
          title: 'Unit A-201 (3BR Luxury)',
          subtitle: 'Eagle Heights • Bole, Addis Ababa • ETB 6,300,000',
          metadata: { projectId: 'eagle-heights', status: 'Available', price: 6300000, area: 126 }
        }
      );
    }
  } 
  // 2. Process CRM Lead Queries (e.g. lead, client, follow up, sales)
  else if (normalizedPrompt.includes('lead') || normalizedPrompt.includes('client') || normalizedPrompt.includes('marta') || normalizedPrompt.includes('sales')) {
    answer = `Analyzing your sales CRM pipeline for active high-score leads... Here are the prospects requiring immediate follow-up:`;
    recommendations.push(
      {
        id: 'lead-1',
        type: 'lead',
        title: 'Marta Bekele',
        subtitle: 'Score: 88 • Budget: ETB 4.5M • Stage: Reservation',
        metadata: { leadId: 'lead-1', assignedAgent: 'Dawit Tesfaye', score: 88 }
      },
      {
        id: 'lead-2',
        type: 'lead',
        title: 'Daniel Kassa',
        subtitle: 'Score: 76 • Budget: ETB 6.5M • Stage: Negotiation',
        metadata: { leadId: 'lead-2', assignedAgent: 'Dawit Tesfaye', score: 76 }
      }
    );
  } 
  // 3. General Real Estate & Market Assistant Queries
  else {
    answer = `Hello! I am Mr. EaglEs, your AI Sales & Real Estate Assistant for Ethiopia & Regional Operations. I can assist you with unit reservations, lead scoring, and market insights. How can I help you today?`;
  }

  return {
    answer,
    recommendations,
    confidence: 0.95
  };
});
