import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import '../services/sms_service.dart';
import '../logic/transaction_parser.dart';
import 'widgets/message_detail_dialog.dart';
import '../services/scam_detection_service.dart';

class BankingMessagesScreen extends StatefulWidget {
  const BankingMessagesScreen({super.key});

  @override
  State<BankingMessagesScreen> createState() => _BankingMessagesScreenState();
}

class _BankingMessagesScreenState extends State<BankingMessagesScreen> {
  final SmsService _smsService = SmsService();
  final ScamDetectionService _scamService = ScamDetectionService();
  List<SmsMessage> _messages = [];
  Map<int, ScamResult> _scamResults = {}; // Map message hash/ID to result
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _showScamAlerts = true; // Toggle for the feature

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _scamService.initialize();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _smsService.getBankingMessages();
      
      // Run scam analysis on all messages
      // structure using message hashcode as key since ID might be null or duplicated in some contexts
      Map<int, ScamResult> results = {};
      for (var msg in messages) {
        if (msg.body != null) {
          results[msg.hashCode] = await _scamService.analyzeMessage(msg.body!);
        }
      }

      setState(() {
        _messages = messages;
        _scamResults = results;
        _isLoading = false;
        _hasPermission = true; 
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasPermission = false; 
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
            icon: Icon(_showScamAlerts ? Icons.shield : Icons.shield_outlined),
            tooltip: _showScamAlerts ? 'Disable Scam Alerts' : 'Enable Scam Alerts',
            color: _showScamAlerts ? Colors.green : null,
            onPressed: () {
              setState(() {
                _showScamAlerts = !_showScamAlerts;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_showScamAlerts ? 'Scam Detection Enabled' : 'Scam Detection Disabled')),
              );
            },
          ),
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
        final scamResult = _scamResults[message.hashCode];
        
        // Determine status color/icon if enabled
        Color? statusColor;
        IconData? statusIcon;
        
        if (_showScamAlerts && scamResult != null) {
          switch (scamResult.risk) {
            case ScamRisk.high:
              statusColor = Colors.red;
              statusIcon = Icons.warning_amber_rounded;
              break;
            case ScamRisk.suspicious:
              statusColor = Colors.orange;
              statusIcon = Icons.info_outline;
              break;
            case ScamRisk.safe:
              statusColor = Colors.green;
              statusIcon = Icons.check_circle_outline;
              break;
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: _showScamAlerts && scamResult != null && scamResult.risk != ScamRisk.safe 
              ? RoundedRectangleBorder(
                  side: BorderSide(color: statusColor!, width: 1),
                  borderRadius: BorderRadius.circular(12)
                )
              : null,
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
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    message.address ?? 'Unknown Sender',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_showScamAlerts && statusIcon != null)
                   Tooltip(
                     message: scamResult?.risk.name.toUpperCase() ?? '',
                     child: Icon(statusIcon, color: statusColor, size: 16),
                   ),
              ],
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
                  scamResult: _showScamAlerts ? scamResult : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
