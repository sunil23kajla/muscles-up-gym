import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import 'login_screen.dart';

class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1E293B), AppColors.background],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pending Lock Card
              GlassCard(
                borderColor: AppColors.neonAmber.withOpacity(0.4),
                bgColor: AppColors.surface.withOpacity(0.65),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.neonAmber.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.neonAmber, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonAmber.withOpacity(0.15),
                            blurRadius: 25,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.hourglass_empty_rounded,
                        color: AppColors.neonAmber,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Approval Pending',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your staff registration request is under review by the head Administrator.\n\nOnce approved, you will be granted immediate access to the management console dashboards. Thank you for your patience!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Log Out Button
              NeonButton(
                text: 'BACK TO LOG IN',
                icon: Icons.logout,
                gradient: AppColors.warningGlow,
                glowColor: AppColors.neonAmber.withOpacity(0.25),
                onPressed: () {
                  // Cleanly invalidate memory token on signout
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
