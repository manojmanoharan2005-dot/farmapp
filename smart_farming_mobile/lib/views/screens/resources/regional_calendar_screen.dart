import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/resources_controller.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_card.dart';

class RegionalCalendarScreen extends StatefulWidget {
  const RegionalCalendarScreen({super.key});

  @override
  State<RegionalCalendarScreen> createState() => _RegionalCalendarScreenState();
}

class _RegionalCalendarScreenState extends State<RegionalCalendarScreen> {
  final _state = TextEditingController(text: 'Tamil Nadu');
  final _district = TextEditingController();
  final _soil = TextEditingController(text: 'Loamy');
  final _previous = TextEditingController();

  @override
  void dispose() {
    _state.dispose();
    _district.dispose();
    _soil.dispose();
    _previous.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    await context.read<ResourcesController>().generateCalendar(
      state: _state.text.trim(),
      district: _district.text.trim(),
      soilType: _soil.text.trim(),
      previousCrops: _previous.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ResourcesController>(
      builder: (context, controller, _) {
        final data = controller.calendarData;
        final calendar = data['calendar'] is List
            ? data['calendar'] as List
            : const <dynamic>[];

        return Scaffold(
          appBar: AppBar(title: const Text('Regional Calendar')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (controller.errorMessage != null)
                  ErrorBanner(message: controller.errorMessage!),
                SectionCard(
                  title: 'Generate AI Crop Calendar',
                  child: Column(
                    children: <Widget>[
                      AppTextField(controller: _state, label: 'State'),
                      const SizedBox(height: 8),
                      AppTextField(controller: _district, label: 'District'),
                      const SizedBox(height: 8),
                      AppTextField(controller: _soil, label: 'Soil Type'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _previous,
                        label: 'Previous Crops',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: 'Generate Calendar',
                        isLoading: controller.isLoading,
                        onPressed: _generate,
                      ),
                    ],
                  ),
                ),
                if (calendar.isNotEmpty)
                  SectionCard(
                    title: 'Season-wise Plan for ${data['region'] ?? ''}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: calendar.whereType<Map>().map((season) {
                        final crops = season['recommended_crops'] is List
                            ? season['recommended_crops'] as List
                            : const <dynamic>[];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${season['season'] ?? 'Season'} (${season['months'] ?? ''})',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              ...crops.whereType<Map>().map(
                                (crop) => Text(
                                  '• ${crop['crop_name']} | Sowing: ${crop['sowing_period']} | Harvest: ${crop['harvesting_period']}',
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
