import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../journal/presentation/bloc/journal_bloc.dart';

/// A card widget that displays monthly spending summary with comparison.
class MonthlySpendSummaryCard extends StatelessWidget {
  /// Creates a monthly spend summary card.
  const MonthlySpendSummaryCard({
    required this.monthlySummary,
    super.key,
    this.onTap,
  });

  /// The monthly summary data.
  final MonthlySummary monthlySummary;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isIncrease = monthlySummary.isIncrease;
    final isDecrease = monthlySummary.isDecrease;
    final percentChange = monthlySummary.percentageChange;
    
    // Determine trend color and icon
    final trendColor = isIncrease
        ? Colors.red.shade600
        : isDecrease
            ? Colors.green.shade600
            : colorScheme.onSurfaceVariant;
    
    final trendIcon = isIncrease
        ? Icons.trending_up
        : isDecrease
            ? Icons.trending_down
            : Icons.trending_flat;

    final monthName = DateFormat('MMMM').format(monthlySummary.currentMonthStart);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Monthly Spending',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Amount row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Current month amount
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${monthlySummary.currentMonthAmount.toStringAsFixed(0)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'vs ₹${monthlySummary.previousMonthAmount.toStringAsFixed(0)} last month',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Trend indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendIcon,
                          size: 16,
                          color: trendColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatPercentage(percentChange),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Progress indicator
              const SizedBox(height: 12),
              _buildProgressBar(context),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPercentage(double value) {
    final absValue = value.abs();
    final sign = value >= 0 ? '+' : '-';
    return '$sign${absValue.toStringAsFixed(0)}%';
  }

  Widget _buildProgressBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Calculate progress as ratio of current to previous (capped at 2x)
    double progress;
    if (monthlySummary.previousMonthAmount == 0) {
      progress = monthlySummary.currentMonthAmount > 0 ? 1.0 : 0.0;
    } else {
      progress = (monthlySummary.currentMonthAmount / monthlySummary.previousMonthAmount)
          .clamp(0.0, 2.0) / 2.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              monthlySummary.isIncrease
                  ? Colors.red.shade400
                  : colorScheme.primary,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                  ),
            ),
            Text(
              '2x last month',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
