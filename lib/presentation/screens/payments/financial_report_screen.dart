import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/glass_card.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentProvider>(context, listen: false).fetchFinancialReports();
    });
  }

  // High-End Custom PDF Exporter Tool
  Future<void> _exportToPDF() async {
    final payProvider = Provider.of<PaymentProvider>(context, listen: false);
    final payments = payProvider.payments;
    final summary = payProvider.financialSummary;

    final doc = pw.Document();

    // Setup custom theme colors for PDF branding matching our gym logo
    final primaryColor = PdfColor.fromHex('#10B981'); // Neon Emerald
    final darkBgColor = PdfColor.fromHex('#1E293B');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Branded Corporate Banner
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: pw.BoxDecoration(
                color: darkBgColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MUSCLES UP GYM',
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Financial Audit & Collections Ledger',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: ${DateFormat('dd MMM, yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 11),
                      ),
                      pw.Text(
                        'System: Automated Node-REST',
                        style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10),
                      ),
                    ],
                  )
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Financial Summary Block (3 Columns)
            pw.Row(
              children: [
                _buildPdfSummaryBox('Today\'s Collections', 'INR ${summary['today']}', primaryColor),
                pw.SizedBox(width: 12),
                _buildPdfSummaryBox('This Month', 'INR ${summary['monthly']}', PdfColor.fromHex('#3B82F6')),
                pw.SizedBox(width: 12),
                _buildPdfSummaryBox('Annual Aggregate', 'INR ${summary['yearly']}', PdfColor.fromHex('#F59E0B')),
              ],
            ),
            pw.SizedBox(height: 28),

            pw.Text(
              'DETAILED TRANSACTION LEDGER',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#64748B'),
              ),
            ),
            pw.SizedBox(height: 8),

            // Ledger Tables
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Member Name
                1: const pw.FlexColumnWidth(2), // Date
                2: const pw.FlexColumnWidth(3), // Details
                3: const pw.FlexColumnWidth(2), // Amount
              },
              children: [
                // Header Roster Item
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildPdfHeaderCell('Member Name'),
                    _buildPdfHeaderCell('Payment Date'),
                    _buildPdfHeaderCell('Notes'),
                    _buildPdfHeaderCell('Amount', isRightAligned: true),
                  ],
                ),
                // Dynamic Data rows
                ...payments.map((p) {
                  return pw.TableRow(
                    children: [
                      _buildPdfDataCell(p.member?.name ?? 'N/A'),
                      _buildPdfDataCell(DateFormat('dd MMM, yyyy').format(DateTime.parse(p.paymentDate))),
                      _buildPdfDataCell(p.notes ?? 'General Membership'),
                      _buildPdfDataCell('Rs ${p.amount}', isRightAligned: true, isBold: true),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    // Launch print/share sheet instantly on platform!
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Iron_Matrix_Gym_Ledger_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // PDF components helpers
  pw.Widget _buildPdfSummaryBox(String label, String value, PdfColor accentColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(color: accentColor, fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPdfHeaderCell(String text, {bool isRightAligned = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        textAlign: isRightAligned ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildPdfDataCell(String text, {bool isRightAligned = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isRightAligned ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payProvider = Provider.of<PaymentProvider>(context);
    final payments = payProvider.payments;
    final summary = payProvider.financialSummary;
    final isLoading = payProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.neonGreen),
            onPressed: payments.isEmpty ? null : _exportToPDF,
            tooltip: 'Export Ledger (PDF)',
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
          : RefreshIndicator(
              onRefresh: () => payProvider.fetchFinancialReports(),
              color: AppColors.neonGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Financial summary cards (Grid of 3 items row-styled)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CASH FLOW STATS',
                            style: TextStyle(
                              color: AppColors.neonGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildSummarySegment('TODAY', _currencyFormat.format(summary['today'] ?? 0.0), AppColors.neonGreen),
                              _buildDivider(),
                              _buildSummarySegment('MONTHLY', _currencyFormat.format(summary['monthly'] ?? 0.0), AppColors.neonBlue),
                              _buildDivider(),
                              _buildSummarySegment('ANNUAL', _currencyFormat.format(summary['yearly'] ?? 0.0), AppColors.neonAmber),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'TRANSACTIONS FEED',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ledger listing
                    payments.isEmpty
                        ? const GlassCard(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'No payment records logged in this system.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: payments.length,
                            itemBuilder: (context, idx) {
                              final pay = payments[idx];
                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.neonGreen.withOpacity(0.12),
                                      child: const Icon(Icons.arrow_downward, color: AppColors.neonGreen),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pay.member?.name ?? 'Deleted Member',
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            pay.notes ?? 'Monthly package registration',
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _currencyFormat.format(pay.amount),
                                          style: const TextStyle(
                                            color: AppColors.neonGreen,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMM').format(DateTime.parse(pay.paymentDate)),
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummarySegment(String label, String val, Color highlightColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            val,
            style: TextStyle(color: highlightColor, fontSize: 15, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 35, color: AppColors.border);
  }
}
