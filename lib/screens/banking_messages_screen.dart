import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import '../services/sms_service.dart';
import '../logic/transaction_parser.dart';
import 'widgets/message_detail_dialog.dart';

class BankingMessagesScreen extends StatefulWidget {
  const BankingMessagesScreen({super.key});

  @override
  State<BankingMessagesScreen> createState() => _BankingMessagesScreenState();
}

class _BankingMessagesScreenState extends State<BankingMessagesScreen> {
  final SmsService _smsService = SmsService();
  List<SmsMessage> _messages = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _smsService.getBankingMessages();
      setState(() {
        _messages = messages;
        _isLoading = false;
        _hasPermission = true; // If we got messages (or empty list), we likely had permission/success
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasPermission = false; // Assuming error means permission issue mostly
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banking Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms_failed, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'SMS Permission Needed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
              child: Text(
                'To view your banking transactions, we need access to your SMS messages. We only process banking-related messages locally on your device.',
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No banking messages found'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final transaction = TransactionParser.parse(message);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: transaction != null 
                  ? (transaction.type == TransactionType.credit ? Colors.green.shade100 : Colors.red.shade100)
                  : Colors.grey.shade200,
              child: Icon(
                transaction != null 
                    ? (transaction.type == TransactionType.credit ? Icons.arrow_downward : Icons.arrow_upward)
                    : Icons.message,
                color: transaction != null 
                    ? (transaction.type == TransactionType.credit ? Colors.green : Colors.red)
                    : Colors.grey,
              ),
            ),
            title: Text(
              message.address ?? 'Unknown Sender',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (transaction != null)
                  Text(
                    '${transaction.merchant} • ${NumberFormat.simpleCurrency(locale: 'en_IN').format(transaction.amount)}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                Text(
                  message.body ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  message.date != null 
                      ? DateFormat('MMM d, h:mm a').format(message.date!)
                      : '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => MessageDetailDialog(
                  message: message,
                  transaction: transaction,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
