import '../services/equipment_service.dart';
import 'base_controller.dart';

class EquipmentController extends BaseController {
  final EquipmentService _service;

  EquipmentController(this._service);

  Map<String, dynamic> liveRent = <String, dynamic>{};
  String marketplaceHtml = '';

  Future<void> fetchLiveRent({
    required String equipmentName,
    required String district,
    required String state,
  }) async {
    setLoading(true);
    clearMessages();

    final result = await _service.getLiveRent(
      equipmentName: equipmentName,
      district: district,
      state: state,
    );

    setLoading(false);

    if (result.isSuccess) {
      liveRent = result.data ?? <String, dynamic>{};
      notifyListeners();
    } else {
      setError(result.error ?? 'Live rent unavailable');
    }
  }

  Future<void> createListing(Map<String, dynamic> payload) async {
    setLoading(true);
    clearMessages();

    final result = await _service.createListing(payload);

    setLoading(false);

    if (result.isSuccess) {
      setSuccess('Equipment listing created');
    } else {
      setError(result.error ?? 'Failed to create listing');
    }
  }

  Future<void> confirmRental(Map<String, dynamic> payload) async {
    setLoading(true);
    clearMessages();

    final result = await _service.confirmRental(payload);

    setLoading(false);

    if (result.isSuccess) {
      setSuccess(result.data?['message']?.toString() ?? 'Rental confirmed');
    } else {
      setError(result.error ?? 'Rental booking failed');
    }
  }

  Future<void> loadMarketplaceHtml() async {
    setLoading(true);
    clearMessages();

    final result = await _service.loadMarketplaceHtml();

    setLoading(false);

    if (result.isSuccess) {
      marketplaceHtml = result.data ?? '';
      setSuccess('Equipment marketplace loaded');
      notifyListeners();
    } else {
      setError(result.error ?? 'Failed to load marketplace');
    }
  }
}
