import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _villageController = TextEditingController();
  final _pincodeController = TextEditingController();

  Timer? _pincodeDebounce;

  Map<String, List<String>> _statesDistricts = <String, List<String>>{};
  List<String> _states = <String>[];
  List<String> _districts = <String>[];
  List<String> _villages = <String>[];

  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedVillage;

  bool _isLoadingLocationConfig = true;
  bool _isLookingUpPincode = false;
  bool _pincodeStatusIsError = false;
  String? _locationConfigStatus;
  String? _pincodeStatus;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _lastShownSuccessMessage;

  @override
  void initState() {
    super.initState();
    _loadLocationConfig();
    _pincodeController.addListener(_onPincodeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthController>().clearMessages();
    });
  }

  void _showSuccessToastIfNeeded(AuthController auth) {
    final message = auth.successMessage;
    if (message == null || message.trim().isEmpty) {
      return;
    }

    if (message == _lastShownSuccessMessage) {
      return;
    }

    _lastShownSuccessMessage = message;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
        ),
      );

      auth.clearMessages();
    });
  }

  String _normalizeLocation(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String? _findBestLocationMatch(String value, List<String> options) {
    if (value.trim().isEmpty || options.isEmpty) {
      return null;
    }

    final normalizedInput = _normalizeLocation(value);

    for (final option in options) {
      final normalizedOption = _normalizeLocation(option);
      if (normalizedOption == normalizedInput ||
          normalizedOption.contains(normalizedInput) ||
          normalizedInput.contains(normalizedOption)) {
        return option;
      }
    }

    return null;
  }

  void _syncDistrictsForState({String? preferredDistrict}) {
    final state = _selectedState;
    final options = state == null
        ? <String>[]
        : List<String>.from(_statesDistricts[state] ?? const <String>[]);
    options.sort();
    _districts = options;

    if (preferredDistrict != null) {
      _selectedDistrict = _findBestLocationMatch(preferredDistrict, _districts);
    } else if (!_districts.contains(_selectedDistrict)) {
      _selectedDistrict = null;
    }

    _stateController.text = _selectedState ?? '';
    _districtController.text = _selectedDistrict ?? '';
  }

  Future<void> _loadLocationConfig() async {
    setState(() {
      _isLoadingLocationConfig = true;
      _locationConfigStatus = null;
    });

    final result = await _authService.fetchRegisterLocationConfig();
    if (!mounted) return;

    var data = result.data ?? <String, List<String>>{};
    if (data.isEmpty) {
      data = <String, List<String>>{
        for (final state in AppConfig.defaultStates) state: <String>[],
      };
    }

    final states = data.keys.toList()..sort();
    var state = _selectedState;
    if (state == null || !states.contains(state)) {
      state = states.isNotEmpty ? states.first : null;
    }

    setState(() {
      _statesDistricts = data;
      _states = states;
      _selectedState = state;
      _syncDistrictsForState();
      _locationConfigStatus = result.isSuccess
          ? null
          : 'Could not load full location list from server. You can still register manually.';
      _isLoadingLocationConfig = false;
    });
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    _pincodeDebounce?.cancel();

    if (pincode.isEmpty || pincode.length < 6) {
      if (_pincodeStatus != null || _isLookingUpPincode) {
        setState(() {
          _pincodeStatus = null;
          _pincodeStatusIsError = false;
          _isLookingUpPincode = false;
        });
      }
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      setState(() {
        _pincodeStatus = 'Please enter a valid 6-digit pincode';
        _pincodeStatusIsError = true;
      });
      return;
    }

    _pincodeDebounce = Timer(const Duration(milliseconds: 500), () {
      _lookupPincode(pincode);
    });
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() {
      _isLookingUpPincode = true;
      _pincodeStatus = 'Fetching location for pincode...';
      _pincodeStatusIsError = false;
    });

    final result = await _authService.lookupPincode(pincode);
    if (!mounted) return;

    if (!result.isSuccess || result.data == null) {
      setState(() {
        _isLookingUpPincode = false;
        _pincodeStatus = result.error ?? 'Unable to fetch pincode details';
        _pincodeStatusIsError = true;
        _villages = <String>[];
        _selectedVillage = null;
        _villageController.clear();
      });
      return;
    }

    final location = result.data!;
    final matchedState = _findBestLocationMatch(location.state, _states);

    setState(() {
      if (matchedState != null) {
        _selectedState = matchedState;
      }

      _syncDistrictsForState(preferredDistrict: location.district);

      final villages = location.villages.toSet().toList(growable: false)
        ..sort();
      _villages = villages;

      if (_villages.length == 1) {
        _selectedVillage = _villages.first;
        _villageController.text = _selectedVillage!;
      } else {
        _selectedVillage = null;
        _villageController.clear();
      }

      _isLookingUpPincode = false;
      _pincodeStatus = location.message;
      _pincodeStatusIsError = false;
    });
  }

  @override
  void dispose() {
    _pincodeDebounce?.cancel();
    _pincodeController.removeListener(_onPincodeChanged);
    _nameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final auth = context.read<AuthController>();
    if (Validators.email(_emailController.text.trim()) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email before sending OTP')),
      );
      return;
    }

    await auth.sendRegistrationOtp(_emailController.text.trim());
  }

  Future<void> _verifyOtp() async {
    await context.read<AuthController>().verifyRegistrationOtp(
      _otpController.text.trim(),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final stateValue = (_selectedState ?? _stateController.text.trim()).trim();
    final districtValue =
      (_selectedDistrict ?? _districtController.text.trim()).trim();
    final villageValue =
      (_selectedVillage ?? _villageController.text.trim()).trim();

    final auth = context.read<AuthController>();
    if (!auth.registerOtpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verify OTP before registering')),
      );
      return;
    }

    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      phone: _phoneController.text.trim(),
      state: stateValue,
      district: districtValue,
      village: villageValue,
      pincode: _pincodeController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FBFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD5E4DC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD5E4DC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1F7A4C), width: 1.4),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFFFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDBE9E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F7A4C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: const Color(0xFF1F7A4C)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF103026),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasStateOptions = _states.isNotEmpty;
    final hasDistrictOptions = _districts.isNotEmpty;
    final hasVillageOptions = _villages.isNotEmpty;
    final statusColor = _pincodeStatusIsError
        ? Theme.of(context).colorScheme.error
        : Colors.green.shade700;

    return Consumer<AuthController>(
      builder: (context, auth, _) {
        _showSuccessToastIfNeeded(auth);

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFFEAF9F0),
                  Color(0xFFE0F0EA),
                  Color(0xFFDCE9FF),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: -90,
                    right: -70,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F7A4C).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -120,
                    left: -80,
                    child: Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4D8DFF).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, AppRoutes.login),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('Back to login'),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Create Premium Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF102A1C),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Join Smart Farming with live weather, prices, and personalized insights.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B6158),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: const Color(0xFFD4E5DC),
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.07),
                                      blurRadius: 30,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    if (auth.errorMessage != null)
                                      ErrorBanner(message: auth.errorMessage!),
                                    if (_isLoadingLocationConfig)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: LinearProgressIndicator(minHeight: 2),
                                      ),
                                    if (_locationConfigStatus != null)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.orange.shade200,
                                          ),
                                        ),
                                        child: Text(_locationConfigStatus!),
                                      ),
                                    _sectionCard(
                                      title: 'Personal Information',
                                      icon: Icons.person_outline_rounded,
                                      children: <Widget>[
                                        TextFormField(
                                          controller: _nameController,
                                          validator: (v) => Validators.requiredField(
                                            v,
                                            label: 'Name',
                                          ),
                                          decoration: _fieldDecoration(
                                            label: 'Full Name',
                                            hint: 'Enter your full name',
                                            icon: Icons.badge_outlined,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          validator: Validators.phone,
                                          decoration: _fieldDecoration(
                                            label: 'Phone Number',
                                            hint: '10-digit mobile number',
                                            icon: Icons.call_outlined,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          validator: Validators.email,
                                          decoration: _fieldDecoration(
                                            label: 'Email Address',
                                            hint: 'farmer@email.com',
                                            icon: Icons.alternate_email_rounded,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final narrow = constraints.maxWidth < 640;
                                            final otpField = TextFormField(
                                              controller: _otpController,
                                              keyboardType: TextInputType.number,
                                              inputFormatters: <TextInputFormatter>[
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              validator: (v) =>
                                                  Validators.requiredField(
                                                    v,
                                                    label: 'OTP',
                                                  ),
                                              decoration: _fieldDecoration(
                                                label: 'Email OTP',
                                                hint: 'Enter 6-digit OTP',
                                                icon: Icons.verified_user_outlined,
                                              ),
                                            );

                                            if (narrow) {
                                              return Column(
                                                children: <Widget>[
                                                  otpField,
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: auth.isLoading
                                                              ? null
                                                              : _sendOtp,
                                                          child: const Text(
                                                            'Send OTP',
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: auth.isLoading
                                                              ? null
                                                              : _verifyOtp,
                                                          child: const Text(
                                                            'Verify OTP',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            }

                                            return Row(
                                              children: <Widget>[
                                                Expanded(child: otpField),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: auth.isLoading
                                                      ? null
                                                      : _sendOtp,
                                                  child: const Text('Send OTP'),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  onPressed: auth.isLoading
                                                      ? null
                                                      : _verifyOtp,
                                                  child: const Text('Verify OTP'),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    _sectionCard(
                                      title: 'Security',
                                      icon: Icons.shield_outlined,
                                      children: <Widget>[
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          validator: Validators.password,
                                          decoration: _fieldDecoration(
                                            label: 'Password',
                                            hint: 'Create a strong password',
                                            icon: Icons.lock_outline_rounded,
                                            suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller: _confirmPasswordController,
                                          obscureText: _obscureConfirmPassword,
                                          validator: (v) {
                                            if (v != _passwordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                          decoration: _fieldDecoration(
                                            label: 'Confirm Password',
                                            hint: 'Re-enter your password',
                                            icon: Icons.lock_reset_rounded,
                                            suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _obscureConfirmPassword =
                                                      !_obscureConfirmPassword;
                                                });
                                              },
                                              icon: Icon(
                                                _obscureConfirmPassword
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    _sectionCard(
                                      title: 'Location Details',
                                      icon: Icons.location_on_outlined,
                                      children: <Widget>[
                                        TextFormField(
                                          controller: _pincodeController,
                                          keyboardType: TextInputType.number,
                                          maxLength: 6,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: _fieldDecoration(
                                            label: 'Pincode (optional)',
                                            hint: 'Enter 6-digit pincode',
                                            icon: Icons.pin_drop_outlined,
                                          ).copyWith(counterText: ''),
                                        ),
                                        if (_pincodeStatus != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: Text(
                                              _pincodeStatus!,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        if (_isLookingUpPincode)
                                          const Padding(
                                            padding: EdgeInsets.only(bottom: 10),
                                            child: LinearProgressIndicator(
                                              minHeight: 2,
                                            ),
                                          ),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final narrow = constraints.maxWidth < 640;

                                            final stateField = hasStateOptions
                                                ? DropdownButtonFormField<String>(
                                                    key: ValueKey<String>(
                                                      'state-${_selectedState ?? ''}-${_states.length}',
                                                    ),
                                                    initialValue: _selectedState,
                                                    isExpanded: true,
                                                    menuMaxHeight: 360,
                                                    items: _states
                                                        .map(
                                                          (state) => DropdownMenuItem<
                                                              String>(
                                                            value: state,
                                                            child: Text(state),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (value) {
                                                      if (value == null) return;
                                                      setState(() {
                                                        _selectedState = value;
                                                        _syncDistrictsForState();
                                                        _selectedVillage = null;
                                                        _villages = <String>[];
                                                        _villageController.clear();
                                                      });
                                                    },
                                                    validator: (value) =>
                                                        Validators.requiredField(
                                                      value,
                                                      label: 'State',
                                                    ),
                                                    decoration: _fieldDecoration(
                                                      label: 'State',
                                                      icon: Icons.map_outlined,
                                                    ),
                                                  )
                                                : TextFormField(
                                                    controller: _stateController,
                                                    validator: (v) =>
                                                        Validators.requiredField(
                                                      v,
                                                      label: 'State',
                                                    ),
                                                    decoration: _fieldDecoration(
                                                      label: 'State',
                                                      icon: Icons.map_outlined,
                                                    ),
                                                  );

                                            final districtField = hasDistrictOptions
                                                ? DropdownButtonFormField<String>(
                                                    key: ValueKey<String>(
                                                      'district-${_selectedState ?? ''}-${_selectedDistrict ?? ''}-${_districts.length}',
                                                    ),
                                                    initialValue: _selectedDistrict,
                                                    isExpanded: true,
                                                    menuMaxHeight: 360,
                                                    items: _districts
                                                        .map(
                                                          (district) =>
                                                              DropdownMenuItem<
                                                                  String>(
                                                            value: district,
                                                            child:
                                                                Text(district),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _selectedDistrict = value;
                                                        _districtController.text =
                                                            value ?? '';
                                                      });
                                                    },
                                                    validator: (value) =>
                                                        Validators.requiredField(
                                                      value,
                                                      label: 'District',
                                                    ),
                                                    decoration: _fieldDecoration(
                                                      label: 'District',
                                                      icon:
                                                          Icons.location_city_outlined,
                                                    ),
                                                  )
                                                : TextFormField(
                                                    controller:
                                                        _districtController,
                                                    validator: (v) =>
                                                        Validators.requiredField(
                                                      v,
                                                      label: 'District',
                                                    ),
                                                    decoration: _fieldDecoration(
                                                      label: 'District',
                                                      icon:
                                                          Icons.location_city_outlined,
                                                    ),
                                                  );

                                            if (narrow) {
                                              return Column(
                                                children: <Widget>[
                                                  stateField,
                                                  const SizedBox(height: 10),
                                                  districtField,
                                                ],
                                              );
                                            }

                                            return Row(
                                              children: <Widget>[
                                                Expanded(child: stateField),
                                                const SizedBox(width: 10),
                                                Expanded(child: districtField),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        if (hasVillageOptions)
                                          DropdownButtonFormField<String>(
                                            key: ValueKey<String>(
                                              'village-${_selectedVillage ?? ''}-${_villages.length}',
                                            ),
                                            initialValue: _selectedVillage,
                                            isExpanded: true,
                                            menuMaxHeight: 320,
                                            items: _villages
                                                .map(
                                                  (village) =>
                                                      DropdownMenuItem<String>(
                                                    value: village,
                                                    child: Text(village),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedVillage = value;
                                                _villageController.text =
                                                    value ?? '';
                                              });
                                            },
                                            decoration: _fieldDecoration(
                                              label: 'Village (optional)',
                                              icon: Icons.home_work_outlined,
                                            ),
                                          )
                                        else
                                          TextFormField(
                                            controller: _villageController,
                                            decoration: _fieldDecoration(
                                              label: 'Village (optional)',
                                              icon: Icons.home_work_outlined,
                                              hint: 'Enter village or area',
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    PrimaryButton(
                                      label: auth.registerOtpVerified
                                          ? 'Create Account'
                                          : 'Verify OTP to Continue',
                                      isLoading: auth.isLoading,
                                      onPressed: auth.registerOtpVerified
                                          ? _register
                                          : _verifyOtp,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        const Text(
                                          'Already have an account? ',
                                          style: TextStyle(
                                            color: Color(0xFF4F655C),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pushNamed(
                                            context,
                                            AppRoutes.login,
                                          ),
                                          child: const Text('Login'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
