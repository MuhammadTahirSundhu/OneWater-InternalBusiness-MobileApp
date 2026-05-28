import io
import logging
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT
from dependencies import get_supabase
from config import get_settings

logger = logging.getLogger(__name__)


async def generate_invoice_pdf(transaction_id: str) -> str | None:
    """Generate a PDF invoice and upload to Supabase Storage. Returns signed URL."""
    try:
        db = get_supabase()
        settings = get_settings()

        # Fetch transaction
        txn_result = db.table("transactions").select("*").eq("id", transaction_id).execute()
        if not txn_result.data:
            return None
        txn = txn_result.data[0]

        # Fetch items
        items_result = db.table("transaction_items").select("*").eq("transaction_id", transaction_id).execute()
        items = items_result.data

        # Fetch customer
        cust_result = db.table("customers").select("*").eq("id", txn["customer_id"]).execute()
        customer = cust_result.data[0] if cust_result.data else {}

        # Build PDF
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, topMargin=15*mm, bottomMargin=15*mm,
                                leftMargin=15*mm, rightMargin=15*mm)

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle('Title', parent=styles['Heading1'], fontSize=20,
                                      textColor=colors.HexColor('#0EA5E9'), alignment=TA_CENTER)
        header_style = ParagraphStyle('Header', parent=styles['Normal'], fontSize=10,
                                       textColor=colors.HexColor('#64748B'), alignment=TA_CENTER)
        label_style = ParagraphStyle('Label', parent=styles['Normal'], fontSize=9,
                                      textColor=colors.HexColor('#64748B'))
        value_style = ParagraphStyle('Value', parent=styles['Normal'], fontSize=10,
                                      textColor=colors.HexColor('#0F172A'), fontName='Helvetica-Bold')
        footer_style = ParagraphStyle('Footer', parent=styles['Normal'], fontSize=8,
                                       textColor=colors.HexColor('#94A3B8'), alignment=TA_CENTER)

        elements = []

        # Header
        elements.append(Paragraph(settings.business_name, title_style))
        elements.append(Paragraph("INVOICE", ParagraphStyle('Inv', parent=styles['Heading2'],
                                                              alignment=TA_CENTER, textColor=colors.HexColor('#0369A1'))))
        if settings.business_address:
            elements.append(Paragraph(settings.business_address, header_style))
        if settings.business_phone:
            elements.append(Paragraph(f"Phone: {settings.business_phone}", header_style))
        elements.append(Spacer(1, 8*mm))

        # Invoice info
        info_data = [
            [Paragraph('Invoice #:', label_style), Paragraph(txn['invoice_number'], value_style),
             Paragraph('Date:', label_style), Paragraph(str(txn['transaction_date']), value_style)],
        ]
        if txn.get('due_date'):
            info_data.append([
                Paragraph('Status:', label_style), Paragraph(txn['payment_status'].upper(), value_style),
                Paragraph('Due Date:', label_style), Paragraph(str(txn['due_date']), value_style),
            ])

        info_table = Table(info_data, colWidths=[60, 120, 60, 120])
        info_table.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ]))
        elements.append(info_table)
        elements.append(Spacer(1, 5*mm))

        # Bill To
        elements.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#E2E8F0')))
        elements.append(Spacer(1, 3*mm))
        elements.append(Paragraph('BILL TO:', ParagraphStyle('BillTo', parent=label_style, fontSize=9,
                                                               textColor=colors.HexColor('#64748B'))))
        elements.append(Paragraph(txn['customer_name'], value_style))
        if txn.get('customer_phone'):
            elements.append(Paragraph(txn['customer_phone'], label_style))
        if customer.get('address'):
            elements.append(Paragraph(customer['address'], label_style))
        elements.append(Spacer(1, 5*mm))

        # Items table
        table_data = [['Product', 'Qty', 'Unit Price', 'Total']]
        for item in items:
            table_data.append([
                item['product_name'],
                str(item['quantity']),
                f"PKR {float(item['unit_price']):,.0f}",
                f"PKR {float(item['line_total']):,.0f}",
            ])

        items_table = Table(table_data, colWidths=[200, 50, 90, 90])
        items_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#0EA5E9')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
            ('TOPPADDING', (0, 0), (-1, 0), 8),
            ('BOTTOMPADDING', (0, 1), (-1, -1), 6),
            ('TOPPADDING', (0, 1), (-1, -1), 6),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#E2E8F0')),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F8FAFC')]),
        ]))
        elements.append(items_table)
        elements.append(Spacer(1, 3*mm))

        # Totals
        totals_data = [
            ['', '', 'Subtotal:', f"PKR {float(txn['subtotal']):,.0f}"],
            ['', '', 'Discount:', f"PKR {float(txn['discount']):,.0f}"],
            ['', '', 'TOTAL:', f"PKR {float(txn['total_amount']):,.0f}"],
            ['', '', 'Paid:', f"PKR {float(txn['amount_paid']):,.0f}"],
            ['', '', 'Balance:', f"PKR {float(txn['total_amount']) - float(txn['amount_paid']):,.0f}"],
        ]
        totals_table = Table(totals_data, colWidths=[200, 50, 90, 90])
        totals_table.setStyle(TableStyle([
            ('ALIGN', (2, 0), (-1, -1), 'RIGHT'),
            ('FONTNAME', (2, 2), (-1, 2), 'Helvetica-Bold'),
            ('FONTSIZE', (2, 2), (-1, 2), 11),
            ('LINEABOVE', (2, 2), (-1, 2), 1, colors.HexColor('#0EA5E9')),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))
        elements.append(totals_table)
        elements.append(Spacer(1, 5*mm))

        # Payment info
        payment_info = f"Payment Status: {txn['payment_status'].upper()}"
        if txn.get('payment_method'):
            payment_info += f"  |  Method: {txn['payment_method'].replace('_', ' ').title()}"
        elements.append(Paragraph(payment_info, ParagraphStyle('PayInfo', parent=label_style, fontSize=9)))

        if txn.get('notes'):
            elements.append(Spacer(1, 2*mm))
            elements.append(Paragraph(f"Notes: {txn['notes']}", label_style))

        # Footer
        elements.append(Spacer(1, 10*mm))
        elements.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#E2E8F0')))
        elements.append(Spacer(1, 3*mm))
        elements.append(Paragraph("Thank you for choosing OneWater Pakistan!", footer_style))
        elements.append(Paragraph("PSQCA-Certified Premium Himalayan Mineral Water", footer_style))

        doc.build(elements)

        # Upload to Supabase Storage
        pdf_bytes = buffer.getvalue()
        file_path = f"invoices/{transaction_id}.pdf"

        try:
            db.storage.from_("invoices").upload(
                file_path,
                pdf_bytes,
                file_options={"content-type": "application/pdf", "upsert": "true"},
            )
        except Exception:
            # File might already exist, try update
            db.storage.from_("invoices").update(
                file_path,
                pdf_bytes,
                file_options={"content-type": "application/pdf"},
            )

        # Get signed URL (valid for 1 year)
        signed_url = db.storage.from_("invoices").create_signed_url(file_path, 31536000)
        return signed_url.get("signedURL") if isinstance(signed_url, dict) else str(signed_url)

    except Exception as e:
        logger.error(f"Invoice generation failed: {e}", exc_info=True)
        return None
