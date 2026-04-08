import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/reports_controller.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsController>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsController>(
      builder: (context, controller, _) {
        if (controller.isLoading &&
            controller.cropPlan.isEmpty &&
            controller.profit.isEmpty) {
          return const LoadingState(label: 'Loading reports...');
        }

        return RefreshIndicator(
          onRefresh: controller.loadReports,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (controller.errorMessage != null)
                ErrorBanner(message: controller.errorMessage!),
              SectionCard(
                title: 'Crop Plan Report',
                child: Text(
                  'Items: ${(controller.cropPlan['crops'] as List?)?.length ?? 0}',
                ),
              ),
              SectionCard(
                title: 'Harvest Report',
                child: Text(
                  'Entries: ${(controller.harvest['crops'] as List?)?.length ?? 0}',
                ),
              ),
              SectionCard(
                title: 'Profit Report',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Revenue: ₹${controller.profit['total_revenue'] ?? 0}',
                    ),
                    Text(
                      'Expenses: ₹${controller.profit['total_expenses'] ?? 0}',
                    ),
                    Text(
                      'Net Profit: ₹${controller.profit['net_profit'] ?? 0}',
                    ),
                    Text('ROI: ${controller.profit['roi'] ?? 0}%'),
                  ],
                ),
              ),
              SectionCard(
                title: 'Download Reports (PDF)',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () =>
                          controller.openUrl(controller.marketPdfUrl),
                      child: const Text('Market PDF'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          controller.openUrl(controller.weatherPdfUrl),
                      child: const Text('Weather PDF'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          controller.openUrl(controller.expensePdfUrl),
                      child: const Text('Expense PDF'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          controller.openUrl(controller.cropProgressPdfUrl),
                      child: const Text('Crop Progress PDF'),
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
