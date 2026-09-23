import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../theme/app_colors.dart';

/// One bar of a bar chart.
class BarPoint {
  const BarPoint({
    required this.label,
    required this.valueMinor,
    this.highlight = false,
  });

  final String label;
  final int valueMinor;
  final bool highlight;
}

/// Simple accessible bar chart for money values. The chart is wrapped in a
/// [Semantics] node with a textual summary for screen readers.
class MoneyBarChart extends StatelessWidget {
  const MoneyBarChart({
    super.key,
    required this.points,
    required this.currency,
    required this.semanticsLabel,
    this.color,
    this.secondaryPoints,
    this.secondaryColor,
    this.height = 180,
    this.hidden = false,
  });

  final List<BarPoint> points;

  /// Optional second series drawn next to each bar (e.g. income).
  final List<BarPoint>? secondaryPoints;
  final Currency currency;
  final String semanticsLabel;
  final Color? color;
  final Color? secondaryColor;
  final double height;

  /// Hide values (privacy mode): bars still show relative size.
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final primary = color ?? context.colors.primary;
    final secondary = secondaryColor ?? context.semantic.income;
    final maxValue = [
      ...points.map((p) => p.valueMinor),
      ...?secondaryPoints?.map((p) => p.valueMinor),
    ].fold<int>(0, math.max);
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.15;
    final rodWidth = secondaryPoints == null
        ? (points.length > 12 ? 8.0 : 18.0)
        : (points.length > 8 ? 6.0 : 10.0);

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: context.colors.outlineVariant,
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final step = points.length > 16 ? 5 : 1;
                      if (i % step != 0 && i != points.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          points[i].label,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: points[i].highlight
                                ? context.colors.primary
                                : context.colors.onSurfaceVariant,
                            fontWeight: points[i].highlight
                                ? FontWeight.w700
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: !hidden,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => context.colors.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                        Money.format(rod.toY.round(), currency, compact: true),
                        TextStyle(
                          color: context.colors.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      if (secondaryPoints != null)
                        BarChartRodData(
                          toY: secondaryPoints![i].valueMinor.toDouble(),
                          color: secondary,
                          width: rodWidth,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      BarChartRodData(
                        toY: points[i].valueMinor.toDouble(),
                        color: points[i].highlight || secondaryPoints != null
                            ? primary
                            : primary.withValues(alpha: 0.55),
                        width: rodWidth,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: secondaryPoints == null,
                          toY: maxY,
                          color: context.colors.surfaceContainerHigh,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A donut slice.
class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.valueMinor,
    required this.color,
  });

  final String label;
  final int valueMinor;
  final Color color;
}

/// Donut chart with an accessible summary. Legends are rendered separately
/// as text lists by callers, so no information depends on colour alone.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.semanticsLabel,
    this.center,
    this.size = 180,
  });

  final List<DonutSlice> slices;
  final String semanticsLabel;
  final Widget? center;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(0, (s, e) => s + e.valueMinor);
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: size,
          width: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: size * 0.3,
                  startDegreeOffset: -90,
                  sections: total == 0
                      ? [
                          PieChartSectionData(
                            value: 1,
                            color: context.colors.surfaceContainerHigh,
                            radius: size * 0.16,
                            showTitle: false,
                          ),
                        ]
                      : [
                          for (final s in slices)
                            PieChartSectionData(
                              value: s.valueMinor.toDouble(),
                              color: s.color,
                              radius: size * 0.16,
                              showTitle: false,
                            ),
                        ],
                ),
              ),
              ?center,
            ],
          ),
        ),
      ),
    );
  }
}

/// A line chart point.
class LinePoint {
  const LinePoint({required this.label, required this.valueMinor});

  final String label;
  final int valueMinor;
}

/// Trend line (e.g. monthly spending) with accessible summary.
class MoneyLineChart extends StatelessWidget {
  const MoneyLineChart({
    super.key,
    required this.points,
    required this.currency,
    required this.semanticsLabel,
    this.color,
    this.height = 180,
  });

  final List<LinePoint> points;
  final Currency currency;
  final String semanticsLabel;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final lineColor = color ?? context.semantic.expense;
    final maxValue = points.map((p) => p.valueMinor).fold<int>(0, math.max);
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.2;
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: context.colors.outlineVariant,
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= points.length || value != i) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          points[i].label,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => context.colors.inverseSurface,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        Money.format(s.y.round(), currency, compact: true),
                        TextStyle(
                          color: context.colors.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].valueMinor.toDouble()),
                  ],
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
