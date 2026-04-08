import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/market_controller.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';

class MarketWatchScreen extends StatefulWidget {
  const MarketWatchScreen({super.key});

  @override
  State<MarketWatchScreen> createState() => _MarketWatchScreenState();
}

class _MarketWatchScreenState extends State<MarketWatchScreen> {
  final _commodityController = TextEditingController(text: 'Tomato');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<MarketController>();
      if (controller.records.isEmpty) {
        controller.refresh();
      }
    });
  }

  @override
  void dispose() {
    _commodityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketController>(
      builder: (context, controller, _) {
        return RefreshIndicator(
          onRefresh: () => controller.refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (controller.errorMessage != null)
                ErrorBanner(message: controller.errorMessage!),
              SectionCard(
                title: 'Trend Lookup',
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _commodityController,
                        decoration: const InputDecoration(
                          labelText: 'Commodity',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => controller.loadTrend(
                        commodity: _commodityController.text.trim(),
                      ),
                      child: const Text('Trend'),
                    ),
                  ],
                ),
              ),
              if (controller.trend.isNotEmpty)
                SectionCard(
                  title: 'Trend Analysis',
                  child: Text(
                    'Direction: ${(controller.trend['analysis'] ?? const {})['direction'] ?? 'N/A'}\n'
                    'Change: ${(controller.trend['analysis'] ?? const {})['change_percent'] ?? '-'}%',
                  ),
                ),
              if (controller.isLoading && controller.records.isEmpty)
                const LoadingState(label: 'Fetching market prices...')
              else
                SectionCard(
                  title: 'Live Market Prices',
                  child: Column(
                    children: controller.records.take(30).map((record) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(record.commodity),
                        subtitle: Text(
                          '${record.district}, ${record.state} • ${record.mandi}',
                        ),
                        trailing: Text(
                          '₹${record.currentPriceKg.toStringAsFixed(1)}/kg',
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
