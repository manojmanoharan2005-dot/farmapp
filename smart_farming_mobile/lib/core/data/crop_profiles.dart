import 'package:flutter/material.dart';

class CropProfile {
  const CropProfile({
    required this.key,
    required this.displayName,
    required this.category,
    required this.season,
    required this.durationDays,
    required this.waterNeed,
    required this.estimatedYield,
    required this.estimatedProfit,
    required this.icon,
    required this.taskTimeline,
  });

  final String key;
  final String displayName;
  final String category;
  final String season;
  final int durationDays;
  final String waterNeed;
  final String estimatedYield;
  final String estimatedProfit;
  final IconData icon;
  final List<String> taskTimeline;
}

const List<String> cropCategoryOrder = <String>[
  'Grains & Cereals',
  'Pulses & Vegetables',
  'Fruits',
  'Commercial Crops',
  'Other Crops',
];

String normalizeCropKey(String input) {
  return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String cropDisplayName(String rawName) {
  final profile = cropProfileFor(rawName);
  return profile.displayName;
}

CropProfile cropProfileFor(String rawName) {
  final key = normalizeCropKey(rawName);
  final profile = _knownCropProfiles[key];
  if (profile != null) {
    return profile;
  }

  return CropProfile(
    key: key.isEmpty ? 'crop' : key,
    displayName: _humanizeCropName(rawName),
    category: 'Other Crops',
    season: 'Region specific',
    durationDays: 90,
    waterNeed: 'Medium',
    estimatedYield: '1800 kg/ha',
    estimatedProfit: 'Rs 45,000/ha',
    icon: Icons.spa_outlined,
    taskTimeline: const <String>[
      'Land preparation and soil testing',
      'Seed selection and sowing',
      'Nutrient and irrigation scheduling',
      'Pest and disease scouting',
      'Harvest readiness check',
    ],
  );
}

String _humanizeCropName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'Unknown Crop';
  }

  final splitCamel = trimmed.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  final normalized = splitCamel.replaceAll(RegExp(r'[_-]+'), ' ');
  final words = normalized
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .toList();

  return words.join(' ');
}

