import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:async/async.dart';
import '../utils/expense_model.dart';
import '../utils/app_colors.dart';
import '../services/expense_service.dart';
import 'add_edit_expense_screen.dart';
import 'analytics_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> with SingleTickerProviderStateMixin {
  final ExpenseService _expenseService = ExpenseService();
  String _searchQuery = '';
  String _filterType = 'All';
  String _filterCategory = 'All';
  DateTimeRange? _dateRange;
  late TabController _tabController;

  final List<String> _categories = [
    'All', 'General', 'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 
    'Health', 'Travel', 'Rent', 'Education', 'Salary', 'Freelance', 'Investment', 'Business', 'Gift', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Transactions'),
        backgroundColor: AppColors.darkest,
        foregroundColor: AppColors.lightest,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.lightest,
          unselectedLabelColor: AppColors.lightGrey,
          indicatorColor: AppColors.accent,
            tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.lightest,
        foregroundColor: AppColors.darkest,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Transaction List
          Column(
            children: [
              _buildSummaryCards(),
              _buildSearchAndFilters(),
              Expanded(child: _buildTransactionList()),
            ],
          ),
          // Tab 2: Analytics
          const AnalyticsView(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<List<double>>(
      stream: _combineStreams(),
      builder: (context, snapshot) {
        double income = 0;
        double expense = 0;
        if (snapshot.hasData) {
          income = snapshot.data![0];
          expense = snapshot.data![1];
        }
        double balance = income - expense;

        return Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.darkGrey,
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Balance', balance, balance >= 0 ? Colors.green : Colors.red, isTotal: true),
              ),
              const SizedBox(width: 10),
              _buildSummaryItem('Income', income, Colors.green),
              const SizedBox(width: 10),
              _buildSummaryItem('Expense', expense, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Stream<List<double>> _combineStreams() {
    return StreamZip([
      _expenseService.getTotalIncome(),
      _expenseService.getTotalExpenses(),
    ]);
  }

  Widget _buildSummaryItem(String label, double amount, Color color, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: isTotal ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.lightGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            NumberFormat.compactSimpleCurrency(locale: 'en_IN').format(amount),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.darkGrey,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: AppColors.lightest),
            decoration: InputDecoration(
              hintText: 'Search merchant or notes...',
              hintStyle: const TextStyle(color: AppColors.lightGrey),
              prefixIcon: const Icon(Icons.search, color: AppColors.lightGrey),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: _dateRange == null 
                      ? 'Date Range' 
                      : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                  isSelected: _dateRange != null,
                  onTap: _pickDateRange,
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppColors.darkGrey,
                    value: _filterType,
                    icon: const Icon(Icons.filter_list, color: AppColors.lightest, size: 16),
                    style: const TextStyle(color: AppColors.lightest, fontSize: 12),
                    items: ['All', 'Income', 'Expense'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _filterType = val!),
                  ),
                ),
                const SizedBox(width: 8),
                 DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppColors.darkGrey,
                    value: _categories.contains(_filterCategory) ? _filterCategory : 'All',
                    icon: const Icon(Icons.category, color: AppColors.lightest, size: 16),
                    style: const TextStyle(color: AppColors.lightest, fontSize: 12),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _filterCategory = val!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightest : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.darkest : AppColors.lightest,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Widget _buildTransactionList() {
    return StreamBuilder<List<Expense>>(
      stream: _expenseService.getExpensesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        var expenses = snapshot.data ?? [];

        expenses = expenses.where((e) {
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            if (!e.merchant.toLowerCase().contains(query) && !e.notes.toLowerCase().contains(query)) {
              return false;
            }
          }
          if (_filterType != 'All') {
            if (_filterType.toLowerCase() != e.type) return false;
          }
          if (_filterCategory != 'All') {
            if (e.category != _filterCategory) return false;
          }
          if (_dateRange != null) {
            if (e.date.isBefore(_dateRange!.start) || e.date.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
              return false;
            }
          }
          return true;
        }).toList();

        if (expenses.isEmpty) {
          return const Center(child: Text('No transactions found', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return Dismissible(
              key: Key(expense.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                 return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
              },
              onDismissed: (_) => _expenseService.deleteExpense(expense.id),
              child: Card(
                color: AppColors.background,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: expense.type == 'income' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    child: Icon(
                      _getCategoryIcon(expense.category),
                      color: expense.type == 'income' ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(expense.merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${expense.category} • ${DateFormat.MMMd().format(expense.date)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '${expense.type == 'income' ? '+ ' : '- '}${NumberFormat.simpleCurrency(locale: 'en_IN').format(expense.amount)}',
                    style: TextStyle(
                      color: expense.type == 'income' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddEditExpenseScreen(expense: expense)),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_bus;
      case 'Shopping': return Icons.shopping_bag;
      case 'Bills': return Icons.receipt;
      case 'Entertainment': return Icons.movie;
      case 'Health': return Icons.medical_services;
      case 'Travel': return Icons.flight;
      case 'Rent': return Icons.home;
      case 'Education': return Icons.school;
      case 'Salary': return Icons.attach_money;
      case 'Freelance': return Icons.work;
      case 'Investment': return Icons.trending_up;
      case 'Business': return Icons.business;
      case 'Gift': return Icons.card_giftcard;
      default: return Icons.category;
    }
  }
}
