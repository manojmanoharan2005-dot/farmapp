import '../models/market_record.dart';
import '../services/market_service.dart';
import 'base_controller.dart';

class MarketController extends BaseController {
  final MarketService _service;

  MarketController(this._service);

  List<MarketRecord> records = <MarketRecord>[];
  Map<String, dynamic> trend = <String, dynamic>{};
  Map<String, dynamic> nearby = <String, dynamic>{};

  Future<void> refresh({String? state}) async {
    setLoading(true);
    clearMessages();

    final result = await _service.refreshPrices(state: state);
    setLoading(false);

    if (result.isSuccess) {
      records = result.data ?? <MarketRecord>[];
      notifyListeners();
      return;
    }

    setError(result.error ?? 'Failed to load market records');
  }

  Future<void> loadTrend({
    required String commodity,
    String? state,
    String? district,
  }) async {
    setLoading(true);
    clearMessages();

    final result = await _service.priceTrend(
      commodity: commodity,
      state: state,
      district: district,
    );

    setLoading(false);

    if (result.isSuccess) {
      trend = result.data ?? <String, dynamic>{};
      notifyListeners();
      return;
    }

    setError(result.error ?? 'Failed to load trend');
  }

  Future<void> loadNearbyMandis(double lat, double lon) async {
    setLoading(true);
    clearMessages();

    final result = await _service.nearbyMandis(lat: lat, lon: lon);
    setLoading(false);

    if (result.isSuccess) {
      nearby = result.data ?? <String, dynamic>{};
      notifyListeners();
      return;
    }

    setError(result.error ?? 'Failed to load nearby mandis');
  }
}
