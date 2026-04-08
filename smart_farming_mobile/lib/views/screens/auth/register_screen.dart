import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

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

  String _selectedState = AppConfig.defaultStates.first;

  @override
  void dispose() {
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

    final states = AppConfig.defaultStates.toSet().toList(growable: false);
    final stateValue = states.isNotEmpty
        ? _selectedState
        : _stateController.text.trim();

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
      district: _districtController.text.trim(),
      village: _villageController.text.trim(),
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
    final states = AppConfig.defaultStates.toSet().toList(growable: false);
    final hasStateOptions = states.isNotEmpty;
    if (hasStateOptions && !states.contains(_selectedState)) {
      _selectedState = states.first;
    }

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
                            initialValue: _selectedState,
                            items: states
                                .map(
                                  (state) => DropdownMenuItem<String>(
                                    value: state,
                                    child: Text(state),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedState = value);
                            },
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
                        AppTextField(
                          controller: _districtController,
                          label: 'District',
                          validator: (v) =>
                              Validators.requiredField(v, label: 'District'),
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _villageController,
                          label: 'Village (optional)',
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _pincodeController,
                          label: 'Pincode (optional)',
                          keyboardType: TextInputType.number,
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
