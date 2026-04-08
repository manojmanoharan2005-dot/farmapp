import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/buyer_controller.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/feature_placeholder.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_card.dart';

class BuyerMarketplaceScreen extends StatefulWidget {
  const BuyerMarketplaceScreen({super.key});

  @override
  State<BuyerMarketplaceScreen> createState() => _BuyerMarketplaceScreenState();
}

class _BuyerMarketplaceScreenState extends State<BuyerMarketplaceScreen> {
  final _cropController = TextEditingController(text: 'Tomato');
  final _districtController = TextEditingController();
  final _stateController = TextEditingController(text: 'Tamil Nadu');

  final _listingIdController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();

  @override
  void dispose() {
    _cropController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _listingIdController.dispose();
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BuyerController>(
      builder: (context, controller, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (controller.errorMessage != null)
              ErrorBanner(message: controller.errorMessage!),
            if (controller.successMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(controller.successMessage!),
              ),
            const FeaturePlaceholder(
              title: 'Marketplace Listing Data',
              description:
                  'Buyer marketplace listing cards are rendered as HTML templates by the backend today. This Flutter screen supports live price checks and purchase actions via JSON APIs.',
              tip:
                  'For full listing feed, expose a JSON endpoint in backend or parse the HTML response.',
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Get Live Price',
              child: Column(
                children: <Widget>[
                  AppTextField(controller: _cropController, label: 'Crop'),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _districtController,
                    label: 'District',
                  ),
                  const SizedBox(height: 8),
                  AppTextField(controller: _stateController, label: 'State'),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Fetch Live Price',
                    isLoading: controller.isLoading,
                    onPressed: () => controller.fetchLivePrice(
                      crop: _cropController.text.trim(),
                      district: _districtController.text.trim(),
                      state: _stateController.text.trim(),
                    ),
                  ),
                  if (controller.livePrice.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      'Recommended: ₹${controller.livePrice['recommended_price'] ?? '-'}',
                    ),
                    Text(
                      'Allowed Range: ₹${controller.livePrice['min_price'] ?? '-'} - ₹${controller.livePrice['max_price'] ?? '-'}',
                    ),
                  ],
                ],
              ),
            ),
            SectionCard(
              title: 'Confirm Purchase',
              child: Column(
                children: <Widget>[
                  AppTextField(
                    controller: _listingIdController,
                    label: 'Listing ID',
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _buyerNameController,
                    label: 'Buyer name',
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _buyerPhoneController,
                    label: 'Buyer phone',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Confirm Purchase',
                    isLoading: controller.isLoading,
                    onPressed: () => controller.confirmPurchase(
                      listingId: _listingIdController.text.trim(),
                      buyerName: _buyerNameController.text.trim(),
                      buyerPhone: _buyerPhoneController.text.trim(),
                    ),
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
