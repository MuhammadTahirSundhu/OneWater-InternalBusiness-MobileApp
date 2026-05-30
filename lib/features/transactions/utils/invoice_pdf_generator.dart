import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> generateInvoicePdf(TransactionModel txn) async {
    final pdf = pw.Document();

    final logoImage = pw.MemoryImage((await rootBundle.load('assets/icon/icon.png')).buffer.asUint8List());
    final pcrwrLogo = pw.MemoryImage((await rootBundle.load('assets/images/pcwr.png')).buffer.asUint8List());
    final pfaLogo = pw.MemoryImage((await rootBundle.load('assets/images/pfa.png')).buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Image(logoImage, width: 60, height: 60),
                      pw.SizedBox(width: 16),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ONE WATER', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1565C0'))),
                          pw.Text('onewaterpakistan.com', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#616161'))),
                          pw.Text('Phone: 03203133140', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#616161'))),
                          pw.Text('Easypaisa/Jazzcash: 03203133140', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#616161'))),
                          pw.Text('Email: onewater.pk@gmail.com', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#616161'))),
                          pw.Text('Address: Green Valley, Phase 1, oppo: IISAT University, Gujranwala', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#616161'))),
                        ],
                      ),
                    ],
                  ),
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#EEEEEE'))),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Bill To & Invoice Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1565C0'))),
                      pw.SizedBox(height: 4),
                      pw.Text(txn.customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      if (txn.customerPhone != null) pw.Text(txn.customerPhone!),
                      if (txn.customerAddress != null) pw.Text(txn.customerAddress!, maxLines: 2),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #: ${txn.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${AppDateUtils.formatDateTime(txn.transactionDate)}'),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: txn.paymentStatus == 'paid' ? PdfColor.fromHex('#E8F5E9') : PdfColor.fromHex('#FFEBEE'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          'STATUS: ${txn.paymentStatus.toUpperCase()}', 
                          style: pw.TextStyle(
                            color: txn.paymentStatus == 'paid' ? PdfColor.fromHex('#388E3C') : PdfColor.fromHex('#D32F2F'),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Table
              _buildItemTable(txn),
              pw.SizedBox(height: 20),
              
              // Totals
              _buildTotals(txn),
              
              pw.Spacer(),
              
              // Footer
              pw.Divider(color: PdfColor.fromHex('#E0E0E0')),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Image(pcrwrLogo, width: 24, height: 24),
                  pw.SizedBox(width: 8),
                  pw.Text('PCRWR: One Water ML GRW-1578', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#424242'))),
                  pw.SizedBox(width: 16),
                  pw.Text('|', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#BDBDBD'))),
                  pw.SizedBox(width: 16),
                  pw.Image(pfaLogo, width: 24, height: 24),
                  pw.SizedBox(width: 8),
                  pw.Text('PFA Licence Number: GRW/M-B/ 04298753', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#424242'))),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildItemTable(TransactionModel txn) {
    return pw.TableHelper.fromTextArray(
      headers: ['Description', 'Qty', 'Unit Price', 'Total'],
      data: txn.items.map((item) => [
        item.productName,
        item.quantity.toString(),
        CurrencyFormatter.format(item.unitPrice),
        CurrencyFormatter.format(item.lineTotal),
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1565C0')),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildTotals(TransactionModel txn) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Subtotal', txn.subtotal),
          if (txn.discount > 0) _buildTotalRow('Discount', -txn.discount),
          pw.SizedBox(height: 5),
          pw.SizedBox(width: 200, child: pw.Divider()),
          pw.SizedBox(height: 5),
          _buildTotalRow('Total', txn.totalAmount, isBold: true),
          _buildTotalRow('Amount Paid', txn.amountPaid),
          pw.SizedBox(height: 5),
          pw.SizedBox(width: 200, child: pw.Divider()),
          pw.SizedBox(height: 5),
          _buildTotalRow('Balance Due', txn.totalAmount - txn.amountPaid, isBold: true),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(CurrencyFormatter.format(amount), style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static Future<void> shareInvoice(TransactionModel txn) async {
    final pdfBytes = await generateInvoicePdf(txn);
    
    // Use path_provider and share_plus for more reliable sharing across devices
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Invoice_${txn.invoiceNumber}.pdf');
    await file.writeAsBytes(pdfBytes);
    
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Invoice ${txn.invoiceNumber} from OneWater',
    );
  }

  static Future<void> viewAndPrintInvoice(TransactionModel txn) async {
    final pdfBytes = await generateInvoicePdf(txn);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${txn.invoiceNumber}',
    );
  }
}
