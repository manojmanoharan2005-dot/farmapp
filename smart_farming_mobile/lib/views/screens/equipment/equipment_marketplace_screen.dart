import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/equipment_controller.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/feature_placeholder.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_card.dart';

class EquipmentMarketplaceScreen extends StatefulWidget {
  const EquipmentMarketplaceScreen({super.key});

  @override
  State<EquipmentMarketplaceScreen> createState() =>
      _EquipmentMarketplaceScreenState();
}

class _EquipmentMarketplaceScreenState
    extends State<EquipmentMarketplaceScreen> {
  final _equipmentName = TextEditingController(text: 'Tractor');
  final _district = TextEditingController();
  final _state = TextEditingController(text: 'Tamil Nadu');

  final _listingId = TextEditingController();
  final _renterName = TextEditingController();
  final _renterPhone = TextEditingController();
  final _fromDate = TextEditingController();
  final _toDate = TextEditingController();

  @override
  void dispose() {
    _equipmentName.dispose();
    _district.dispose();
    _state.dispose();
    _listingId.dispose();
    _renterName.dispose();
    _renterPhone.dispose();
    _fromDate.dispose();
    _toDate.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate.text = now.toIso8601String().substring(0, 10);
    _toDate.text = now
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EquipmentController>(
      builder: (context, controller, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (controller.errorMessage != null)
              ErrorBanner(message: controller.errorMessage!),
            const FeaturePlaceholder(
              title: 'Equipment Marketplace Feed',
              description:
                  'Marketplace listing feed is currently template-rendered by backend. This screen supports live rent checks and booking via existing JSON APIs.',
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Get Live Rent',
              child: Column(
                children: <Widget>[
                  AppTextField(
                    controller: _equipmentName,
                    label: 'Equipment name',
                  ),
                  const SizedBox(height: 8),
                  AppTextField(controller: _district, label: 'District'),
                  const SizedBox(height: 8),
                  AppTextField(controller: _state, label: 'State'),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Fetch Rent',
                    isLoading: controller.isLoading,
                    onPressed: () => controller.fetchLiveRent(
                      equipmentName: _equipmentName.text.trim(),
                      district: _district.text.trim(),
                      state: _state.text.trim(),
                    ),
                  ),
                  if (controller.liveRent.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      'Recommended: ₹${controller.liveRent['recommended_rent'] ?? '-'} /day',
                    ),
                    Text(
                      'Range: ₹${controller.liveRent['min_rent'] ?? '-'} - ₹${controller.liveRent['max_rent'] ?? '-'}',
                    ),
                  ],
                ],
              ),
            ),
            SectionCard(
              title: 'Confirm Rental',
              child: Column(
                children: <Widget>[
                  AppTextField(controller: _listingId, label: 'Listing ID'),
                  const SizedBox(height: 8),
                  AppTextField(controller: _renterName, label: 'Renter Name'),
                  const SizedBox(height: 8),
                  AppTextField(controller: _renterPhone, label: 'Renter Phone'),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _fromDate,
                    label: 'Rental From (YYYY-MM-DD)',
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _toDate,
                    label: 'Rental To (YYYY-MM-DD)',
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Confirm Rental',
                    isLoading: controller.isLoading,
                    onPressed: () => controller.confirmRental(<String, dynamic>{
                      'listing_id': _listingId.text.trim(),
                      'renter_name': _renterName.text.trim(),
                      'renter_phone': _renterPhone.text.trim(),
                      'rental_from': _fromDate.text.trim(),
                      'rental_to': _toDate.text.trim(),
                    }),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
