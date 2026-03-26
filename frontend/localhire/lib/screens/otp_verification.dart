import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'complete_profile.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String username;
  final String password;
  final String phone;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.username,
    required this.password,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthService _authService = AuthService();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  late String _verificationId;
  Timer? _timer;
  int _secondsRemaining = 120;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 120;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complete OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyOTP(
        verificationId: _verificationId,
        smsCode: otp,
      );

      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CompleteProfileScreen(
            username: widget.username,
            password: widget.password,
            phone: widget.phone,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      await _authService.sendOTP(
        phone: widget.phone,
        onCodeSent: (newVerificationId) {
          setState(() => _verificationId = newVerificationId);
        },
      );
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP resent successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to resend OTP: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime =
        "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text("Verify OTP",
            style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3DC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock_outline,
                  size: 36, color: Color(0xFFF5B544)),
            ),
            const SizedBox(height: 20),
            const Text("Verify OTP",
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Enter the 6-digit code sent to",
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(widget.phone,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _otpBox(index)),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5B544),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Verify & Proceed",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _canResend ? _resendOtp : null,
              child: Text(
                _canResend
                    ? "Resend OTP"
                    : "Resend OTP $formattedTime",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      _canResend ? Colors.orange.shade600 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      height: 48,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Colors.orange, width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}