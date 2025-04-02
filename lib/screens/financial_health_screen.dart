import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/financial_health_model.dart';
import '../utils/currency_util.dart';
import '../services/financial_health_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'financial_health_result_screen.dart';

class FinancialHealthScreen extends StatefulWidget {
  const FinancialHealthScreen({super.key});

  @override
  State<FinancialHealthScreen> createState() => _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends State<FinancialHealthScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for text fields
  final _monthlyIncomeController = TextEditingController();
  final _monthlyExpensesController = TextEditingController();
  final _monthlySavingsController = TextEditingController();
  final _totalDebtController = TextEditingController();
  final _emergencyFundController = TextEditingController();
  
  // Controllers for investment fields
  final Map<String, TextEditingController> _investmentControllers = {};
  
  // Investment allocation
  final Map<String, double> _investments = {
    'Stocks': 0,
    'Bonds': 0,
    'Real Estate': 0,
    'Cash': 0,
    'Other': 0,
  };
  
  final FinancialHealthService _healthService = FinancialHealthService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String _currencyCode = CurrencyUtil.getDefaultCurrencyCode();
  String _currencySymbol = CurrencyUtil.getDefaultCurrency().symbol;

  @override
  void initState() {
    super.initState();
    _loadUserCurrency();
    
    // Initialize investment controllers
    for (String category in _investments.keys) {
      _investmentControllers[category] = TextEditingController(
        text: _formatNumberWithCommas(_investments[category]!.toStringAsFixed(0))
      );
    }
  }

