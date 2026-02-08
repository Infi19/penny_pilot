import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../services/analytics_service.dart';

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
        ],
      ),
    );
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
