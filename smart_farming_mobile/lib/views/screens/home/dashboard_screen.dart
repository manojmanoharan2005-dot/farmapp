import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../controllers/dashboard_controller.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/loading_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Duration _liveRefreshInterval = Duration(seconds: 30);

  Timer? _clockTimer;
  Timer? _liveRefreshTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<DashboardController>();
      controller.loadDashboard();

      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
      });

      _liveRefreshTimer = Timer.periodic(_liveRefreshInterval, (_) {
        if (!mounted) return;
        controller.loadLivePanels();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _greeting() {
    final hour = _now.hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }

  String _formatMoney(double amount) {
    if (amount.abs() >= 100000) {
      return NumberFormat.compactCurrency(
        locale: 'en_IN',
        symbol: 'Rs ',
        decimalDigits: 1,
      ).format(amount);
    }

    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs ',
      decimalDigits: 0,
    ).format(amount);
  }

  double _normalizePricePerKg(dynamic rawPrice) {
    final value = _asDouble(rawPrice);
    if (value <= 0) return 0;

    // Most backend market records store modal_price as quintal rate.
    if (value > 250) {
      return value / 100;
    }

    return value;
  }

  String _weatherUpdatedLabel(
    Map<String, dynamic> weather,
    DashboardController controller,
  ) {
    final text = (weather['last_updated'] ?? '').toString().trim();
    if (text.isNotEmpty) {
      return text;
    }

    final stamp = controller.lastLiveUpdatedAt;
    if (stamp != null) {
      return DateFormat('hh:mm a').format(stamp);
    }

    return '--';
  }

  String _marketUpdatedLabel(
    Map<String, dynamic> marketData,
    DashboardController controller,
  ) {
    final text = (marketData['generated_at'] ?? '').toString().trim();
    if (text.isNotEmpty) {
      try {
        final parsed = DateFormat('yyyy-MM-dd HH:mm:ss').parseStrict(text);
        return DateFormat('hh:mm a').format(parsed);
      } catch (_) {
        return text;
      }
    }

    final stamp = controller.lastLiveUpdatedAt;
    if (stamp != null) {
      return DateFormat('hh:mm a').format(stamp);
    }

    return '--';
  }

  IconData _commodityIcon(String commodity) {
    final value = commodity.toLowerCase();
    if (value.contains('tomato')) return Icons.local_pizza_outlined;
    if (value.contains('onion')) return Icons.circle_outlined;
    if (value.contains('potato')) return Icons.brightness_1_outlined;
    if (value.contains('apple')) return Icons.apple_outlined;
    if (value.contains('banana')) return Icons.eco_outlined;
    if (value.contains('rice') || value.contains('wheat')) {
      return Icons.grass_outlined;
    }
    return Icons.spa_outlined;
  }

  Color _changeColor(double change, ThemeData theme) {
    if (change > 0) {
      return Colors.green.shade700;
    }
    if (change < 0) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.primary;
  }

  Widget _buildLiveBadge({
    required String label,
    required Color color,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.circle, size: 8, color: textColor ?? Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required double width,
    required String marketUpdated,
    required String weatherUpdated,
  }) {
    final isWide = width >= 920;

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _greeting(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Welcome to Smart Farming',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Live weather and commodity data auto-refresh every 30 seconds.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blueGrey.shade600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            _buildLiveBadge(
              label: 'Weather: $weatherUpdated',
              color: const Color(0xFF2563EB),
            ),
            _buildLiveBadge(
              label: 'Market: $marketUpdated',
              color: const Color(0xFF16A34A),
            ),
          ],
        ),
      ],
    );

    final right = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7DE)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            DateFormat('hh:mm:ss a').format(_now),
            style: const TextStyle(
              color: Color(0xFF059669),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd').format(_now),
            style: const TextStyle(
              fontSize: 42,
              height: 0.95,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            DateFormat('MMM yyyy').format(_now),
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: left),
          const SizedBox(width: 16),
          right,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        left,
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerRight, child: right),
      ],
    );
  }

  Widget _buildProfitBar({
    required double revenue,
    required double expenses,
    required double netProfit,
    required double roi,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x2A0F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        spacing: 16,
        children: <Widget>[
          _profitTile('Revenue', _formatMoney(revenue), Colors.greenAccent),
          _profitTile('Expenses', _formatMoney(expenses), Colors.orangeAccent),
          _profitTile('Net Profit', _formatMoney(netProfit), Colors.cyanAccent),
          _profitTile('ROI', '${roi.toStringAsFixed(1)}%', Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _profitTile(String label, String value, Color color) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketFeedCard(
    BuildContext context, {
    required List<Map<String, dynamic>> marketFeed,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7EBDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.show_chart, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live Commodity Feed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildLiveBadge(
                label: 'Live',
                color: const Color(0xFF111827),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (marketFeed.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Text(
                'No market prices available yet. Pull to refresh.',
                style: TextStyle(color: Colors.blueGrey.shade700),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...marketFeed.take(8).map((item) {
              final commodity = (item['commodity'] ?? 'Commodity').toString();
              final district = (item['district'] ?? '').toString();
              final mandi = (item['market'] ?? item['mandi'] ?? 'Local mandi')
                  .toString();
              final change = _asDouble(item['change']);
              final normalizedPrice = _normalizePricePerKg(
                item['current_price_kg'] ?? item['modal_price'] ?? item['price'],
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFF8FCF8),
                  border: Border.all(color: const Color(0xFFE1EFE4)),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFE9F7ED),
                      ),
                      child: Icon(
                        _commodityIcon(commodity),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            commodity,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            district.isNotEmpty ? '$district - $mandi' : mandi,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          'Rs ${normalizedPrice.toStringAsFixed(2)}/kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _changeColor(change, theme),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.marketWatch),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Full Market Watch'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCropsCard(
    BuildContext context, {
    required List<Map<String, dynamic>> activeCrops,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.agriculture_outlined, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 8),
              Text(
                'Active Crop Management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (activeCrops.isEmpty)
            Column(
              children: <Widget>[
                const SizedBox(height: 16),
                Icon(Icons.spa_outlined, size: 42, color: Colors.green.shade600),
                const SizedBox(height: 8),
                const Text(
                  'No active crops',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start your first crop activity to see progress updates here.',
                  style: TextStyle(color: Colors.blueGrey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.cropSuggestion),
                  icon: const Icon(Icons.add),
                  label: const Text('Get Crop Suggestion'),
                ),
              ],
            )
          else
            ...activeCrops.take(4).map((crop) {
              final cropName =
                  (crop['crop'] ?? crop['name'] ?? 'Crop').toString();
              final stage =
                  (crop['stage'] ?? crop['current_stage'] ?? 'Growing').toString();
              final progress = _asDouble(crop['progress']).clamp(0, 100);
              final day = _asInt(crop['current_day']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            cropName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day > 0 ? '$stage - Day $day' : stage,
                      style: TextStyle(color: Colors.blueGrey.shade700),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFertilizerCard(
    BuildContext context, {
    required List<Map<String, dynamic>> fertilizers,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E2F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.science_outlined, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text(
                'Saved Fertilizers',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (fertilizers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                'No fertilizer recommendations saved yet.',
                style: TextStyle(color: Colors.blueGrey.shade700),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: fertilizers.take(8).map((item) {
                final fertilizer =
                    (item['fertilizer'] ?? item['name'] ?? 'Fertilizer')
                        .toString();
                final crop =
                    (item['crop'] ?? item['crop_type'] ?? 'General').toString();

                return Container(
                  constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        fertilizer,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF312E81),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Crop: $crop',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.fertilizerRecommend),
              icon: const Icon(Icons.add),
              label: const Text('Add Fertilizer Advice'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(
    BuildContext context, {
    required Map<String, dynamic> current,
    required List<Map<String, dynamic>> forecast,
    required String weatherUpdated,
  }) {
    final location = (current['location'] ?? 'Unknown location').toString();
    final condition = (current['condition'] ?? 'N/A').toString();
    final temp = _asDouble(current['temperature']);
    final humidity = _asDouble(current['humidity']);
    final wind = _asDouble(current['wind_speed']);
    final visibility = _asDouble(current['visibility']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x402563EB),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.cloud_outlined, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Live Weather',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              _buildLiveBadge(
                label: weatherUpdated,
                color: Colors.white.withValues(alpha: 0.22),
                textColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${temp.toStringAsFixed(0)} C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            condition,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            location,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _weatherMetric('Humidity', '${humidity.toStringAsFixed(0)}%'),
              ),
              Expanded(
                child: _weatherMetric('Wind', '${wind.toStringAsFixed(0)} km/h'),
              ),
              Expanded(
                child: _weatherMetric(
                  'Visibility',
                  '${visibility.toStringAsFixed(0)} km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 12),
          Text(
            '7-Day Forecast',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (forecast.isEmpty)
            Text(
              'Forecast is not available right now.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            )
          else
            ...forecast.take(5).map((day) {
              final dayName = (day['day'] ?? 'Day').toString();
              final dayCondition = (day['condition'] ?? 'N/A').toString();
              final high = _asDouble(day['high']);
              final low = _asDouble(day['low']);

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 90,
                      child: Text(
                        dayName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        dayCondition,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${high.toStringAsFixed(0)} / ${low.toStringAsFixed(0)} C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _weatherMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsivePanels(
    BuildContext context, {
    required double width,
    required List<Map<String, dynamic>> marketFeed,
    required Map<String, dynamic> currentWeather,
    required List<Map<String, dynamic>> forecast,
    required List<Map<String, dynamic>> activeCrops,
    required List<Map<String, dynamic>> fertilizers,
    required String weatherUpdated,
  }) {
    final marketCard = _buildMarketFeedCard(context, marketFeed: marketFeed);
    final weatherCard = _buildWeatherCard(
      context,
      current: currentWeather,
      forecast: forecast,
      weatherUpdated: weatherUpdated,
    );
    final activeCropsCard =
        _buildActiveCropsCard(context, activeCrops: activeCrops);
    final fertilizerCard =
        _buildFertilizerCard(context, fertilizers: fertilizers);

    if (width >= 1360) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 34, child: marketCard),
          const SizedBox(width: 16),
          Expanded(
            flex: 38,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                activeCropsCard,
                const SizedBox(height: 16),
                fertilizerCard,
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(flex: 28, child: weatherCard),
        ],
      );
    }

    if (width >= 900) {
      return Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: marketCard),
              const SizedBox(width: 16),
              Expanded(child: weatherCard),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: activeCropsCard),
              const SizedBox(width: 16),
              Expanded(child: fertilizerCard),
            ],
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        weatherCard,
        const SizedBox(height: 14),
        marketCard,
        const SizedBox(height: 14),
        activeCropsCard,
        const SizedBox(height: 14),
        fertilizerCard,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        if (controller.isLoading &&
            controller.weather.isEmpty &&
            controller.snapshot.isEmpty) {
          return const LoadingState(label: 'Loading dashboard...');
        }

        final weather = _asMap(controller.weather);
        final current = _asMap(weather['current']);
        final forecast = _asList(weather['forecast']);

        final snapshot = _asMap(controller.snapshot);
        final cropReport = _asMap(snapshot['crop_plan']);
        final cropData = _asMap(cropReport['data']);
        final activeCrops = _asList(cropData['crops']);
        final fertilizers = _asList(cropData['fertilizers']);

        final profitReport = _asMap(snapshot['profit']);
        final profitData = _asMap(profitReport['data']);

        final totalRevenue = _asDouble(profitData['total_revenue']);
        final totalExpenses = _asDouble(profitData['total_expenses']);
        final netProfit = _asDouble(profitData['net_profit']);
        final roi = _asDouble(profitData['roi']);

        final marketReport = _asMap(snapshot['market']);
        final marketData = _asMap(marketReport['data']);
        final marketFeed = _asList(marketData['prices']);

        final weatherUpdated = _weatherUpdatedLabel(weather, controller);
        final marketUpdated = _marketUpdatedLabel(marketData, controller);

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFF3F8F3), Color(0xFFEAF4EC), Color(0xFFF3F7FD)],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: controller.loadDashboard,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    _buildHeader(
                      context,
                      width: width,
                      marketUpdated: marketUpdated,
                      weatherUpdated: weatherUpdated,
                    ),
                    const SizedBox(height: 16),
                    _buildProfitBar(
                      revenue: totalRevenue,
                      expenses: totalExpenses,
                      netProfit: netProfit,
                      roi: roi,
                    ),
                    const SizedBox(height: 16),
                    _buildResponsivePanels(
                      context,
                      width: width,
                      marketFeed: marketFeed,
                      currentWeather: current,
                      forecast: forecast,
                      activeCrops: activeCrops,
                      fertilizers: fertilizers,
                      weatherUpdated: weatherUpdated,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
