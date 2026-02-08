import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/expense_model.dart';
import '../services/expense_service.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _category = 'General';
  DateTime _selectedDate = DateTime.now();
  String _type = 'expense'; // 'income' or 'expense'
  final ExpenseService _expenseService = ExpenseService();
  bool _isLoading = false;

  final List<String> _expenseCategories = [
    'General', 'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Travel', 'Rent', 'Education'
  ];
  
  final List<String> _incomeCategories = [
    'Salary', 'Freelance', 'Investment', 'Business', 'Gift', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toString();
      _merchantController.text = widget.expense!.merchant;
      _notesController.text = widget.expense!.notes;
      _category = widget.expense!.category;
      _selectedDate = widget.expense!.date;
      _type = widget.expense!.type;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double amount = double.parse(_amountController.text);
      
      final expense = Expense(
        id: widget.expense?.id ?? '', // ID handled by Service for new items
        userId: '', // Handled by Service
        amount: amount,
        category: _category,
        merchant: _merchantController.text,
        date: _selectedDate,
        notes: _notesController.text,
        isAutoLogged: widget.expense?.isAutoLogged ?? false,
        originalMessage: widget.expense?.originalMessage,
        type: _type,
      );

      if (widget.expense == null) {
        await _expenseService.addExpense(expense);
      } else {
        await _expenseService.updateExpense(expense);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'expense' ? _expenseCategories : _incomeCategories;
    if (!categories.contains(_category)) {
      _category = categories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Transaction' : 'Edit Transaction'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Toggle Income / Expense
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                        ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                      ],
                      selected: {_type},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _type = newSelection.first;
                          // Reset category if not valid for new type
                          if (_type == 'expense' && !_expenseCategories.contains(_category)) {
                            _category = _expenseCategories.first;
                          } else if (_type == 'income' && !_incomeCategories.contains(_category)) {
                            _category = _incomeCategories.first;
                          }
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return _type == 'expense' ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2);
                            }
                            return Colors.transparent;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          color: _type == 'expense' ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 24,
                        color: _type == 'expense' ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter amount';
                        if (double.tryParse(value) == null) return 'Invalid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _merchantController,
                      decoration: const InputDecoration(
                        labelText: 'Description / Merchant',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: categories.contains(_category) ? _category : categories.first,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      )).toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _saveExpense,
                        style: FilledButton.styleFrom(
                          backgroundColor: _type == 'expense' ? Colors.red : Colors.green,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
