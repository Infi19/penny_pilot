import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/financial_goal_model.dart';
import '../utils/currency_util.dart';
import '../services/financial_goals_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class AddEditGoalScreen extends StatefulWidget {
  final FinancialGoal? goal; // Null for creating a new goal

  const AddEditGoalScreen({super.key, this.goal});

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 365));
  String _selectedCategory = 'Savings';
  
  final List<String> _categories = [
    'Savings', 
    'Retirement', 
    'Emergency Fund', 
    'Home', 
    'Education', 
    'Travel', 
    'Car', 
    'Other'
  ];
  
  bool _isLoading = false;
  final FinancialGoalsService _goalsService = FinancialGoalsService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  String _currencyCode = CurrencyUtil.getDefaultCurrencyCode();
  String _currencySymbol = CurrencyUtil.getDefaultCurrency().symbol;

  @override
  void initState() {
    super.initState();
    _loadUserCurrency();
    
    // If editing an existing goal, populate the form
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _targetAmountController.text = widget.goal!.targetAmount.toString();
      _currentAmountController.text = widget.goal!.currentAmount.toString();
      _descriptionController.text = widget.goal!.description;
      _selectedDate = widget.goal!.targetDate;
      _selectedCategory = widget.goal!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.darkest,
              surface: AppColors.darkGrey,
              onSurface: AppColors.lightest,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final name = _nameController.text;
        final targetAmount = double.parse(_targetAmountController.text);
        final currentAmount = double.parse(_currentAmountController.text);
        final description = _descriptionController.text;

        if (widget.goal == null) {
          // Create new goal
          final newGoal = FinancialGoal(
            id: '',  // Will be assigned by Firestore
            name: name,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: _selectedDate,
            description: description,
            category: _selectedCategory,
            progressHistory: [
              GoalProgress(
                date: DateTime.now(),
                amount: currentAmount,
                note: 'Initial amount',
              ),
            ],
          );

          await _goalsService.addGoal(newGoal);
        } else {
          // Update existing goal
          final updatedGoal = FinancialGoal(
            id: widget.goal!.id,
            name: name,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: _selectedDate,
            description: description,
            category: _selectedCategory,
            progressHistory: widget.goal!.progressHistory,
          );

          await _goalsService.updateGoal(updatedGoal);
        }

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } catch (e) {
        print('Error saving goal: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving goal: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _loadUserCurrency() async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final userData = await _userService.getUserProfile(user.uid);
        if (userData != null && userData['currency'] != null) {
          final currency = CurrencyUtil.getCurrencyData(userData['currency']);
          setState(() {
            _currencyCode = currency.code;
            _currencySymbol = currency.symbol;
          });
        }
      }
    } catch (e) {
      print('Error loading user currency: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.goal == null ? 'Add New Goal' : 'Edit Goal',
          style: const TextStyle(color: AppColors.lightest),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal Name
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.lightest),
                      decoration: const InputDecoration(
                        labelText: 'Goal Name',
                        labelStyle: TextStyle(color: AppColors.lightGrey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.mediumGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name for your goal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: AppColors.lightGrey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.mediumGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      style: const TextStyle(color: AppColors.lightest),
                      dropdownColor: AppColors.darkGrey,
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Target Amount
                    TextFormField(
                      controller: _targetAmountController,
                      style: const TextStyle(color: AppColors.lightest),
                      decoration: InputDecoration(
                        labelText: 'Target Amount ($_currencySymbol)',
                        labelStyle: const TextStyle(color: AppColors.lightGrey),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.mediumGrey),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        prefixText: _currencySymbol + ' ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a target amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Current Amount
                    TextFormField(
                      controller: _currentAmountController,
                      style: const TextStyle(color: AppColors.lightest),
                      decoration: InputDecoration(
                        labelText: 'Current Amount ($_currencySymbol)',
                        labelStyle: const TextStyle(color: AppColors.lightGrey),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.mediumGrey),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        prefixText: _currencySymbol + ' ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter current amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) < 0) {
                          return 'Amount cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Target Date
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Target Date',
                          labelStyle: TextStyle(color: AppColors.lightGrey),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.mediumGrey),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                              style: const TextStyle(color: AppColors.lightest),
                            ),
                            const Icon(Icons.calendar_today, color: AppColors.lightest),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppColors.lightest),
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: TextStyle(color: AppColors.lightGrey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.mediumGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.white,
                        ),
                        child: Text(
                          widget.goal == null ? 'Create Goal' : 'Update Goal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 