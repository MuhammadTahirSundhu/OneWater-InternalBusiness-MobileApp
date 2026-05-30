import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> generateInvoicePdf(TransactionModel txn) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ONE WATER', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1565C0'))),
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#616161'))),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(txn.customerName),
                      if (txn.customerPhone != null) pw.Text(txn.customerPhone!),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #: ${txn.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${AppDateUtils.formatDateTime(txn.transactionDate)}'),
                      pw.Text('Status: ${txn.paymentStatus.toUpperCase()}', style: pw.TextStyle(
                        color: txn.paymentStatus == 'paid' ? PdfColor.fromHex('#388E3C') : PdfColor.fromHex('#D32F2F'),
                        fontWeight: pw.FontWeight.bold,
                      )),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              _buildItemTable(txn),
              pw.SizedBox(height: 20),
              _buildTotals(txn),
              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text('Thank you for choosing OneWater!', style: pw.TextStyle(color: PdfColor.fromHex('#616161'))),
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
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${txn.invoiceNumber}.pdf',
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
