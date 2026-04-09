import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.onLogout,
    this.currentRoute = AppRoutes.home,
  });

  final VoidCallback onLogout;
  final String currentRoute;

  bool _isActiveRoute(String route) {
    if (route == AppRoutes.dashboard || route == AppRoutes.home) {
      return currentRoute == AppRoutes.dashboard || currentRoute == AppRoutes.home;
    }
    return currentRoute == route;
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);
    if (route == AppRoutes.home || route == AppRoutes.dashboard) {
      if (_isActiveRoute(route)) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
      return;
    }

    Navigator.pushNamed(context, route);
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF98A6BE),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    String? badge,
  }) {
    final active = _isActiveRoute(route);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE6F4EC) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _navigate(context, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: active ? const Color(0xFF16A34A) : const Color(0xFF637A98),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? const Color(0xFF16A34A) : const Color(0xFF456183),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Drawer(
        backgroundColor: const Color(0xFFF7FBF9),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0EAF0)),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF22C55E), Color(0xFF16A34A)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.spa_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Smart Farming',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Agricultural Platform',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF66829E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  children: <Widget>[
                    _sectionLabel('MAIN MENU'),
                    _navTile(
                      context,
                      icon: Icons.grid_view_rounded,
                      title: 'Dashboard',
                      route: AppRoutes.home,
                    ),
                    _navTile(
                      context,
                      icon: Icons.energy_savings_leaf_outlined,
                      title: 'Crop Suggestion',
                      route: AppRoutes.cropSuggestion,
                    ),
                    _navTile(
                      context,
                      icon: Icons.biotech_outlined,
                      title: 'Disease Detection',
                      route: AppRoutes.diseaseDetection,
                    ),
                    _navTile(
                      context,
                      icon: Icons.science_outlined,
                      title: 'Fertilizer Advice',
                      route: AppRoutes.fertilizerRecommend,
                    ),
                    _navTile(
                      context,
                      icon: Icons.show_chart_rounded,
                      title: 'Market Prices',
                      route: AppRoutes.marketWatch,
                      badge: 'Live',
                    ),
                    _navTile(
                      context,
                      icon: Icons.calendar_month_rounded,
                      title: 'Regional Calendar',
                      route: AppRoutes.regionalCalendar,
                    ),

                    _sectionLabel('BUYER CONNECT'),
                    _navTile(
                      context,
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Sell My Crop',
                      route: AppRoutes.createListing,
                    ),
                    _navTile(
                      context,
                      icon: Icons.view_list_rounded,
                      title: 'My Listings',
                      route: AppRoutes.myListings,
                    ),
                    _navTile(
                      context,
                      icon: Icons.storefront_outlined,
                      title: 'Buy from Farmers',
                      route: AppRoutes.buyerMarketplace,
                      badge: 'New',
                    ),
                    _navTile(
                      context,
                      icon: Icons.history_rounded,
                      title: 'Purchase History',
                      route: AppRoutes.purchaseHistory,
                    ),

                    _sectionLabel('TOOLS'),
                    _navTile(
                      context,
                      icon: Icons.calculate_outlined,
                      title: 'Expense Calculator',
                      route: AppRoutes.reports,
                    ),
                    _navTile(
                      context,
                      icon: Icons.cloud_outlined,
                      title: 'Weather Forecast',
                      route: AppRoutes.marketWatch,
                    ),
                    _navTile(
                      context,
                      icon: Icons.account_balance_outlined,
                      title: 'Govt. Schemes',
                      route: AppRoutes.about,
                    ),
                    _navTile(
                      context,
                      icon: Icons.menu_book_outlined,
                      title: "Farmer's Manual",
                      route: AppRoutes.features,
                    ),

                    _sectionLabel('EQUIPMENT SHARING'),
                    _navTile(
                      context,
                      icon: Icons.add_circle_outline_rounded,
                      title: 'List My Equipment',
                      route: AppRoutes.equipmentCreateListing,
                    ),
                    _navTile(
                      context,
                      icon: Icons.view_list_rounded,
                      title: 'My Equipment',
                      route: AppRoutes.equipmentMyListings,
                    ),
                    _navTile(
                      context,
                      icon: Icons.shopping_bag_outlined,
                      title: 'Rent Equipment',
                      route: AppRoutes.equipmentMarketplace,
                      badge: 'Live',
                    ),
                    _navTile(
                      context,
                      icon: Icons.history_rounded,
                      title: 'Rental History',
                      route: AppRoutes.equipmentRentalHistory,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Farmer',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Smart Member',
                            style: TextStyle(
                              color: Color(0xFF6B7F97),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onLogout();
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                      ),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
