import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/app_drawer.dart';
import '../buyer/buyer_marketplace_screen.dart';
import '../equipment/equipment_marketplace_screen.dart';
import '../market/market_watch_screen.dart';
import '../reports/reports_screen.dart';
import 'dashboard_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  final _tabs = const <Widget>[
    DashboardScreen(),
    MarketWatchScreen(),
    BuyerMarketplaceScreen(),
    EquipmentMarketplaceScreen(),
    ReportsScreen(),
  ];

  final _titles = const <String>[
    'Dashboard',
    'Market Watch',
    'Buyer Marketplace',
    'Equipment Sharing',
    'Reports',
  ];

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
      appBar: AppBar(title: Text(_titles[_index])),
      drawer: AppDrawer(onLogout: _logout),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Market'),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Buyer',
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            label: 'Equipment',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
