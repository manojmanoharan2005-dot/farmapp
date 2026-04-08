class MarketRecord {
  final String commodity;
  final String mandi;
  final String district;
  final String state;
  final double currentPriceKg;
  final double change;

  const MarketRecord({
    required this.commodity,
    required this.mandi,
    required this.district,
    required this.state,
    required this.currentPriceKg,
    required this.change,
  });

  factory MarketRecord.fromMap(Map<String, dynamic> map) {
    final dynamic rawPrice = map['current_price_kg'] ?? map['modal_price'] ?? 0;
    final dynamic rawChange = map['change'] ?? 0;

    return MarketRecord(
      commodity: (map['commodity'] ?? 'Unknown').toString(),
      mandi: (map['mandi'] ?? map['market'] ?? 'Local Mandi').toString(),
      district: (map['district'] ?? '').toString(),
      state: (map['state'] ?? '').toString(),
      currentPriceKg: double.tryParse(rawPrice.toString()) ?? 0,
      change: double.tryParse(rawChange.toString().replaceAll('%', '')) ?? 0,
    );
  }
}
