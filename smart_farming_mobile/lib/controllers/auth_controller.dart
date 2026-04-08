import '../services/auth_service.dart';
import 'base_controller.dart';

class AuthController extends BaseController {
  final AuthService _service;

  AuthController(this._service);

  bool _isAuthenticated = false;
  String _pendingIdentifier = '';
  bool _registerOtpVerified = false;

  bool get isAuthenticated => _isAuthenticated;
  String get pendingIdentifier => _pendingIdentifier;
  bool get registerOtpVerified => _registerOtpVerified;

  Future<void> validateSession() async {
    setLoading(true);
    final result = await _service.validateSession();
    _isAuthenticated = result.data ?? false;
    setLoading(false);
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    clearMessages();
    final result = await _service.login(email: email, password: password);
    setLoading(false);

    if (result.isSuccess) {
      _isAuthenticated = true;
      setSuccess('Login successful');
      return true;
    }

    setError(result.error ?? 'Login failed');
    return false;
  }

  Future<bool> sendRegistrationOtp(String email) async {
    setLoading(true);
    clearMessages();
    final result = await _service.sendRegistrationOtp(email);
    setLoading(false);

    if (result.isSuccess) {
      _pendingIdentifier = email;
      _registerOtpVerified = false;
      setSuccess(result.data ?? 'OTP sent');
      return true;
    }

    setError(result.error ?? 'Failed to send OTP');
    return false;
  }

  Future<bool> verifyRegistrationOtp(String otp) async {
    if (_pendingIdentifier.isEmpty) {
      setError('Please send OTP first');
      return false;
    }

    setLoading(true);
    clearMessages();
    final result = await _service.verifyRegistrationOtp(
      email: _pendingIdentifier,
      otp: otp,
    );
    setLoading(false);

    if (result.isSuccess) {
      _registerOtpVerified = true;
      setSuccess(result.data ?? 'OTP verified');
      return true;
    }

    setError(result.error ?? 'OTP verification failed');
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String state,
    required String district,
    String village = '',
    String pincode = '',
  }) async {
    setLoading(true);
    clearMessages();

    final result = await _service.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      phone: phone,
      state: state,
      district: district,
      village: village,
      pincode: pincode,
    );

    setLoading(false);

    if (result.isSuccess) {
      _isAuthenticated = true;
      setSuccess('Registration successful');
      return true;
    }

    setError(result.error ?? 'Registration failed');
    return false;
  }

  Future<bool> requestForgotOtp(String identifier) async {
    setLoading(true);
    clearMessages();
    final result = await _service.requestForgotPasswordOtp(identifier);
    setLoading(false);

    if (result.isSuccess) {
      _pendingIdentifier = identifier;
      setSuccess(result.data ?? 'OTP sent');
      return true;
    }

    setError(result.error ?? 'Unable to send OTP');
    return false;
  }

  Future<bool> verifyForgotOtp(String otp) async {
    setLoading(true);
    clearMessages();
    final result = await _service.verifyForgotPasswordOtp(otp);
    setLoading(false);

    if (result.isSuccess) {
      setSuccess(result.data ?? 'OTP verified');
      return true;
    }

    setError(result.error ?? 'OTP verification failed');
    return false;
  }

  Future<bool> resetPassword(String newPassword) async {
    setLoading(true);
    clearMessages();
    final result = await _service.resetPassword(newPassword);
    setLoading(false);

    if (result.isSuccess) {
      setSuccess(result.data ?? 'Password reset successful');
      return true;
    }

    setError(result.error ?? 'Password reset failed');
    return false;
  }

  Future<void> logout() async {
    setLoading(true);
    await _service.logout();
    _isAuthenticated = false;
    _registerOtpVerified = false;
    _pendingIdentifier = '';
    setLoading(false);
  }
}
