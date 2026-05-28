import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PaymentStatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _displayText,
        style: TextStyle(
          color: _textColor,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _displayText {
    switch (status) {
      case 'paid': return 'Paid';
      case 'pending': return 'Pending';
      case 'partial': return 'Partial';
      case 'voided': return 'Voided';
      default: return status;
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case 'paid': return AppColors.successLight;
      case 'pending': return AppColors.dangerLight;
      case 'partial': return AppColors.warningLight;
      case 'voided': return const Color(0xFFF1F5F9);
      default: return AppColors.background;
    }
  }

  Color get _textColor {
    switch (status) {
      case 'paid': return AppColors.success;
      case 'pending': return AppColors.danger;
      case 'partial': return AppColors.warning;
      case 'voided': return AppColors.textTertiary;
      default: return AppColors.textSecondary;
    }
  }
}
