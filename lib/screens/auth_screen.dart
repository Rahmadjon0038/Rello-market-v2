import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';

class AuthResult {
  final String name;
  final String phone;
  final String role;

  const AuthResult({
    required this.name,
    required this.phone,
    required this.role,
  });
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final AuthApiService _authApi = AuthApiService();
  late final TabController _tabController;
  final TextEditingController _loginPhoneCtrl = TextEditingController();
  final TextEditingController _loginPasswordCtrl = TextEditingController();
  final TextEditingController _registerFirstCtrl = TextEditingController();
  final TextEditingController _registerLastCtrl = TextEditingController();
  final TextEditingController _registerPhoneCtrl = TextEditingController();
  final TextEditingController _registerCodeCtrl = TextEditingController();
  final TextEditingController _registerPasswordCtrl = TextEditingController();
  final ScrollController _authScrollCtrl = ScrollController();
  Timer? _registerSmsTimer;
  int _registerStep = 0;
  int _registerSmsSecondsLeft = 0;
  bool _isSubmitting = false;
  String? _loginMessage;
  String? _loginError;
  String? _registerMessage;
  String? _registerError;
  String? _registrationToken;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _registerSmsTimer?.cancel();
    _tabController.dispose();
    _loginPhoneCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _registerFirstCtrl.dispose();
    _registerLastCtrl.dispose();
    _registerPhoneCtrl.dispose();
    _registerCodeCtrl.dispose();
    _registerPasswordCtrl.dispose();
    _authScrollCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    const primaryGreen = Color(0xFF1F5A50);

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF1E2E2A),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: primaryGreen,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      enabledBorder: border(primaryGreen.withValues(alpha: 0.22), width: 1.2),
      focusedBorder: border(primaryGreen, width: 1.5),
      errorBorder: border(Colors.redAccent.withValues(alpha: 0.7)),
      focusedErrorBorder: border(Colors.redAccent, width: 1.4),
    );
  }

  String _codeMessage(CodeResponse response) {
    final codeText = response.smsCode == null
        ? ''
        : ' Kod: ${response.smsCode}';
    final expiresText = response.expiresInSeconds == null
        ? ''
        : ' ${response.expiresInSeconds} sekund amal qiladi.';
    return '${response.message}.$codeText$expiresText';
  }

  void _setLoginMessage({String? message, String? error}) {
    setState(() {
      _loginMessage = message;
      _loginError = error;
    });
  }

  void _setRegisterMessage({String? message, String? error}) {
    setState(() {
      _registerMessage = message;
      _registerError = error;
    });
  }

  void _startRegisterSmsTimer(int seconds) {
    _registerSmsTimer?.cancel();
    setState(() => _registerSmsSecondsLeft = seconds);
    if (seconds <= 0) return;

    _registerSmsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_registerSmsSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _registerSmsSecondsLeft = 0);
        return;
      }

      setState(() => _registerSmsSecondsLeft -= 1);
    });
  }

  AuthResult _resultFromSession(AuthSession session) {
    return AuthResult(
      name: session.name,
      phone: session.phone,
      role: session.role,
    );
  }

  Future<void> _login() async {
    if (_isSubmitting) return;
    final phone = _loginPhoneCtrl.text.trim();
    final password = _loginPasswordCtrl.text.trim();
    if (phone.isEmpty || password.isEmpty) {
      _setLoginMessage(error: 'Telefon raqam va parolni kiriting');
      return;
    }
    if (password.length < 6) {
      _setLoginMessage(
        error: "Parol kamida 6 ta belgidan iborat bo'lishi kerak",
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loginError = null;
      _loginMessage = null;
    });

    try {
      final session = await _authApi.login(phone: phone, password: password);
      if (!mounted) return;
      Navigator.of(context).pop(_resultFromSession(session));
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _setLoginMessage(error: error.message);
    } on Object {
      if (!mounted) return;
      _setLoginMessage(error: 'Server bilan bog‘lanib bo‘lmadi');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _goRegisterCodeStep() async {
    if (_isSubmitting) return;
    final phone = _registerPhoneCtrl.text.trim();
    if (phone.isEmpty) {
      _setRegisterMessage(error: 'Telefon raqamni kiriting');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _registerError = null;
      _registerMessage = null;
    });

    try {
      final response = await _authApi.requestRegisterCode(phone: phone);
      if (!mounted) return;
      setState(() {
        _registerStep = 1;
        _registerMessage = _codeMessage(response);
        _registrationToken = null;
      });
      _startRegisterSmsTimer(response.expiresInSeconds ?? 60);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _setRegisterMessage(error: error.message);
    } on Object {
      if (!mounted) return;
      _setRegisterMessage(error: 'Server bilan bog‘lanib bo‘lmadi');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendRegisterCode() async {
    if (_isSubmitting || _registerSmsSecondsLeft > 0) return;
    final phone = _registerPhoneCtrl.text.trim();
    if (phone.isEmpty) {
      _setRegisterMessage(error: 'Telefon raqamni kiriting');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _registerError = null;
      _registerMessage = null;
    });

    try {
      final response = await _authApi.requestRegisterCode(phone: phone);
      if (!mounted) return;
      setState(() {
        _registerMessage = _codeMessage(response);
        _registrationToken = null;
      });
      _startRegisterSmsTimer(response.expiresInSeconds ?? 60);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _setRegisterMessage(error: error.message);
    } on Object {
      if (!mounted) return;
      _setRegisterMessage(error: 'Server bilan bog‘lanib bo‘lmadi');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyRegisterCodeStep() async {
    if (_isSubmitting) return;
    final phone = _registerPhoneCtrl.text.trim();
    final code = _registerCodeCtrl.text.trim();
    if (code.isEmpty) {
      _setRegisterMessage(error: 'SMS kodni kiriting');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _registerError = null;
      _registerMessage = null;
    });

    try {
      final response = await _authApi.verifyRegisterCode(
        phone: phone,
        code: code,
      );
      if (!mounted) return;
      _registerSmsTimer?.cancel();
      setState(() {
        _registerStep = 2;
        _registerSmsSecondsLeft = 0;
        _registrationToken = response.registrationToken;
        _registerMessage = response.expiresInSeconds == null
            ? response.message
            : '${response.message}. Profilni ${response.expiresInSeconds} sekund ichida yakunlang.';
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _setRegisterMessage(error: error.message);
    } on Object {
      if (!mounted) return;
      _setRegisterMessage(error: 'Server bilan bog‘lanib bo‘lmadi');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _completeRegister() async {
    if (_isSubmitting) return;
    final firstName = _registerFirstCtrl.text.trim();
    final lastName = _registerLastCtrl.text.trim();
    final phone = _registerPhoneCtrl.text.trim();
    final password = _registerPasswordCtrl.text.trim();
    final registrationToken = _registrationToken;
    if (firstName.isEmpty || lastName.isEmpty || password.isEmpty) {
      _setRegisterMessage(error: 'Ism, familiya va parolni kiriting');
      return;
    }
    if (registrationToken == null || registrationToken.isEmpty) {
      _setRegisterMessage(error: 'Avval SMS kodni tasdiqlang');
      setState(() => _registerStep = 1);
      return;
    }
    if (password.length < 6) {
      _setRegisterMessage(
        error: "Parol kamida 6 ta belgidan iborat bo'lishi kerak",
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _registerError = null;
    });

    try {
      final session = await _authApi.completeRegister(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        registrationToken: registrationToken,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pop(_resultFromSession(session));
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _setRegisterMessage(error: error.message);
    } on Object {
      if (!mounted) return;
      _setRegisterMessage(error: 'Server bilan bog‘lanib bo‘lmadi');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handlePrimaryAction() {
    if (_tabController.index == 0) {
      _login();
      return;
    }

    if (_registerStep == 0) {
      _goRegisterCodeStep();
      return;
    }

    if (_registerStep == 1) {
      _verifyRegisterCodeStep();
      return;
    }

    _completeRegister();
  }

  String get _primaryButtonText {
    if (_isSubmitting) return 'Kuting...';
    if (_tabController.index == 0) return 'Tizimga kirish';
    if (_registerStep == 0) return 'Davom etish';
    if (_registerStep == 1) return 'Tasdiqlash';
    return "Ro'yxatdan o'tish";
  }

  Future<void> _openForgotPassword() async {
    final result = await Navigator.of(context).push<AuthResult>(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
    if (!mounted || result == null) return;
    Navigator.of(context).pop(result);
  }

  void _keepAuthActionsAboveKeyboard(bool keyboardOpen) {
    if (!keyboardOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_authScrollCtrl.hasClients) return;
      _authScrollCtrl.animateTo(
        _authScrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    _keepAuthActionsAboveKeyboard(keyboardOpen);
    final isCompact = MediaQuery.sizeOf(context).height < 720;
    final topGap = keyboardOpen ? 0.0 : (isCompact ? 4.0 : 10.0);
    final isRegisterFlowStep = _tabController.index == 1 && _registerStep > 0;
    final isLoginTab = _tabController.index == 0;
    final imageHeight = keyboardOpen
        ? 0.0
        : isRegisterFlowStep
        ? (isCompact ? 52.0 : 82.0)
        : (isCompact ? 156.0 : 224.0);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _authScrollCtrl,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 64, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 80,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: topGap),
                        const Text(
                          'Hisobingizga kiring',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        if (!keyboardOpen && !isRegisterFlowStep)
                          SizedBox(height: isCompact ? 6 : 10),
                        if (!keyboardOpen && !isRegisterFlowStep)
                          Image.asset(
                            'assets/auth1.png',
                            height: imageHeight,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          )
                        else if (!keyboardOpen)
                          SizedBox(height: imageHeight),
                        SizedBox(
                          height: keyboardOpen
                              ? 8
                              : isRegisterFlowStep
                              ? (isCompact ? 6 : 8)
                              : (isCompact ? 10 : 18),
                        ),
                        Container(
                          height: 58,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryGreen, width: 1.2),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: primaryGreen,
                            labelStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            indicator: BoxDecoration(
                              color: primaryGreen,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            tabs: const [
                              Tab(text: 'Kirish'),
                              Tab(text: "Ro'yhatdan o'tish"),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: KeyedSubtree(
                            key: ValueKey(
                              'auth-form-${_tabController.index}-$_registerStep',
                            ),
                            child: isLoginTab
                                ? _buildLoginForm()
                                : _buildRegisterForm(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            key: ValueKey(
                              'auth-primary-${_tabController.index}-$_registerStep',
                            ),
                            onPressed: _isSubmitting
                                ? null
                                : _handlePrimaryAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              disabledBackgroundColor: primaryGreen.withValues(
                                alpha: 0.72,
                              ),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: primaryGreen.withValues(alpha: 0.28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _AuthButtonContent(
                              isLoading: _isSubmitting,
                              text: _primaryButtonText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 34),
                color: primaryGreen,
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          TextField(
            controller: _loginPhoneCtrl,
            keyboardType: TextInputType.phone,
            cursorColor: const Color(0xFF1F5A50),
            decoration: _inputDecoration('Telefon raqam'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _loginPasswordCtrl,
            obscureText: true,
            cursorColor: const Color(0xFF1F5A50),
            decoration: _inputDecoration('Parol'),
          ),
          _InlineMessage(message: _loginMessage, error: _loginError),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _openForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1F5A50),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Parolni unutdingizmi?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    final primaryGreen = const Color(0xFF1F5A50);

    if (_registerStep == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            _buildRegisterSteps(),
            const SizedBox(height: 8),
            TextField(
              controller: _registerCodeCtrl,
              keyboardType: TextInputType.number,
              cursorColor: primaryGreen,
              decoration: _inputDecoration('SMS kod'),
            ),
            _buildRegisterSmsStatus(),
            _InlineMessage(message: _registerMessage, error: _registerError),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _goBackToRegisterPhone,
                style: TextButton.styleFrom(
                  foregroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Telefon raqamga qaytish",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_registerStep == 2) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            _buildRegisterSteps(),
            const SizedBox(height: 8),
            TextField(
              controller: _registerFirstCtrl,
              cursorColor: primaryGreen,
              decoration: _inputDecoration('Ism'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _registerLastCtrl,
              cursorColor: primaryGreen,
              decoration: _inputDecoration('Familiya'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _registerPasswordCtrl,
              obscureText: true,
              cursorColor: primaryGreen,
              decoration: _inputDecoration('Parol'),
            ),
            _InlineMessage(message: _registerMessage, error: _registerError),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => setState(() => _registerStep = 1),
                style: TextButton.styleFrom(
                  foregroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'SMS kodga qaytish',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          _buildRegisterSteps(),
          const SizedBox(height: 10),
          TextField(
            controller: _registerPhoneCtrl,
            keyboardType: TextInputType.phone,
            cursorColor: primaryGreen,
            decoration: _inputDecoration('Telefon raqami'),
          ),
          _InlineMessage(message: _registerMessage, error: _registerError),
        ],
      ),
    );
  }

  Widget _buildRegisterSteps() {
    const primaryGreen = Color(0xFF1F5A50);

    return SizedBox(
      height: 34,
      child: Center(
        child: SizedBox(
          width: 210,
          child: Row(
            children: List.generate(5, (slotIndex) {
              if (slotIndex.isOdd) {
                final leftStep = slotIndex ~/ 2;
                final isDone = _registerStep > leftStep;

                return Expanded(
                  child: Container(
                    height: 1.4,
                    color: primaryGreen.withValues(alpha: isDone ? 0.8 : 0.2),
                  ),
                );
              }

              final index = slotIndex ~/ 2;
              final isActive = _registerStep == index;
              final isDone = _registerStep > index;
              final color = isActive || isDone
                  ? primaryGreen
                  : primaryGreen.withValues(alpha: 0.28);

              return Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? primaryGreen : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.4),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterSmsStatus() {
    const primaryGreen = Color(0xFF1F5A50);

    if (_registerSmsSecondsLeft > 0) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 6),
        child: Text(
          'SMS kod $_registerSmsSecondsLeft soniya amal qiladi',
          style: const TextStyle(
            color: primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: _isSubmitting ? null : _resendRegisterCode,
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.only(top: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          "SMS kodni qayta so'rash mumkin",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _goBackToRegisterPhone() {
    _registerSmsTimer?.cancel();
    setState(() {
      _registerStep = 0;
      _registerSmsSecondsLeft = 0;
      _registrationToken = null;
      _registerMessage = null;
      _registerError = null;
    });
  }
}

class _InlineMessage extends StatelessWidget {
  final String? message;
  final String? error;

  const _InlineMessage({this.message, this.error});

  @override
  Widget build(BuildContext context) {
    final text = error ?? message;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final isError = error != null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? Colors.redAccent : const Color(0xFF1F5A50),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _AuthButtonContent extends StatelessWidget {
  final bool isLoading;
  final String text;

  const _AuthButtonContent({required this.isLoading, required this.text});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        SizedBox(width: 10),
        Text(
          'Kuting...',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthApiService _authApi = AuthApiService();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final ScrollController _forgotScrollCtrl = ScrollController();
  int _step = 0;
  bool _isSubmitting = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _forgotScrollCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    const primaryGreen = Color(0xFF1F5A50);

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF1E2E2A),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: primaryGreen,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      enabledBorder: border(primaryGreen.withValues(alpha: 0.22), width: 1.2),
      focusedBorder: border(primaryGreen, width: 1.5),
      errorBorder: border(Colors.redAccent.withValues(alpha: 0.7)),
      focusedErrorBorder: border(Colors.redAccent, width: 1.4),
    );
  }

  String _codeMessage(CodeResponse response) {
    final codeText = response.smsCode == null
        ? ''
        : ' Kod: ${response.smsCode}';
    final expiresText = response.expiresInSeconds == null
        ? ''
        : ' ${response.expiresInSeconds} sekund amal qiladi.';
    return '${response.message}.$codeText$expiresText';
  }

  AuthResult _resultFromSession(AuthSession session) {
    return AuthResult(
      name: session.name,
      phone: session.phone,
      role: session.role,
    );
  }

  void _setMessage({String? message, String? error}) {
    setState(() {
      _message = message;
      _error = error;
    });
  }

  Future<void> _handlePrimaryAction() async {
    if (_isSubmitting) return;
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();
    if (_step == 0) {
      if (phone.isEmpty) {
        _setMessage(error: 'Telefon raqamni kiriting');
        return;
      }

      setState(() {
        _isSubmitting = true;
        _message = null;
        _error = null;
      });
      try {
        final response = await _authApi.requestPasswordResetCode(phone);
        if (!mounted) return;
        setState(() {
          _step = 1;
          _message = _codeMessage(response);
        });
      } on AuthApiException catch (error) {
        if (!mounted) return;
        _setMessage(error: error.message);
      } on Object {
        if (!mounted) return;
        _setMessage(error: 'Server bilan bog‘lanib bo‘lmadi');
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }

    if (code.isEmpty || newPassword.isEmpty) {
      _setMessage(error: 'SMS kod va yangi parolni kiriting');
      return;
    }
    if (newPassword.length < 6) {
      _setMessage(error: "Parol kamida 6 ta belgidan iborat bo'lishi kerak");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final session = await _authApi.verifyPasswordReset(
        phone: phone,
        code: code,
        newPassword: newPassword,
      );
      if (!mounted) return;
      Navigator.of(context).pop(_resultFromSession(session));
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _setMessage(error: error.message);
    } on Object {
      if (!mounted) return;
      _setMessage(error: 'Server bilan bog‘lanib bo‘lmadi');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _keepForgotActionsAboveKeyboard(bool keyboardOpen) {
    if (!keyboardOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_forgotScrollCtrl.hasClients) return;
      _forgotScrollCtrl.animateTo(
        _forgotScrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    _keepForgotActionsAboveKeyboard(keyboardOpen);
    final isCompact = MediaQuery.sizeOf(context).height < 720;
    final topGap = keyboardOpen ? 0.0 : (isCompact ? 4.0 : 10.0);
    final imageHeight = keyboardOpen ? 0.0 : (isCompact ? 172.0 : 238.0);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _forgotScrollCtrl,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 64, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 80,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: topGap),
                        const Text(
                          'Parolni tiklash',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        if (!keyboardOpen) ...[
                          SizedBox(height: isCompact ? 10 : 18),
                          Image.asset(
                            'assets/auth1.png',
                            height: imageHeight,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ],
                        SizedBox(
                          height: keyboardOpen ? 8 : (isCompact ? 16 : 24),
                        ),
                        Column(
                          children: [
                            if (_step == 0)
                              TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                cursorColor: primaryGreen,
                                decoration: _inputDecoration('Telefon raqam'),
                              )
                            else ...[
                              TextField(
                                controller: _codeCtrl,
                                keyboardType: TextInputType.number,
                                cursorColor: primaryGreen,
                                decoration: _inputDecoration('SMS kod'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _newPasswordCtrl,
                                obscureText: true,
                                cursorColor: primaryGreen,
                                decoration: _inputDecoration('Yangi parol'),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () => setState(() => _step = 0),
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryGreen,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    "Telefon raqamni o'zgartirish",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            _InlineMessage(message: _message, error: _error),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : _handlePrimaryAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              disabledBackgroundColor: primaryGreen.withValues(
                                alpha: 0.72,
                              ),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: primaryGreen.withValues(alpha: 0.28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _AuthButtonContent(
                              isLoading: _isSubmitting,
                              text: _step == 0 ? 'Davom etish' : 'Tasdiqlash',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 34),
                color: primaryGreen,
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
