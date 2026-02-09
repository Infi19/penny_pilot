import 'package:flutter/material.dart';
import '../../logic/transaction_parser.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../services/expense_service.dart';
import '../../utils/expense_model.dart';
import '../../services/scam_detection_service.dart';
import '../../services/gemini_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessageDetailDialog extends StatelessWidget {
  final String? body;
  final String? address;
  final DateTime? date;
  final TransactionDetails? transaction;
  final ScamResult? scamResult;

  const MessageDetailDialog({
    super.key,
    required this.body,
    required this.address,
    required this.date,
    this.transaction,
    this.scamResult,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(address ?? 'Unknown Sender', style: const TextStyle(color: AppColors.lightest)),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scamResult != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _getRiskColor(scamResult!.risk).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getRiskColor(scamResult!.risk)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getRiskIcon(scamResult!.risk), color: _getRiskColor(scamResult!.risk)),
                      const SizedBox(width: 8),
                      Text(
                        'Risk Level: ${scamResult!.risk.name.toUpperCase()}',
                         style: TextStyle(
                           fontWeight: FontWeight.bold, 
                           color: _getRiskColor(scamResult!.risk)
                         ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Confidence: ${(scamResult!.confidence * 100).toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.lightest)),
                  const SizedBox(height: 4),
                  Text('Reason: ${scamResult!.reason}', style: const TextStyle(color: AppColors.lightest)),
                  const SizedBox(height: 8),
                  if (scamResult!.risk != ScamRisk.safe) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Analysis',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightest),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<String>(
                      future: GeminiService().explainScamMessage(scamResult!, body ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          );
                        }
                        if (snapshot.hasError) {
                          return Text('Could not load explanation.', style: TextStyle(color: Colors.red[300], fontSize: 12));
                        }
                        return MarkdownBody(
                          data: snapshot.data ?? 'No explanation available.',
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 13, color: AppColors.lightest),
                            h1: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.lightest),
                            h2: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.lightest),
                            h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.lightest),
                            listBullet: const TextStyle(color: AppColors.lightest),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'Disclaimer: This assessment is AI-based and may not always be accurate.',
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
          if (transaction != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: transaction!.type == TransactionType.credit 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: transaction!.type == TransactionType.credit 
                      ? Colors.green.withOpacity(0.3) 
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Amount', NumberFormat.simpleCurrency(locale: 'en_IN').format(transaction!.amount), isBold: true),
                  _buildDetailRow('Merchant', transaction!.merchant),
                  _buildDetailRow('Type', transaction!.type.name.toUpperCase()),
                  _buildDetailRow('Date', DateFormat('MMM d, y h:mm a').format(transaction!.date)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.lightGrey),
            const SizedBox(height: 8),
          ],
          const Text('Original Message:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.lightGrey)),
          const SizedBox(height: 4),
          SelectableText(body ?? '', style: const TextStyle(fontSize: 14, color: AppColors.lightest)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: AppColors.lightGrey)),
        ),
        if (transaction != null)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.buttonColor, foregroundColor: AppColors.darkest),
            onPressed: () async {
              try {
                final expenseService = ExpenseService();
                // Check duplicate
                final isDuplicate = await expenseService.isDuplicateExpense(
                  transaction!.amount, 
                  transaction!.merchant, 
                  transaction!.date
                );

                if (context.mounted && isDuplicate) {
                   final shouldProceed = await showDialog<bool>(
                     context: context,
                     builder: (context) => AlertDialog(
                       backgroundColor: AppColors.darkGrey,
                       title: const Text('Possible Duplicate', style: TextStyle(color: AppColors.lightest)),
                       content: const Text('A transaction with this amount and merchant already exists for this date. Save anyway?', style: TextStyle(color: AppColors.lightest)),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.lightGrey))),
                         FilledButton(
                           style: FilledButton.styleFrom(backgroundColor: AppColors.buttonColor, foregroundColor: AppColors.darkest),
                           onPressed: () => Navigator.pop(context, true), 
                           child: const Text('Save')
                          ),
                       ],
                     ),
                   );
                   if (shouldProceed != true) return;
                }

                // Determine type based on transaction (Credit -> Income, Debit -> Expense)
                final String type = transaction!.type == TransactionType.credit ? 'income' : 'expense';

                // Initial category guess based on merchant names could go here
                // For now, default to 'General' or let user edit later
                final expense = Expense(
                  id: '', // Service generates ID
                  userId: '', // Service handles user
                  amount: transaction!.amount,
                  category: 'General',
                  merchant: transaction!.merchant,
                  date: transaction!.date,
                  notes: 'Auto-logged from SMS',
                  isAutoLogged: true,
                  originalMessage: body,
                  type: type,
                );

                await expenseService.addExpense(expense);

                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                       content: Text('Saved ₹${transaction!.amount} at ${transaction!.merchant}'),
                     ),
                   );
                   Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Expense'),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, color: AppColors.lightGrey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: AppColors.lightest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(ScamRisk risk) {
    switch (risk) {
      case ScamRisk.high: return Colors.red;
      case ScamRisk.suspicious: return Colors.orange;
      case ScamRisk.safe: return Colors.green;
    }
  }

  IconData _getRiskIcon(ScamRisk risk) {
    switch (risk) {
      case ScamRisk.high: return Icons.warning;
      case ScamRisk.suspicious: return Icons.info;
      case ScamRisk.safe: return Icons.check_circle;
    }
  }
}
