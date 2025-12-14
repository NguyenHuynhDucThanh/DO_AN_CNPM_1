import 'dart:ui';
import 'package:equatable/equatable.dart';

class ChartDataEntity extends Equatable {
  final String categoryName;
  final double amount;
  final double percentage;
  final Color color;

  const ChartDataEntity({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  List<Object?> get props => [categoryName, amount, percentage, color];
}