import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/buyer_controller.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _crop = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController(text: 'kg');
  final _district = TextEditingController();
  final _state = TextEditingController(text: 'Tamil Nadu');
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  @override
  void dispose() {
    _crop.dispose();
    _quantity.dispose();
    _unit.dispose();
    _district.dispose();
    _state.dispose();
    _description.dispose();
    _price.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await context.read<BuyerController>().createListing(<String, dynamic>{
      'crop': _crop.text.trim(),
      'quantity': _quantity.text.trim(),
      'unit': _unit.text.trim(),
      'district': _district.text.trim(),
      'state': _state.text.trim(),
      'description': _description.text.trim(),
      'price': _price.text.trim(),
      'latitude': _latitude.text.trim(),
      'longitude': _longitude.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BuyerController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create Crop Listing')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (controller.errorMessage != null)
                  ErrorBanner(message: controller.errorMessage!),
                AppTextField(controller: _crop, label: 'Crop'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _quantity,
                  label: 'Quantity',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                AppTextField(controller: _unit, label: 'Unit (kg/quintal)'),
                const SizedBox(height: 8),
                AppTextField(controller: _district, label: 'District'),
                const SizedBox(height: 8),
                AppTextField(controller: _state, label: 'State'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _price,
                  label: 'Price',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _latitude,
                  label: 'Latitude',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _longitude,
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
