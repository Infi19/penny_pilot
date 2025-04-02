import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/financial_health_model.dart';
import '../utils/currency_util.dart';
import '../services/financial_health_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class FinancialHealthResultScreen extends StatefulWidget {
  final String scoreId;

  const FinancialHealthResultScreen({
    super.key,
    required this.scoreId,
  });

  @override
  State<FinancialHealthResultScreen> createState() => _FinancialHealthResultScreenState();
}

class _FinancialHealthResultScreenState extends State<FinancialHealthResultScreen> {
  final FinancialHealthService _healthService = FinancialHealthService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  FinancialHealthScore? _healthScore;
  bool _isLoading = true;
  String _currencyCode = CurrencyUtil.getDefaultCurrencyCode();
  String _currencySymbol = CurrencyUtil.getDefaultCurrency().symbol;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user currency preference
      final user = _authService.getCurrentUser();
      if (user != null) {
        final userData = await _userService.getUserProfile(user.uid);
        if (userData != null && userData['currency'] != null) {
          final currency = CurrencyUtil.getCurrencyData(userData['currency']);
          _currencyCode = currency.code;
          _currencySymbol = currency.symbol;
        }
      }

      // Load health score
      final scores = await _healthService.getAllHealthScores();
      for (final score in scores) {
        if (score.id == widget.scoreId) {
          setState(() {
            _healthScore = score;
          });
          break;
        }
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getScoreColor(String category) {
    switch (category) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.yellow;
      case 'Moderate Risk':
        return Colors.orange;
      case 'High Risk':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(double value) {
    return NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 0).format(value);
  }

  String _formatPercent(double value) {
    return NumberFormat.percentPattern().format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Financial Health Results',
          style: TextStyle(color: AppColors.primaryText),
        ),
        backgroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.lightest),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.tertiary))
          : _healthScore == null
              ? const Center(child: Text('Score not found', style: TextStyle(color: AppColors.primaryText)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        child: _buildScoreOverview(),
                      ),
                      const SizedBox(height: 24),
                      _buildScoreBreakdown(),
                      const SizedBox(height: 24),
                      _buildRecommendations(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildScoreOverview() {
    return Card(
      elevation: 4,
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your Financial Health Score',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: CircularProgressIndicator(
                      value: _healthScore!.totalScore / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(_healthScore!.healthCategory),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _healthScore!.totalScore.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Text(
                        'out of 100',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.quaternary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: _getScoreColor(_healthScore!.healthCategory).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _healthScore!.healthCategory,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(_healthScore!.healthCategory),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Assessment Date: ${DateFormat.yMMMd().format(_healthScore!.assessmentDate)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.quaternary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    return Card(
      elevation: 4,
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Score Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            
            // Income vs Expenses
            _buildMetricTile(
              title: 'Income vs Expenses Ratio',
              value: _healthScore!.incomeExpensesRatio,
              maxScore: 25,
              scoreValue: FinancialHealthScore.calculateIncomeExpensesScore(
                _healthScore!.incomeExpensesRatio,
              ),
              icon: Icons.account_balance_wallet,
              color: AppColors.tertiary,
              formatter: (value) => value.toStringAsFixed(2) + 'x',
            ),
            
            // Savings Rate
            _buildMetricTile(
              title: 'Savings Rate',
              value: _healthScore!.savingsRate,
              maxScore: 20,
              scoreValue: FinancialHealthScore.calculateSavingsRateScore(
                _healthScore!.savingsRate,
              ),
              icon: Icons.savings,
              color: Colors.green,
              formatter: _formatPercent,
            ),
            
            // Debt-to-Income
            _buildMetricTile(
              title: 'Debt-to-Income Ratio',
              value: _healthScore!.debtToIncomeRatio,
              maxScore: 20,
              scoreValue: FinancialHealthScore.calculateDebtToIncomeScore(
                _healthScore!.debtToIncomeRatio,
              ),
              icon: Icons.credit_card,
              color: Colors.red,
              formatter: _formatPercent,
            ),
            
            // Investment Diversification
            _buildMetricTile(
              title: 'Investment Diversification',
              value: _healthScore!.investmentDiversification,
              maxScore: 15,
              scoreValue: FinancialHealthScore.calculateInvestmentDiversificationScore(
                _healthScore!.investmentDiversification,
              ),
              icon: Icons.pie_chart,
              color: Colors.purple,
              formatter: _formatPercent,
            ),
            
            // Emergency Fund
            _buildMetricTile(
              title: 'Emergency Fund',
              value: _healthScore!.emergencyFundRatio,
              maxScore: 20,
              scoreValue: FinancialHealthScore.calculateEmergencyFundScore(
                _healthScore!.emergencyFundRatio,
              ),
              icon: Icons.health_and_safety,
              color: Colors.orange,
              formatter: (value) => value.toStringAsFixed(1) + ' months',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required double value,
    required double maxScore,
    required double scoreValue,
    required IconData icon,
    required Color color,
    required String Function(double) formatter,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatter(value),
                          style: TextStyle(
                            color: AppColors.quaternary,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${scoreValue.toStringAsFixed(0)}/${maxScore.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: scoreValue / maxScore,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      elevation: 4,
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            ...List.generate(_healthScore!.recommendations.length, (index) {
              final recommendation = _healthScore!.recommendations[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _healthScore!.recommendations.length - 1 ? 14 : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.arrow_right,
                        color: AppColors.tertiary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
} 