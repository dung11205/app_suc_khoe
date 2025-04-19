import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/health_entry.dart';

class ChartWidget extends StatelessWidget {
  final List<HealthEntry> entries;

  const ChartWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu để hiển thị'));
    }

    final sortedEntries = List<HealthEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      children: [
        const Text('Biểu đồ cân nặng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < sortedEntries.length) {
                        final date = sortedEntries[index].date;
                        return Text('${date.day}/${date.month}');
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: sortedEntries.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.weight);
                  }).toList(),
                  isCurved: true,
                  barWidth: 2,
                  color: Colors.green,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}