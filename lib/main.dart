import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/member_provider.dart';
import 'presentation/providers/payment_provider.dart';
import 'presentation/providers/attendance_provider.dart';
import 'presentation/providers/website_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/pending_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();
  await authProvider.loadPersistedLogin();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => WebsiteProvider()),
      ],
      child: const MusclesUpAdminApp(),
    ),
  );
}

class MusclesUpAdminApp extends StatelessWidget {
  const MusclesUpAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muscles Up Gym Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            final user = auth.currentUser;
            if (user != null && user.isApproved) {
              return const DashboardScreen();
            } else {
              return const PendingScreen();
            }
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
