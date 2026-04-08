import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/dashboard_controller.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.weather.isEmpty) {
          return const LoadingState(label: 'Loading dashboard...');
        }

        final weather = controller.weather;
        final current = weather['current'] is Map
            ? Map<String, dynamic>.from(weather['current'] as Map)
            : <String, dynamic>{};

        final snapshot = controller.snapshot;
        final profit = snapshot['profit'] is Map
            ? Map<String, dynamic>.from(snapshot['profit'] as Map)
            : <String, dynamic>{};

        final profitData = profit['data'] is Map
            ? Map<String, dynamic>.from(profit['data'] as Map)
            : <String, dynamic>{};

        return RefreshIndicator(
          onRefresh: controller.loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              SectionCard(
                title: 'Weather Summary',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Location: ${current['location'] ?? 'Unknown'}'),
                    Text('Condition: ${current['condition'] ?? 'N/A'}'),
                    Text('Temperature: ${current['temperature'] ?? '-'} °C'),
                    Text('Humidity: ${current['humidity'] ?? '-'} %'),
                    Text('Wind: ${current['wind_speed'] ?? '-'} km/h'),
                  ],
                ),
              ),
              SectionCard(
                title: 'Farm Financial Snapshot',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Revenue: ₹ ${profitData['total_revenue'] ?? 0}'),
                    Text('Expenses: ₹ ${profitData['total_expenses'] ?? 0}'),
                    Text('Net Profit: ₹ ${profitData['net_profit'] ?? 0}'),
                    Text('ROI: ${profitData['roi'] ?? 0}%'),
                  ],
                ),
              ),
              SectionCard(
                title: 'Quick Access',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.cropSuggestion,
                      ),
                      child: const Text('Crop Suggestion'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.fertilizerRecommend,
                      ),
                      child: const Text('Fertilizer'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.growingActivities,
                      ),
                      child: const Text('Growing Activities'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.regionalCalendar,
                      ),
                      child: const Text('Regional Calendar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
