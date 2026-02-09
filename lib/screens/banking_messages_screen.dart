import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Banking Messages'),
        backgroundColor: AppColors.darkest,
        foregroundColor: AppColors.lightest,
        actions: [
          IconButton(
            icon: Icon(_showScamAlerts ? Icons.shield : Icons.shield_outlined),
            tooltip: _showScamAlerts ? 'Disable Scam Alerts' : 'Enable Scam Alerts',
            color: _showScamAlerts ? Colors.green : AppColors.lightest,
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
            icon: const Icon(Icons.bug_report),
            tooltip: 'Test Scam Detection',
            onPressed: _showTestScamDialog,
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

  void _showTestScamDialog() {
    final TextEditingController _testController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: const Text('Test Scam Detection', style: TextStyle(color: AppColors.lightest)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste a message to analyze:',
              style: TextStyle(color: AppColors.lightGrey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _testController,
              maxLines: 5,
              style: const TextStyle(color: AppColors.lightest),
              decoration: const InputDecoration(
                hintText: 'Enter suspicious text...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.lightGrey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightGrey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.buttonColor, foregroundColor: AppColors.darkest),
            onPressed: () async {
              Navigator.pop(context); // Close input dialog
              
              if (_testController.text.trim().isEmpty) return;
              
              // Show loading
              showDialog(
                context: context, 
                barrierDismissible: false,
                builder: (ctx) => const Center(child: CircularProgressIndicator())
              );
              
              // Analyze
              final result = await _scamService.analyzeMessage(_testController.text);
              
              Navigator.pop(context); // Close loading
              
              // Show Result using existing dialog
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => MessageDetailDialog(
                    body: _testController.text,
                    address: 'Test Sender',
                    date: DateTime.now(),
                    transaction: null, // No transaction parsing for test
                    scamResult: result,
                  ),
                );
              }
            },
            child: const Text('Analyze'),
          ),
        ],
      ),
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
            const Icon(Icons.sms_failed, size: 64, color: AppColors.lightGrey),
            const SizedBox(height: 16),
            const Text(
              'SMS Permission Needed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.lightest),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
              child: Text(
                'To view your banking transactions, we need access to your SMS messages. We only process banking-related messages locally on your device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.lightGrey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonColor, foregroundColor: AppColors.darkest),
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
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppColors.lightGrey),
            SizedBox(height: 16),
            Text('No banking messages found', style: TextStyle(color: AppColors.lightGrey)),
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
          color: AppColors.darkGrey,
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
                  ? (transaction.type == TransactionType.credit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                  : AppColors.background,
              child: Icon(
                transaction != null 
                    ? (transaction.type == TransactionType.credit ? Icons.arrow_downward : Icons.arrow_upward)
                    : Icons.message,
                color: transaction != null 
                    ? (transaction.type == TransactionType.credit ? Colors.green : Colors.red)
                    : AppColors.lightGrey,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    message.address ?? 'Unknown Sender',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightest),
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
                    style: const TextStyle(color: AppColors.lightest),
                  ),
                Text(
                  message.body ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.lightGrey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  message.date != null 
                      ? DateFormat('MMM d, h:mm a').format(message.date!)
                      : '',
                  style: TextStyle(color: AppColors.lightGrey.withOpacity(0.7), fontSize: 10),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => MessageDetailDialog(
                  body: message.body,
                  address: message.address,
                  date: message.date,
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
