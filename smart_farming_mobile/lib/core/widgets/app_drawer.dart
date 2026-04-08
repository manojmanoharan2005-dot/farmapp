import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    Widget navTile(String title, String route) {
      return ListTile(
        title: Text(title),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
      );
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: <Widget>[
            const ListTile(
              title: Text(
                'Smart Farming Assistant',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Mobile App Navigation'),
            ),
            const Divider(),
            navTile('Dashboard', AppRoutes.home),
            navTile('Crop Suggestion', AppRoutes.cropSuggestion),
            navTile('Start Growing', AppRoutes.startGrowing),
            navTile('Growing Activities', AppRoutes.growingActivities),
            navTile('Fertilizer Recommend', AppRoutes.fertilizerRecommend),
            navTile('Disease Detection', AppRoutes.diseaseDetection),
            navTile('Market Watch', AppRoutes.marketWatch),
            navTile('Buyer Marketplace', AppRoutes.buyerMarketplace),
            navTile('Create Crop Listing', AppRoutes.createListing),
            navTile('My Crop Listings', AppRoutes.myListings),
            navTile('Purchase History', AppRoutes.purchaseHistory),
            navTile('Equipment Marketplace', AppRoutes.equipmentMarketplace),
            navTile(
              'Equipment Create Listing',
              AppRoutes.equipmentCreateListing,
            ),
            navTile('Equipment List Form', AppRoutes.equipmentListForm),
            navTile('Equipment My Listings', AppRoutes.equipmentMyListings),
            navTile(
              'Equipment Rental History',
              AppRoutes.equipmentRentalHistory,
            ),
            navTile('Regional Calendar', AppRoutes.regionalCalendar),
            navTile('Chat Assistant', AppRoutes.chat),
            navTile('Reports', AppRoutes.reports),
            navTile('About', AppRoutes.about),
            navTile('Features', AppRoutes.features),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
