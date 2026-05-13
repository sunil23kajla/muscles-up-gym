import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        color = AppColors.neonGreen.withOpacity(0.12);
        textColor = AppColors.neonGreen;
        break;
      case 'expired':
      case 'rejected':
        color = AppColors.neonRed.withOpacity(0.12);
        textColor = AppColors.neonRed;
        break;
      case 'pending':
      default:
        color = AppColors.neonAmber.withOpacity(0.12);
        textColor = AppColors.neonAmber;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: textColor.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
