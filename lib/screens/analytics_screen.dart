import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../services/analytics_service.dart';
import '../services/gemini_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCategoryPieChart(),
          const SizedBox(height: 24),
          _buildWeeklyTrendChart(),
          const SizedBox(height: 24),
          _buildGenerateSummaryButton(context),
        ],
      ),
    );
  }

  Widget _buildGenerateSummaryButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.summarize, color: Colors.white),
        label: const Text("Generate Monthly Summary", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        onPressed: () => _generateAndShowSummary(context),
      ),
    );
  }

  Future<void> _generateAndShowSummary(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final analyticsService = AnalyticsService();
      final geminiService = GeminiService();

      // 1. Get Data
      final data = await analyticsService.getMonthlySummaryData(DateTime.now());
      
      // 2. Generate Summary
      final summary = await geminiService.generateMonthlyFinancialSummary(data);

      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Show Result
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.darkGrey,
            title: const Text("Monthly Financial Summary", style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: MarkdownBody(
                data: summary,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppColors.lightest),
                  h1: const TextStyle(color: AppColors.lightest, fontWeight: FontWeight.bold),
                  h2: const TextStyle(color: AppColors.lightest, fontWeight: FontWeight.bold),
                  h3: const TextStyle(color: AppColors.lightest, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(color: AppColors.lightest),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Widget _buildCategoryPieChart() {
    final AnalyticsService analyticsService = AnalyticsService();
    
    return StreamBuilder<Map<String, double>>(
      stream: analyticsService.getCategoryBreakdown(DateTime.now()), // Current Month
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            color: AppColors.darkGrey,
            child: Padding(padding: EdgeInsets.all(20), child: Text('No data for this month', style: TextStyle(color: Colors.white))),
          );
        }

        final data = snapshot.data!;
        final total = data.values.fold(0.0, (sum, val) => sum + val);

        return Card(
          color: AppColors.darkGrey,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expense Breakdown (This Month)', style: TextStyle(color: AppColors.lightest, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: data.entries.map((e) {
                        final percentage = (e.value / total) * 100;
                        return PieChartSectionData(
                          color: _getColorForCategory(e.key),
                          value: e.value,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: data.entries.map((e) => _buildLegendItem(e.key, _getColorForCategory(e.key))).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyTrendChart() {
    final AnalyticsService analyticsService = AnalyticsService();

    return Card(
      color: AppColors.darkGrey,
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly Trend (Last 7 Days)', style: TextStyle(color: AppColors.lightest, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<Map<String, double>>(
                stream: analyticsService.getWeeklySpendingTrend(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));
                  }
                  
                  final data = snapshot.data!;
                  // Ensure we sort by date keys (YYYY-MM-DD)
                  final sortedKeys = data.keys.toList()..sort();
                  
                  return BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                         leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                         rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                         topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                         bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                 if (value < 0 || value >= sortedKeys.length) return const SizedBox();
                                 final dateStr = sortedKeys[value.toInt()];
                                 final date = DateTime.parse(dateStr);
                                 return Padding(
                                   padding: const EdgeInsets.only(top: 8.0),
                                   child: Text(DateFormat('E').format(date), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                 );
                              },
                            ),
                         ),
                      ),
                      barGroups: sortedKeys.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key, 
                          barRods: [
                            BarChartRodData(
                              toY: data[e.value]!, 
                              color: AppColors.lightest,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            )
                          ]
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.lightGrey, fontSize: 12)),
      ],
    );
  }

  Color _getColorForCategory(String category) {
    // Generate distinct colors
    switch (category.hashCode % 6) {
      case 0: return Colors.blue;
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.purple;
      case 4: return Colors.red;
      case 5: return Colors.teal;
      default: return Colors.grey;
    }
  }
}
