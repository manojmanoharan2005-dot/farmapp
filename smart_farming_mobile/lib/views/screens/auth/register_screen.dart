import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLocationConfig();
    _pincodeController.addListener(_onPincodeChanged);
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
        return Scaffold(
          appBar: AppBar(title: const Text('Register')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (auth.errorMessage != null)
                          ErrorBanner(message: auth.errorMessage!),
                        if (_isLoadingLocationConfig)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        if (_locationConfigStatus != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(_locationConfigStatus!),
                          ),
                        if (auth.successMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(auth.successMessage!),
                          ),
                        AppTextField(
                          controller: _nameController,
                          label: 'Full name',
                          validator: (v) =>
                              Validators.requiredField(v, label: 'Name'),
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 540;

                            if (narrow) {
                              return Column(
                                children: <Widget>[
                                  AppTextField(
                                    controller: _otpController,
                                    label: 'OTP',
                                    validator: (v) =>
                                        Validators.requiredField(v, label: 'OTP'),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _sendOtp,
                                      child: const Text('Send OTP'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _verifyOtp,
                                      child: const Text('Verify'),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: <Widget>[
                                Expanded(
                                  child: AppTextField(
                                    controller: _otpController,
                                    label: 'OTP',
                                    validator: (v) =>
                                        Validators.requiredField(v, label: 'OTP'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _sendOtp,
                                  child: const Text('Send OTP'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _verifyOtp,
                                  child: const Text('Verify'),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: true,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm password',
                          obscureText: true,
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 10),
                        if (hasStateOptions)
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'state-${_selectedState ?? ''}-${_states.length}',
                            ),
                            initialValue: _selectedState,
                            isExpanded: true,
                            menuMaxHeight: 360,
                            items: _states
                                .map(
                                  (state) => DropdownMenuItem<String>(
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
                                Validators.requiredField(value, label: 'State'),
                            decoration: const InputDecoration(labelText: 'State'),
                          )
                        else
                          AppTextField(
                            controller: _stateController,
                            label: 'State',
                            validator: (v) =>
                                Validators.requiredField(v, label: 'State'),
                          ),
                        const SizedBox(height: 10),
                        if (hasDistrictOptions)
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'district-${_selectedState ?? ''}-${_selectedDistrict ?? ''}-${_districts.length}',
                            ),
                            initialValue: _selectedDistrict,
                            isExpanded: true,
                            menuMaxHeight: 360,
                            items: _districts
                                .map(
                                  (district) => DropdownMenuItem<String>(
                                    value: district,
                                    child: Text(district),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDistrict = value;
                                _districtController.text = value ?? '';
                              });
                            },
                            validator: (value) =>
                                Validators.requiredField(value, label: 'District'),
                            decoration:
                                const InputDecoration(labelText: 'District'),
                          )
                        else
                          AppTextField(
                            controller: _districtController,
                            label: 'District',
                            validator: (v) =>
                                Validators.requiredField(v, label: 'District'),
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
                                  (village) => DropdownMenuItem<String>(
                                    value: village,
                                    child: Text(village),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVillage = value;
                                _villageController.text = value ?? '';
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Village (optional)',
                            ),
                          )
                        else
                          AppTextField(
                            controller: _villageController,
                            label: 'Village (optional)',
                          ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Pincode (optional)',
                            hintText: 'Enter 6-digit pincode',
                            counterText: '',
                          ),
                        ),
                        if (_pincodeStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              _pincodeStatus!,
                              style: TextStyle(color: statusColor, fontSize: 12),
                            ),
                          ),
                        if (_isLookingUpPincode)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          label: auth.registerOtpVerified
                              ? 'Register'
                              : 'Verify OTP to Continue',
                          isLoading: auth.isLoading,
                          onPressed: auth.registerOtpVerified
                              ? _register
                              : _verifyOtp,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.login),
                          child: const Text('Already have an account? Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
