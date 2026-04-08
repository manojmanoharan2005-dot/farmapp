import '../services/buyer_service.dart';
import 'base_controller.dart';

class BuyerController extends BaseController {
  final BuyerService _service;

  BuyerController(this._service);

  Map<String, dynamic> livePrice = <String, dynamic>{};
  String marketplaceHtml = '';

  Future<void> fetchLivePrice({
    required String crop,
    required String district,
    required String state,
  }) async {
    setLoading(true);
    clearMessages();
    final result = await _service.getLivePrice(
      crop: crop,
      district: district,
      state: state,
    );
    setLoading(false);

    if (result.isSuccess) {
      livePrice = result.data ?? <String, dynamic>{};
      notifyListeners();
      return;
    }

    setError(result.error ?? 'Live price unavailable');
  }

  Future<void> createListing(Map<String, dynamic> payload) async {
    setLoading(true);
    clearMessages();

    final result = await _service.createListing(payload);
    setLoading(false);

    if (result.isSuccess) {
      setSuccess('Listing submitted successfully');
    } else {
      setError(result.error ?? 'Failed to submit listing');
    }
  }

  Future<void> confirmPurchase({
    required String listingId,
    required String buyerName,
    required String buyerPhone,
  }) async {
    setLoading(true);
    clearMessages();

    final result = await _service.confirmPurchase(
      listingId: listingId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
    );

    setLoading(false);

    if (result.isSuccess) {
      setSuccess(result.data?['message']?.toString() ?? 'Purchase confirmed');
    } else {
      setError(result.error ?? 'Purchase failed');
    }
  }

  Future<void> loadMarketplaceHtml() async {
    setLoading(true);
    clearMessages();

    final result = await _service.loadMarketplaceHtml();
    setLoading(false);

    if (result.isSuccess) {
      marketplaceHtml = result.data ?? '';
      setSuccess('Marketplace page loaded from backend');
      notifyListeners();
    } else {
      setError(result.error ?? 'Failed to load marketplace');
    }
  }
}
