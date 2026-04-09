import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/app_drawer.dart';
import 'dashboard_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  Future<void> _logout() async {
    final auth = context.read<AuthController>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.landing,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: const Color(0xFFDDE7E0),
        foregroundColor: const Color(0xFF1F2937),
      ),
      drawer: AppDrawer(
        onLogout: _logout,
        currentRoute: AppRoutes.home,
      ),
      body: const DashboardScreen(),
    );
  }
}
