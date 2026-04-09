import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/crop_controller.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../core/data/crop_profiles.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';

class StartGrowingScreen extends StatefulWidget {
  const StartGrowingScreen({super.key});

  @override
  State<StartGrowingScreen> createState() => _StartGrowingScreenState();
}

class _StartGrowingScreenState extends State<StartGrowingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropKeyController = TextEditingController();
  final _cropDisplayController = TextEditingController();
  final _startDateController = TextEditingController();
  final _durationController = TextEditingController();
  final _harvestDateController = TextEditingController();
  final _notesController = TextEditingController();

  bool _didInit = false;
  double _matchPercent = 0;
  CropProfile _profile = cropProfileFor('');

  @override
  void initState() {
    super.initState();
    _startDateController.addListener(_syncHarvestDateFromInputs);
    _durationController.addListener(_syncHarvestDateFromInputs);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInit) {
      return;
    }
    _didInit = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    var cropKey = '';
    var cropDisplay = '';
    var durationDays = 0;

    if (args is Map<String, dynamic>) {
      cropKey = normalizeCropKey((args['crop'] ?? '').toString());
      cropDisplay = (args['cropDisplay'] ?? '').toString();
      durationDays = int.tryParse((args['durationDays'] ?? '').toString()) ?? 0;
      _matchPercent = _parseMatchPercent(args['probability']);
    }

    if (cropDisplay.trim().isEmpty) {
      cropDisplay = cropDisplayName(cropKey);
    }

    _profile = cropProfileFor(cropKey.isNotEmpty ? cropKey : cropDisplay);
    _cropKeyController.text = cropKey.isNotEmpty ? cropKey : _profile.key;
    _cropDisplayController.text =
        cropDisplay.trim().isNotEmpty ? cropDisplay : _profile.displayName;

    if (_startDateController.text.isEmpty) {
      final now = DateTime.now();
      _startDateController.text = _formatDate(now);
      _durationController.text =
          (durationDays > 0 ? durationDays : _profile.durationDays).toString();
      _syncHarvestDateFromInputs();
    }
  }

  @override
  void dispose() {
    _cropKeyController.dispose();
    _cropDisplayController.dispose();
    _startDateController.dispose();
    _durationController.dispose();
    _harvestDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  DateTime? _tryParseDate(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  void _syncHarvestDateFromInputs() {
    final startDate = _tryParseDate(_startDateController.text) ?? DateTime.now();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;

    if (duration <= 0) {
      return;
    }

    final harvest = startDate.add(Duration(days: duration));
    final formatted = _formatDate(harvest);
    if (_harvestDateController.text != formatted) {
      _harvestDateController.text = formatted;
    }
  }

  double _parseMatchPercent(dynamic raw) {
    if (raw is num) {
      final value = raw.toDouble();
      if (value <= 1) {
        return (value * 100).clamp(0, 100);
      }
      return value.clamp(0, 100);
    }

    final parsed = double.tryParse(raw?.toString() ?? '');
    if (parsed == null) {
      return 0;
    }

    if (parsed <= 1) {
      return (parsed * 100).clamp(0, 100);
    }
    return parsed.clamp(0, 100);
  }

  String? _dateValidator(String? value) {
    final date = _tryParseDate(value ?? '');
    if (date == null) {
      return 'Use date format YYYY-MM-DD';
    }

    return null;
  }

  String? _durationValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Duration is required';
    }

    final days = int.tryParse(text);
    if (days == null || days < 1 || days > 730) {
      return 'Use duration between 1 and 730 days';
    }

    return null;
  }

  Future<void> _pickStartDate() async {
    final initial = _tryParseDate(_startDateController.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) {
      return;
    }

    _startDateController.text = _formatDate(selected);
    _syncHarvestDateFromInputs();
  }

  List<_ScheduledTask> _buildTaskTimeline() {
    final start = _tryParseDate(_startDateController.text) ?? DateTime.now();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;

    final tasks = _profile.taskTimeline;
    if (tasks.isEmpty || duration <= 0) {
      return <_ScheduledTask>[];
    }

    final spacing = (duration / tasks.length).ceil();

    return tasks.asMap().entries.map((entry) {
      final date = start.add(Duration(days: spacing * entry.key));
      return _ScheduledTask(title: entry.value, dateText: _formatDate(date));
    }).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final controller = context.read<CropController>();
    final success = await controller.saveGrowingPlan(
      cropName: _cropKeyController.text.trim(),
      startDate: _startDateController.text.trim(),
      harvestDate: _harvestDateController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      return;
    }

    await context.read<DashboardController>().loadDashboard();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (route) => false,
    );
  }

  Widget _metricCard({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAF7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDFEDE1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10211A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CropController>(
      builder: (context, controller, _) {
        final timeline = _buildTaskTimeline();

        return Scaffold(
          appBar: AppBar(title: const Text('Harvest Planner')),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFF2F8F2), Color(0xFFEAF3EC)],
              ),
            ),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF0F9D58), Color(0xFF19B86A)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Growing Guide: ${_cropDisplayController.text}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                child: Text(
                                  '${_matchPercent.toStringAsFixed(0)}% Match',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                child: Text(
                                  _profile.season,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        _metricCard(
                          label: 'Expected Yield',
                          value: _profile.estimatedYield,
                        ),
                        const SizedBox(width: 10),
                        _metricCard(
                          label: 'Estimated Profit',
                          value: _profile.estimatedProfit,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (controller.errorMessage != null)
                      ErrorBanner(message: controller.errorMessage!),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDDE8DE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Row(
                            children: <Widget>[
                              Icon(Icons.calendar_today_outlined,
                                  color: Color(0xFF1A8E52)),
                              SizedBox(width: 8),
                              Text(
                                'Harvest Planner',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _cropDisplayController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Crop',
                              prefixIcon: Icon(Icons.spa_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _startDateController,
                            readOnly: true,
                            validator: _dateValidator,
                            onTap: _pickStartDate,
                            decoration: const InputDecoration(
                              labelText: 'Sowing Date (YYYY-MM-DD)',
                              prefixIcon: Icon(Icons.event_outlined),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            validator: _durationValidator,
                            decoration: const InputDecoration(
                              labelText: 'Growth Duration (days)',
                              prefixIcon: Icon(Icons.timelapse_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _harvestDateController,
                            readOnly: true,
                            validator: _dateValidator,
                            decoration: const InputDecoration(
                              labelText: 'Estimated Harvest Date',
                              prefixIcon: Icon(Icons.flag_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              Chip(
                                avatar: const Icon(Icons.water_drop_outlined,
                                    size: 16),
                                label: Text('Water: ${_profile.waterNeed}'),
                              ),
                              Chip(
                                avatar: const Icon(Icons.calendar_month_outlined,
                                    size: 16),
                                label: Text('Season: ${_profile.season}'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDDE8DE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Row(
                            children: <Widget>[
                              Icon(Icons.checklist_rtl_outlined,
                                  color: Color(0xFF1A8E52)),
                              SizedBox(width: 8),
                              Text(
                                'Suggested Task Timeline',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (timeline.isEmpty)
                            Text(
                              'Add valid sowing date and duration to generate timeline.',
                              style: TextStyle(color: Colors.blueGrey.shade700),
                            )
                          else
                            ...timeline.map((task) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFFF8FBF8),
                                  border:
                                      Border.all(color: const Color(0xFFDFEDE1)),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    const Icon(Icons.task_alt,
                                        color: Color(0xFF14834B), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      task.dateText,
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add plot details, reminders, or custom tasks.',
                        prefixIcon: Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Save Plan & Open Dashboard',
                      isLoading: controller.isLoading,
                      onPressed: _save,
                    ),
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

class _ScheduledTask {
  const _ScheduledTask({required this.title, required this.dateText});

  final String title;
  final String dateText;
}
