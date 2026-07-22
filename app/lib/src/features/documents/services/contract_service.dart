import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ContractService {
  static Future<Uint8List> generateSalesAgreementPdf({
    required String tenantName,
    required String buyerName,
    required String buyerEmail,
    required String projectLocation,
    required String unitNumber,
    required double priceEtb,
    Uint8List? signaturePngBytes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              cross: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  main: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      tenantName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'OFFICIAL SALES AGREEMENT',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                pw.SizedBox(height: 20),

                // Title
                pw.Center(
                  child: pw.Text(
                    'REAL ESTATE PROPERTY PURCHASE & RESERVATION AGREEMENT',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Details Grid
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    cross: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DEVELOPER / TENANT: $tenantName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('BUYER / CLIENT NAME: $buyerName ($buyerEmail)'),
                      pw.SizedBox(height: 4),
                      pw.Text('PROPERTY LOCATION: $projectLocation'),
                      pw.SizedBox(height: 4),
                      pw.Text('UNIT DESIGNATION: Unit $unitNumber'),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'TOTAL AGREED PRICE: ETB ${priceEtb.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Standard Contract Terms
                pw.Text('CONTRACT TERMS & CONDITIONS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text(
                  '1. The buyer agrees to reserve the specified unit under the multi-tenant real estate registry guidelines of Ethiopia.\n'
                  '2. Payment schedules shall follow the agreed milestones via verified gateway partners (Telebirr, Chapa, M-Pesa, or Direct Bank Wire).\n'
                  '3. Ownership transfer certificates will be issued upon 100% settlement of total valuation.\n'
                  '4. This contract is generated and cryptographically tracked via EaglEs Property Platform.',
                  style: const pw.TextStyle(fontSize: 10, lineHeight: 1.4),
                ),

                pw.Spacer(),

                // Signatures Section
                pw.Row(
                  main: pw.MainAxisAlignment.spaceBetween,
                  cross: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      cross: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 150,
                          height: 1,
                          color: PdfColors.grey800,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Authorized Developer Seal', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      cross: pw.CrossAxisAlignment.center,
                      children: [
                        if (signaturePngBytes != null && signaturePngBytes.isNotEmpty)
                          pw.Image(
                            pw.MemoryImage(signaturePngBytes),
                            width: 120,
                            height: 50,
                          )
                        else
                          pw.Container(height: 50),
                        pw.Container(
                          width: 150,
                          height: 1,
                          color: PdfColors.grey800,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Buyer Digital Signature', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrPreviewSalesAgreement({
    required String tenantName,
    required String buyerName,
    required String buyerEmail,
    required String projectLocation,
    required String unitNumber,
    required double priceEtb,
    Uint8List? signaturePngBytes,
  }) async {
    final pdfBytes = await generateSalesAgreementPdf(
      tenantName: tenantName,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      projectLocation: projectLocation,
      unitNumber: unitNumber,
      priceEtb: priceEtb,
      signaturePngBytes: signaturePngBytes,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Sales_Agreement_${buyerName.replaceAll(' ', '_')}.pdf',
    );
  }
}