const Map<String, CropProfile> _knownCropProfiles = <String, CropProfile>{
  'rice': CropProfile(
    key: 'rice',
    displayName: 'Rice',
    category: 'Grains & Cereals',
    season: 'Kharif',
    durationDays: 120,
    waterNeed: 'High',
    estimatedYield: '2500 kg/ha',
    estimatedProfit: 'Rs 75,000/ha',
    icon: Icons.grass_outlined,
    taskTimeline: <String>[
      'Prepare field and level soil',
      'Nursery sowing and transplanting',
      'Split fertilizer application',
      'Water depth and weed control',
      'Grain maturity and harvest',
    ],
  ),
  'wheat': CropProfile(
    key: 'wheat',
    displayName: 'Wheat',
    category: 'Grains & Cereals',
    season: 'Rabi',
    durationDays: 130,
    waterNeed: 'Medium',
    estimatedYield: '3000 kg/ha',
    estimatedProfit: 'Rs 68,000/ha',
    icon: Icons.agriculture_outlined,
    taskTimeline: <String>[
      'Prepare seed bed and sow',
      'Crown root irrigation',
      'Nitrogen top dressing',
      'Flowering irrigation and monitoring',
      'Harvest at golden stage',
    ],
  ),
  'maize': CropProfile(
    key: 'maize',
    displayName: 'Maize',
    category: 'Grains & Cereals',
    season: 'Kharif/Rabi',
    durationDays: 100,
    waterNeed: 'Medium',
    estimatedYield: '2800 kg/ha',
    estimatedProfit: 'Rs 62,000/ha',
    icon: Icons.grain,
    taskTimeline: <String>[
      'Land preparation and sowing',
      'Gap filling and thinning',
      'Weed management',
      'Nitrogen split and pest watch',
      'Cob maturity harvest',
    ],
  ),
  'cotton': CropProfile(
    key: 'cotton',
    displayName: 'Cotton',
    category: 'Commercial Crops',
    season: 'Kharif',
    durationDays: 180,
    waterNeed: 'Medium',
    estimatedYield: '2200 kg/ha',
    estimatedProfit: 'Rs 95,000/ha',
    icon: Icons.energy_savings_leaf_outlined,
    taskTimeline: <String>[
      'Ridge preparation and sowing',
      'Thinning and early fertilizer',
      'Square and boll monitoring',
      'Pest scouting for bollworm',
      'Multi-pick harvest schedule',
    ],
  ),
  'jute': CropProfile(
    key: 'jute',
    displayName: 'Jute',
    category: 'Commercial Crops',
    season: 'Kharif',
    durationDays: 120,
    waterNeed: 'High',
    estimatedYield: '2400 kg/ha',
    estimatedProfit: 'Rs 58,000/ha',
    icon: Icons.forest_outlined,
    taskTimeline: <String>[
      'Prepare field with fine tilth',
      'Sowing and thinning',
      'Nitrogen and weed operation',
      'Stem growth monitoring',
      'Cutting and retting prep',
    ],
  ),
  'banana': CropProfile(
    key: 'banana',
    displayName: 'Banana',
    category: 'Fruits',
    season: 'Year-round',
    durationDays: 300,
    waterNeed: 'High',
    estimatedYield: '35000 kg/ha',
    estimatedProfit: 'Rs 1,25,000/ha',
    icon: Icons.eco_outlined,
    taskTimeline: <String>[
      'Pit preparation and planting',
      'Drip and mulch setup',
      'Desuckering and fertigation',
      'Propping and bunch care',
      'Maturity grading and harvest',
    ],
  ),
  'apple': CropProfile(
    key: 'apple',
    displayName: 'Apple',
    category: 'Fruits',
    season: 'Temperate cycle',
    durationDays: 365,
    waterNeed: 'Medium',
    estimatedYield: '18000 kg/ha',
    estimatedProfit: 'Rs 1,40,000/ha',
    icon: Icons.apple,
    taskTimeline: <String>[
      'Dormancy pruning',
      'Pre-bloom nutrition',
      'Fruit thinning and protection',
      'Color and sugar monitoring',
      'Harvest and storage planning',
    ],
  ),
  'orange': CropProfile(
    key: 'orange',
    displayName: 'Orange',
    category: 'Fruits',
    season: 'Winter harvest',
    durationDays: 240,
    waterNeed: 'Medium',
    estimatedYield: '16000 kg/ha',
    estimatedProfit: 'Rs 1,10,000/ha',
    icon: Icons.circle_outlined,
    taskTimeline: <String>[
      'Pruning and basin management',
      'Irrigation and micronutrients',
      'Fruit set monitoring',
      'Pest and disease control',
      'Harvest and grading',
    ],
  ),
  'papaya': CropProfile(
    key: 'papaya',
    displayName: 'Papaya',
    category: 'Fruits',
    season: 'Year-round',
    durationDays: 270,
    waterNeed: 'Medium',
    estimatedYield: '45000 kg/ha',
    estimatedProfit: 'Rs 1,30,000/ha',
    icon: Icons.spa,
    taskTimeline: <String>[
      'Raise healthy seedlings',
      'Transplant and support setup',
      'Split nutrient schedule',
      'Virus and pest watch',
      'Regular fruit harvest',
    ],
  ),
  'mango': CropProfile(
    key: 'mango',
    displayName: 'Mango',
    category: 'Fruits',
    season: 'Summer harvest',
    durationDays: 365,
    waterNeed: 'Medium',
    estimatedYield: '12000 kg/ha',
    estimatedProfit: 'Rs 1,50,000/ha',
    icon: Icons.local_florist_outlined,
    taskTimeline: <String>[
      'Canopy pruning',
      'Flower induction nutrition',
      'Fruit set and bagging',
      'Disease prevention spray',
      'Harvest and post-harvest care',
    ],
  ),
  'muskmelon': CropProfile(
    key: 'muskmelon',
    displayName: 'Muskmelon',
    category: 'Fruits',
    season: 'Zaid',
    durationDays: 85,
    waterNeed: 'Medium',
    estimatedYield: '15000 kg/ha',
    estimatedProfit: 'Rs 70,000/ha',
    icon: Icons.bubble_chart_outlined,
    taskTimeline: <String>[
      'Raised bed preparation',
      'Direct sowing and thinning',
      'Flowering moisture management',
      'Fruit fly protection',
      'Harvest at aroma stage',
    ],
  ),
  'watermelon': CropProfile(
    key: 'watermelon',
    displayName: 'Watermelon',
    category: 'Fruits',
    season: 'Zaid',
    durationDays: 85,
    waterNeed: 'Medium',
    estimatedYield: '20000 kg/ha',
    estimatedProfit: 'Rs 78,000/ha',
    icon: Icons.waves_outlined,
    taskTimeline: <String>[
      'Bed preparation and sowing',
      'Vine training',
      'Pollination and fruit set',
      'Pest scouting',
      'Maturity test and harvest',
    ],
  ),
  'pomegranate': CropProfile(
    key: 'pomegranate',
    displayName: 'Pomegranate',
    category: 'Fruits',
    season: 'Multiple bahar',
    durationDays: 300,
    waterNeed: 'Low',
    estimatedYield: '12000 kg/ha',
    estimatedProfit: 'Rs 1,35,000/ha',
    icon: Icons.blur_on_outlined,
    taskTimeline: <String>[
      'Pruning and training',
      'Bahar treatment',
      'Drip fertigation',
      'Fruit borer and blight control',
      'Harvest and sorting',
    ],
  ),
  'grapes': CropProfile(
    key: 'grapes',
    displayName: 'Grapes',
    category: 'Fruits',
    season: 'Rabi/Summer',
    durationDays: 365,
    waterNeed: 'Medium',
    estimatedYield: '22000 kg/ha',
    estimatedProfit: 'Rs 1,60,000/ha',
    icon: Icons.scatter_plot_outlined,
    taskTimeline: <String>[
      'Pruning cycle start',
      'Canopy and trellis management',
      'Bunch thinning',
      'Quality and sugar checks',
      'Harvest and packing',
    ],
  ),
  'coconut': CropProfile(
    key: 'coconut',
    displayName: 'Coconut',
    category: 'Commercial Crops',
    season: 'Year-round',
    durationDays: 365,
    waterNeed: 'High',
    estimatedYield: '9000 nuts/ha',
    estimatedProfit: 'Rs 1,20,000/ha',
    icon: Icons.park_outlined,
    taskTimeline: <String>[
      'Pit and basin maintenance',
      'Organic manure application',
      'Irrigation scheduling',
      'Palm pest monitoring',
      'Periodic nut harvest',
    ],
  ),
  'coffee': CropProfile(
    key: 'coffee',
    displayName: 'Coffee',
    category: 'Commercial Crops',
    season: 'Hilly regions',
    durationDays: 365,
    waterNeed: 'Medium',
    estimatedYield: '1800 kg/ha',
    estimatedProfit: 'Rs 1,45,000/ha',
    icon: Icons.local_cafe_outlined,
    taskTimeline: <String>[
      'Shade and pruning schedule',
      'Nutrient management',
      'Berry borer prevention',
      'Ripening observation',
      'Selective cherry picking',
    ],
  ),
  'chickpea': CropProfile(
    key: 'chickpea',
    displayName: 'Chickpea',
    category: 'Pulses & Vegetables',
    season: 'Rabi',
    durationDays: 110,
    waterNeed: 'Low',
    estimatedYield: '1700 kg/ha',
    estimatedProfit: 'Rs 72,000/ha',
    icon: Icons.lens_outlined,
    taskTimeline: <String>[
      'Seed treatment and sowing',
      'Branching stage irrigation',
      'Wilt and pod borer scouting',
      'Flowering moisture support',
      'Dry pod harvest',
    ],
  ),
  'blackgram': CropProfile(
    key: 'blackgram',
    displayName: 'Black Gram',
    category: 'Pulses & Vegetables',
    season: 'Kharif/Rabi',
    durationDays: 75,
    waterNeed: 'Low',
    estimatedYield: '1100 kg/ha',
    estimatedProfit: 'Rs 58,000/ha',
    icon: Icons.grain_outlined,
    taskTimeline: <String>[
      'Basal dose and sowing',
      'Early weed management',
      'Moisture support irrigation',
      'Pod borer watch',
      'Black pod harvest',
    ],
  ),
  'lentil': CropProfile(
    key: 'lentil',
    displayName: 'Lentil',
    category: 'Pulses & Vegetables',
    season: 'Rabi',
    durationDays: 105,
    waterNeed: 'Low',
    estimatedYield: '1300 kg/ha',
    estimatedProfit: 'Rs 60,000/ha',
    icon: Icons.circle,
    taskTimeline: <String>[
      'Seed inoculation and sowing',
      'First irrigation at branching',
      'Disease and aphid scouting',
      'Pod maturity checks',
      'Harvest and drying',
    ],
  ),
  'kidneybeans': CropProfile(
    key: 'kidneybeans',
    displayName: 'Kidney Beans',
    category: 'Pulses & Vegetables',
    season: 'Rabi/Kharif',
    durationDays: 90,
    waterNeed: 'Medium',
    estimatedYield: '1500 kg/ha',
    estimatedProfit: 'Rs 66,000/ha',
    icon: Icons.blur_circular_outlined,
    taskTimeline: <String>[
      'Sowing with proper spacing',
      'Weed and moisture management',
      'Staking and disease watch',
      'Pod formation support',
      'Dry pod harvest',
    ],
  ),
  'mungbean': CropProfile(
    key: 'mungbean',
    displayName: 'Mung Bean',
    category: 'Pulses & Vegetables',
    season: 'Kharif/Zaid',
    durationDays: 70,
    waterNeed: 'Low',
    estimatedYield: '1000 kg/ha',
    estimatedProfit: 'Rs 52,000/ha',
    icon: Icons.fiber_manual_record,
    taskTimeline: <String>[
      'Quick land preparation',
      'Seed treatment and sowing',
      'Weed control and moisture check',
      'Flowering pest monitoring',
      'Harvest at pod maturity',
    ],
  ),
  'mothbeans': CropProfile(
    key: 'mothbeans',
    displayName: 'Moth Beans',
    category: 'Pulses & Vegetables',
    season: 'Kharif',
    durationDays: 80,
    waterNeed: 'Low',
    estimatedYield: '900 kg/ha',
    estimatedProfit: 'Rs 48,000/ha',
    icon: Icons.fiber_manual_record_outlined,
    taskTimeline: <String>[
      'Dryland seedbed prep',
      'Line sowing and thinning',
      'Rainfed moisture management',
      'Pod borer monitoring',
      'Harvest and drying',
    ],
  ),
  'pigeonpeas': CropProfile(
    key: 'pigeonpeas',
    displayName: 'Pigeon Peas',
    category: 'Pulses & Vegetables',
    season: 'Kharif',
    durationDays: 160,
    waterNeed: 'Low',
    estimatedYield: '1700 kg/ha',
    estimatedProfit: 'Rs 82,000/ha',
    icon: Icons.trip_origin,
    taskTimeline: <String>[
      'Field prep and sowing',
      'Gap filling and staking',
      'Flowering nutrient support',
      'Pod borer management',
      'Pod harvest in batches',
    ],
  ),
};
