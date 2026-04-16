import 'package:flutter/material.dart';

class AuthResult {
  final String name;
  final String phone;

  const AuthResult({required this.name, required this.phone});
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  static const _mockSmsCode = '1234';

  late final TabController _tabController;
  final TextEditingController _loginPhoneCtrl = TextEditingController();
  final TextEditingController _loginCodeCtrl = TextEditingController();
  final TextEditingController _registerFirstCtrl = TextEditingController();
  final TextEditingController _registerLastCtrl = TextEditingController();
  final TextEditingController _registerPhoneCtrl = TextEditingController();
  final TextEditingController _registerCodeCtrl = TextEditingController();
  int _registerStep = 0;

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
    _tabController.dispose();
    _loginPhoneCtrl.dispose();
    _loginCodeCtrl.dispose();
    _registerFirstCtrl.dispose();
    _registerLastCtrl.dispose();
    _registerPhoneCtrl.dispose();
    _registerCodeCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration(String label) {
    const primaryGreen = Color(0xFF1F5A50);
    const mutedText = Color(0xFF8A9A97);

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: mutedText),
      floatingLabelStyle: const TextStyle(
        color: primaryGreen,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: const Color(0xFFF6F7F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(primaryGreen.withValues(alpha: 0.12)),
      focusedBorder: border(primaryGreen, width: 1.4),
      errorBorder: border(Colors.redAccent.withValues(alpha: 0.7)),
      focusedErrorBorder: border(Colors.redAccent, width: 1.4),
    );
  }

  void _login() {
    final phone = _loginPhoneCtrl.text.trim();
    final code = _loginCodeCtrl.text.trim();
    if (phone.isEmpty || code.isEmpty) {
      _showMessage("Telefon raqam va SMS kodni kiriting");
      return;
    }
    if (code != _mockSmsCode) {
      _showMessage("Parol xato");
      return;
    }
    _showMessage("Tizimga kirildi");
    Navigator.of(context).pop(AuthResult(name: 'Mock User', phone: phone));
  }

  void _goRegisterCodeStep() {
    if (_registerFirstCtrl.text.trim().isEmpty ||
        _registerLastCtrl.text.trim().isEmpty ||
        _registerPhoneCtrl.text.trim().isEmpty) {
      _showMessage("Barcha ma'lumotlarni kiriting");
      return;
    }
    setState(() => _registerStep = 1);
  }

  void _completeRegister() {
    if (_registerCodeCtrl.text.trim() != _mockSmsCode) {
      _showMessage("Parol xato");
      return;
    }
    final name =
        '${_registerFirstCtrl.text.trim()} ${_registerLastCtrl.text.trim()}';
    _showMessage("Profil yaratildi va tizimga kirildi");
    Navigator.of(
      context,
    ).pop(AuthResult(name: name, phone: _registerPhoneCtrl.text.trim()));
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

    _completeRegister();
  }

  String get _primaryButtonText {
    if (_tabController.index == 0) return 'Tizimga kirish';
    if (_registerStep == 0) return 'Davom etish';
    return 'Profil yaratish';
  }

  Future<void> _openForgotPassword() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    const mutedText = Color(0xFF8A9A97);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: primaryGreen,
                      splashRadius: 22,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Center(
                    child: Text(
                      'Hisobingizga kiring',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: primaryGreen,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      indicator: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      tabs: const [
                        Tab(text: 'Login'),
                        Tab(text: 'Register'),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: _registerStep == 0 ? 260 : 168,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildLoginForm(), _buildRegisterForm()],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handlePrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      return Text(
                        _primaryButtonText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          TextField(
            controller: _loginPhoneCtrl,
            keyboardType: TextInputType.phone,
            cursorColor: const Color(0xFF1F5A50),
            decoration: _inputDecoration('Telefon raqam'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _loginCodeCtrl,
            keyboardType: TextInputType.number,
            cursorColor: const Color(0xFF1F5A50),
            decoration: _inputDecoration('SMS kod'),
          ),
          const SizedBox(height: 8),
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
    if (_registerStep == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          children: [
            TextField(
              controller: _registerCodeCtrl,
              keyboardType: TextInputType.number,
              cursorColor: const Color(0xFF1F5A50),
              decoration: _inputDecoration('SMS kod'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _registerStep = 0),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1F5A50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Ma'lumotlarga qaytish",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          TextField(
            controller: _registerFirstCtrl,
            cursorColor: const Color(0xFF1F5A50),
            decoration: _inputDecoration('Ism'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _registerLastCtrl,
            cursorColor: const Color(0xFF1F5A50),
            decoration: _inputDecoration('Familiya'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _registerPhoneCtrl,
            keyboardType: TextInputType.phone,
            cursorColor: const Color(0xFF1F5A50),
            decoration: _inputDecoration('Telefon raqami'),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _mockSmsCode = '1234';

  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  int _step = 0;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration(String label) {
    const primaryGreen = Color(0xFF1F5A50);
    const mutedText = Color(0xFF8A9A97);

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: mutedText),
      floatingLabelStyle: const TextStyle(
        color: primaryGreen,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: const Color(0xFFF6F7F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(primaryGreen.withValues(alpha: 0.12)),
      focusedBorder: border(primaryGreen, width: 1.4),
      errorBorder: border(Colors.redAccent.withValues(alpha: 0.7)),
      focusedErrorBorder: border(Colors.redAccent, width: 1.4),
    );
  }

  void _handlePrimaryAction() {
    if (_step == 0) {
      if (_phoneCtrl.text.trim().isEmpty) {
        _showMessage('Telefon raqamni kiriting');
        return;
      }
      setState(() => _step = 1);
      return;
    }

    if (_codeCtrl.text.trim() != _mockSmsCode) {
      _showMessage('SMS kod xato');
      return;
    }
    _showMessage('Parol tiklash tasdiqlandi');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: primaryGreen,
                      splashRadius: 22,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Center(
                    child: Text(
                      'Parolni tiklash',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _step = 0),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Telefon raqamni o‘zgartirish',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handlePrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _step == 0 ? 'Davom etish' : 'Tasdiqlash',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