  Future<void> _loadUserCurrency() async {
    setState(() {
      _isLoading = true;
    });

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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    _monthlyExpensesController.dispose();
    _monthlySavingsController.dispose();
    _totalDebtController.dispose();
    _emergencyFundController.dispose();
    
    // Dispose investment controllers
    for (var controller in _investmentControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  // Format numbers with commas for thousands
  String _formatNumberWithCommas(String value) {
    if (value.isEmpty) return '';
    
    // Remove any non-digit characters
    value = value.replaceAll(RegExp(r'[^\d.]'), '');
    
    if (value.isEmpty) return '';
    
    final formatter = NumberFormat('#,##0.##', 'en_US');
    try {
      final number = double.parse(value);
      return formatter.format(number);
    } catch (e) {
      return value;
    }
  }

  // Parse comma-formatted number to double
  double _parseFormattedNumber(String value) {
    if (value.isEmpty) return 0;
    return double.parse(value.replaceAll(',', ''));
  }

  Future<void> _calculateHealthScore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final monthlyIncome = _parseFormattedNumber(_monthlyIncomeController.text);
      final monthlyExpenses = _parseFormattedNumber(_monthlyExpensesController.text);
      final monthlySavings = _parseFormattedNumber(_monthlySavingsController.text);
      final totalDebt = _parseFormattedNumber(_totalDebtController.text);
      final emergencyFund = _parseFormattedNumber(_emergencyFundController.text);

      final scoreId = await _healthService.saveHealthScore(
        monthlyIncome: monthlyIncome,
        monthlyExpenses: monthlyExpenses,
        monthlySavings: monthlySavings,
        totalDebt: totalDebt,
        investments: _investments,
        emergencyFund: emergencyFund,
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FinancialHealthResultScreen(scoreId: scoreId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating health score: $e')),
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

  // Update investment controller with current value
  void _updateInvestmentController(String category) {
    final controller = _investmentControllers[category]!;
    final formattedValue = _formatNumberWithCommas(_investments[category]!.toStringAsFixed(0));
    
    // Only update if the values are different (to avoid cursor jumping)
    if (controller.text != formattedValue) {
      controller.text = formattedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Financial Health Calculator',
          style: TextStyle(color: AppColors.primaryText),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.tertiary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calculate Your Financial Health Score',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Enter your financial information to get a comprehensive assessment of your financial well-being.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.quaternary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Monthly Income
                    _buildCurrencyField(
                      label: 'Monthly Income',
                      controller: _monthlyIncomeController,
                      hintText: '0',
                      icon: Icons.payments,
                    ),
                    const SizedBox(height: 16),
                    
                    // Monthly Expenses
                    _buildCurrencyField(
                      label: 'Monthly Expenses',
                      controller: _monthlyExpensesController,
                      hintText: '0',
                      icon: Icons.shopping_cart,
                    ),
                    const SizedBox(height: 16),
                    
                    // Monthly Savings
                    _buildCurrencyField(
                      label: 'Monthly Savings',
                      controller: _monthlySavingsController,
                      hintText: '0',
                      icon: Icons.savings,
                    ),
                    const SizedBox(height: 16),
                    
                    // Total Debt
                    _buildCurrencyField(
                      label: 'Total Debt',
                      controller: _totalDebtController,
                      hintText: '0',
                      icon: Icons.account_balance,
                    ),
                    const SizedBox(height: 16),
                    
                    // Emergency Fund
                    _buildCurrencyField(
                      label: 'Emergency Fund',
                      controller: _emergencyFundController,
                      hintText: '0',
                      icon: Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 24),
                    
                    // Investment Allocation
                    const Text(
                      'Investment Allocation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._investments.keys.map((category) => _buildInvestmentSlider(category)),
                    const SizedBox(height: 32),
                    
                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _calculateHealthScore,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: AppColors.primaryText,
                          backgroundColor: AppColors.tertiary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Calculate Health Score',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrencyField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.tertiary),
            prefixText: _currencySymbol + ' ',
            prefixStyle: const TextStyle(color: AppColors.primaryText),
            hintText: hintText,
            hintStyle: TextStyle(color: AppColors.primaryText.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.secondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.tertiary, width: 1.5),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a value';
            }
            return null;
          },
          onChanged: (value) {
            final cursorPosition = controller.selection.base.offset;
            
            // Count commas before the cursor
            final beforeCursor = controller.text.substring(0, cursorPosition);
            final commasBefore = beforeCursor.replaceAll(RegExp(r'[^,]'), '').length;
            
            // Format the number
            final formattedValue = _formatNumberWithCommas(value);
            
            // Count commas in the formatted text before the cursor
            final formattedBeforeCursor = _formatNumberWithCommas(beforeCursor);
            final newCommasBefore = formattedBeforeCursor.replaceAll(RegExp(r'[^,]'), '').length;
            
            // Calculate the new cursor position
            final newPosition = cursorPosition + (newCommasBefore - commasBefore);
            
            controller.text = formattedValue;
            
            // Set the cursor position
            if (newPosition >= 0 && newPosition <= formattedValue.length) {
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: newPosition),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildInvestmentSlider(String category) {
    // Use the controller from the map
    final controller = _investmentControllers[category]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.pie_chart, color: AppColors.tertiary),
            prefixText: _currencySymbol + ' ',
            prefixStyle: const TextStyle(color: AppColors.primaryText),
            hintText: '0',
            hintStyle: TextStyle(color: AppColors.primaryText.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.secondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.tertiary, width: 1.5),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          onChanged: (value) {
            final cursorPosition = controller.selection.base.offset;
            
            // Count commas before the cursor
            final beforeCursor = controller.text.substring(0, cursorPosition);
            final commasBefore = beforeCursor.replaceAll(RegExp(r'[^,]'), '').length;
            
            // Format the number
            final formattedValue = _formatNumberWithCommas(value);
            
            // Count commas in the formatted text before the cursor
            final formattedBeforeCursor = _formatNumberWithCommas(beforeCursor);
            final newCommasBefore = formattedBeforeCursor.replaceAll(RegExp(r'[^,]'), '').length;
            
            // Calculate the new cursor position
            final newPosition = cursorPosition + (newCommasBefore - commasBefore);
            
            controller.text = formattedValue;
            
            // Update the investment value
            setState(() {
              _investments[category] = _parseFormattedNumber(formattedValue);
            });
            
            // Set the cursor position
            if (newPosition >= 0 && newPosition <= formattedValue.length) {
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: newPosition),
              );
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
} 