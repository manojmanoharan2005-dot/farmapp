import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/growing_controller.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_state.dart';

class GrowingActivitiesScreen extends StatefulWidget {
  const GrowingActivitiesScreen({super.key});

  @override
  State<GrowingActivitiesScreen> createState() =>
      _GrowingActivitiesScreenState();
}

class _GrowingActivitiesScreenState extends State<GrowingActivitiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GrowingController>().loadActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GrowingController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Growing Activities')),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: controller.loadActivities,
              child: controller.isLoading && controller.activities.isEmpty
                  ? const LoadingState(label: 'Loading activities...')
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        if (controller.errorMessage != null)
                          ErrorBanner(message: controller.errorMessage!),
                        if (controller.activities.isEmpty)
                          const Text('No active crop activities found yet.')
                        else
                          ...controller.activities.map((activity) {
                            final crop =
                                (activity['crop'] ??
                                        activity['crop_name'] ??
                                        'Unknown')
                                    .toString();
                            final progress = (activity['progress'] ?? 0)
                                .toString();
                            return Card(
                              child: ListTile(
                                title: Text(crop),
                                subtitle: Text('Progress: $progress%'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.growingView,
                                    arguments: activity,
                                  );
                                },
                              ),
                            );
                          }),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
