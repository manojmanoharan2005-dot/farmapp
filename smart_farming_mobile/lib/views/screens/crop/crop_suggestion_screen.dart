import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/crop_controller.dart';
import '../../../core/data/crop_profiles.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/primary_button.dart';

class CropSuggestionScreen extends StatefulWidget {
  const CropSuggestionScreen({super.key});

  @override
  State<CropSuggestionScreen> createState() => _CropSuggestionScreenState();
}

class _CropSuggestionScreenState extends State<CropSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _n = TextEditingController(text: '90');
  final _p = TextEditingController(text: '40');
  final _k = TextEditingController(text: '40');
  final _temperature = TextEditingController(text: '26');
  final _humidity = TextEditingController(text: '75');
  final _ph = TextEditingController(text: '6.5');
  final _rainfall = TextEditingController(text: '120');

  late final List<_InputFieldSpec> _inputFields = <_InputFieldSpec>[
    _InputFieldSpec(
      label: 'Nitrogen (N)',
      helper: 'Range: 0-200 mg/kg',
      min: 0,
      max: 200,
      icon: Icons.science_outlined,
      controller: _n,
    ),
    _InputFieldSpec(
      label: 'Phosphorus (P)',
      helper: 'Range: 0-200 mg/kg',
      min: 0,
      max: 200,
      icon: Icons.bubble_chart_outlined,
      controller: _p,
    ),
    _InputFieldSpec(
      label: 'Potassium (K)',
      helper: 'Range: 0-250 mg/kg',
      min: 0,
      max: 250,
      icon: Icons.eco_outlined,
      controller: _k,
    ),
    _InputFieldSpec(
      label: 'Temperature (C)',
      helper: 'Range: 8-44 C',
      min: 8,
      max: 44,
      icon: Icons.device_thermostat_outlined,
      controller: _temperature,
    ),
    _InputFieldSpec(
      label: 'Humidity (%)',
      helper: 'Range: 10-100%',
      min: 10,
      max: 100,
      icon: Icons.water_drop_outlined,
      controller: _humidity,
    ),
    _InputFieldSpec(
      label: 'Soil pH',
      helper: 'Range: 3.0-10.0',
      min: 3,
      max: 10,
      icon: Icons.tune_outlined,
      controller: _ph,
    ),
    _InputFieldSpec(
      label: 'Annual Rainfall (mm)',
      helper: 'Range: 20-300 mm',
      min: 20,
      max: 300,
      icon: Icons.cloud_outlined,
      controller: _rainfall,
    ),
  ];

  @override
  void dispose() {
    _n.dispose();
    _p.dispose();
    _k.dispose();
    _temperature.dispose();
    _humidity.dispose();
    _ph.dispose();
    _rainfall.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await context.read<CropController>().predict(
      nitrogen: _safeParse(_n.text),
      phosphorus: _safeParse(_p.text),
      potassium: _safeParse(_k.text),
      temperature: _safeParse(_temperature.text),
      humidity: _safeParse(_humidity.text),
      ph: _safeParse(_ph.text),
      rainfall: _safeParse(_rainfall.text),
    );
  }

  double _safeParse(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  double _confidencePercent(Map<String, dynamic> item) {
    final rawConfidence = item['confidence_percentage'];
    if (rawConfidence is num) {
      return rawConfidence.toDouble().clamp(0, 100);
    }

    final rawProbability = item['probability'];
    if (rawProbability is num) {
      final value = rawProbability.toDouble();
      if (value <= 1) {
        return (value * 100).clamp(0, 100);
      }
      return value.clamp(0, 100);
    }

    return 0;
  }

  String _priorityText(Map<String, dynamic> item, double confidence) {
    final value = (item['priority'] ?? '').toString().trim();
    if (value.isNotEmpty) {
      return value;
    }

    if (confidence >= 70) return 'High';
    if (confidence >= 45) return 'Medium';
    return 'Low';
  }

  String? _numberValidator(
    String? value, {
    required String label,
    required double min,
    required double max,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return '$label is required';
    }

    final number = double.tryParse(text);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < min || number > max) {
      return 'Use range $min to $max';
    }

    return null;
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory(
    List<Map<String, dynamic>> predictions,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final item in predictions.take(10)) {
      final rawCrop = (item['name'] ?? item['crop'] ?? '').toString();
      final profile = cropProfileFor(rawCrop);
      grouped.putIfAbsent(profile.category, () => <Map<String, dynamic>>[]);
      grouped[profile.category]!.add(item);
    }

    return grouped;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0F9D58), Color(0xFF18B86A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x260F9D58),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.18),
            ),
            child: const Icon(Icons.energy_savings_leaf, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Premium Crop Suggestion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter soil and weather inputs to get AI recommendations with harvest planning.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm(CropController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE8DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.tune, color: Color(0xFF168A50)),
              SizedBox(width: 8),
              Text(
                'Soil & Weather Inputs',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 520;
              final itemWidth = isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _inputFields.map((field) {
                  return SizedBox(
                    width: itemWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          controller: field.controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) => _numberValidator(
                            value,
                            label: field.label,
                            min: field.min,
                            max: field.max,
                          ),
                          decoration: InputDecoration(
                            labelText: field.label,
                            prefixIcon: Icon(field.icon),
                            filled: true,
                            fillColor: const Color(0xFFF8FBF8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          field.helper,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Get Premium Crop Recommendations',
            isLoading: controller.isLoading,
            onPressed: _predict,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> item) {
    final rawCrop = (item['name'] ?? item['crop'] ?? '').toString();
    final normalizedKey = normalizeCropKey(rawCrop);
    final profile = cropProfileFor(rawCrop);
    final confidence = _confidencePercent(item);
    final priority = _priorityText(item, confidence);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE8DF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFEAF7EE),
                ),
                child: Icon(profile.icon, color: const Color(0xFF14834B)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10211A),
                      ),
                    ),
                    Text(
                      profile.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFF1EBF67),
                ),
                child: Text(
                  '${confidence.toStringAsFixed(0)}% Match',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _metricChip(Icons.calendar_month_outlined, profile.season),
              _metricChip(
                Icons.timelapse_outlined,
                '${profile.durationDays} days',
              ),
              _metricChip(Icons.water_drop_outlined, profile.waterNeed),
              _metricChip(Icons.flag_outlined, 'Priority: $priority'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.startGrowing,
                  arguments: <String, dynamic>{
                    'crop': normalizedKey,
                    'cropDisplay': profile.displayName,
                    'probability': confidence,
                    'durationDays': profile.durationDays,
                    'season': profile.season,
                    'waterNeed': profile.waterNeed,
                  },
                );
              },
              icon: const Icon(Icons.agriculture_outlined),
              label: const Text('Open Harvest Planner'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF4F9F4),
        border: Border.all(color: const Color(0xFFDFEDE0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF157246)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14432B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(List<Map<String, dynamic>> predictions) {
    final grouped = _groupByCategory(predictions);
    final ordered = <String>[
      ...cropCategoryOrder.where(grouped.containsKey),
      ...grouped.keys.where((key) => !cropCategoryOrder.contains(key)),
    ];

    if (ordered.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCEADB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.auto_awesome, color: Color(0xFF1A8E52)),
              SizedBox(width: 8),
              Text(
                'Premium Recommendations',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...ordered.map((category) {
            final items = grouped[category] ?? const <Map<String, dynamic>>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 12),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map(_buildRecommendationCard),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CropController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Crop Suggestion')),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFFF2F8F2),
                  Color(0xFFE7F2EA),
                  Color(0xFFF3F7F4),
                ],
              ),
            ),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    _buildHeader(),
                    if (controller.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      ErrorBanner(message: controller.errorMessage!),
                    ],
                    _buildInputForm(controller),
                    if (controller.isLoading) ...<Widget>[
                      const SizedBox(height: 14),
                      const LoadingState(label: 'Generating premium suggestions...'),
                    ],
                    if (controller.predictions.isNotEmpty)
                      _buildRecommendations(controller.predictions),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InputFieldSpec {
  const _InputFieldSpec({
    required this.label,
    required this.helper,
    required this.min,
    required this.max,
    required this.icon,
    required this.controller,
  });

  final String label;
  final String helper;
  final double min;
  final double max;
  final IconData icon;
  final TextEditingController controller;
}
