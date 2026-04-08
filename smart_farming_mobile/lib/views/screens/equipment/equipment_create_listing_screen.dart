import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/equipment_controller.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';

class EquipmentCreateListingScreen extends StatefulWidget {
  const EquipmentCreateListingScreen({super.key});

  @override
  State<EquipmentCreateListingScreen> createState() =>
      _EquipmentCreateListingScreenState();
}

class _EquipmentCreateListingScreenState
    extends State<EquipmentCreateListingScreen> {
  final _equipment = TextEditingController(text: 'Tractor');
  final _district = TextEditingController();
  final _state = TextEditingController(text: 'Tamil Nadu');
  final _description = TextEditingController();
  final _rent = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from.text = now.toIso8601String().substring(0, 10);
    _to.text = now
        .add(const Duration(days: 7))
        .toIso8601String()
        .substring(0, 10);
  }

  @override
  void dispose() {
    _equipment.dispose();
    _district.dispose();
    _state.dispose();
    _description.dispose();
    _rent.dispose();
    _from.dispose();
    _to.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await context.read<EquipmentController>().createListing(<String, dynamic>{
      'equipment_name': _equipment.text.trim(),
      'district': _district.text.trim(),
      'state': _state.text.trim(),
      'description': _description.text.trim(),
      'rent': _rent.text.trim(),
      'available_from': _from.text.trim(),
      'available_to': _to.text.trim(),
      'latitude': _lat.text.trim(),
      'longitude': _lon.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EquipmentController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Equipment Create Listing')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (controller.errorMessage != null)
                  ErrorBanner(message: controller.errorMessage!),
                AppTextField(controller: _equipment, label: 'Equipment Name'),
                const SizedBox(height: 8),
                AppTextField(controller: _district, label: 'District'),
                const SizedBox(height: 8),
                AppTextField(controller: _state, label: 'State'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _rent,
                  label: 'Rent per day',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _from,
                  label: 'Available From (YYYY-MM-DD)',
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _to,
                  label: 'Available To (YYYY-MM-DD)',
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _lat,
                  label: 'Latitude',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _lon,
                  label: 'Longitude',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _description,
                  label: 'Description',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Submit Listing',
                  isLoading: controller.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
