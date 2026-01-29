import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../../logic/transaction_parser.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../utils/expense_model.dart';

class MessageDetailDialog extends StatelessWidget {
  final SmsMessage message;
  final TransactionDetails? transaction;

  const MessageDetailDialog({
    super.key,
    required this.message,
    this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(message.address ?? 'Unknown Sender'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            const Divider(),
            const SizedBox(height: 8),
          ],
          const Text('Original Message:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          SelectableText(message.body ?? '', style: const TextStyle(fontSize: 14)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (transaction != null)
          FilledButton.icon(
            onPressed: () async {
              try {
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
                  originalMessage: message.body,
                );

                await ExpenseService().addExpense(expense);

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
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
