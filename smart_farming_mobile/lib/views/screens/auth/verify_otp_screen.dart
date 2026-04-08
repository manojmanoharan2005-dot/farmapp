import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final auth = context.read<AuthController>();
    final success = await auth.verifyForgotOtp(_otpController.text.trim());

    if (!mounted) return;

    if (success) {
      Navigator.pushNamed(context, AppRoutes.resetPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Verify OTP')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (auth.errorMessage != null)
                    ErrorBanner(message: auth.errorMessage!),
                  Text('OTP sent to: ${auth.pendingIdentifier}'),
                  const SizedBox(height: 10),
                  AppTextField(controller: _otpController, label: 'Enter OTP'),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Verify OTP',
                    isLoading: auth.isLoading,
                    onPressed: _verify,
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
