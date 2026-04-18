import 'package:flutter/material.dart';
import 'package:hello_flutter_app/models/seller_application.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/store_api_service.dart';

class OpenStoreScreen extends StatefulWidget {
  const OpenStoreScreen({super.key});

  @override
  State<OpenStoreScreen> createState() => _OpenStoreScreenState();
}

class _OpenStoreScreenState extends State<OpenStoreScreen> {
  final StoreApiService _storeApi = StoreApiService();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _storeNameCtrl = TextEditingController();
  final TextEditingController _purposeCtrl = TextEditingController();
  final TextEditingController _productsInfoCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  SellerApplication? _application;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _storeNameCtrl.dispose();
    _purposeCtrl.dispose();
    _productsInfoCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApplication() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final application = await _storeApi.getMyApplication();
      if (!mounted) return;
      setState(() {
        _application = application;
        _isLoading = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Ariza holatini yuklab bo‘lmadi';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (_isSubmitting) return;
    final input = SellerApplicationCreateInput(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      storeName: _storeNameCtrl.text.trim(),
      purpose: _purposeCtrl.text.trim(),
      productsInfo: _productsInfoCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    if (input.firstName.isEmpty ||
        input.lastName.isEmpty ||
        input.phone.isEmpty ||
        input.purpose.isEmpty ||
        input.productsInfo.isEmpty ||
        input.address.isEmpty) {
      setState(() => _error = 'Majburiy maydonlarni to‘ldiring');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _message = null;
    });

    try {
      final application = await _storeApi.createSellerApplication(input);
      if (!mounted) return;
      setState(() {
        _application = application;
        _message = 'Ariza yuborildi. Natijasini tez orada olasiz';
        _isSubmitting = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isSubmitting = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Server bilan bog‘lanib bo‘lmadi';
        _isSubmitting = false;
      });
    }
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
      labelStyle: const TextStyle(
        color: mutedText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: primaryGreen,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: const Color(0xFFF6F7F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(primaryGreen.withValues(alpha: 0.12)),
      disabledBorder: border(primaryGreen.withValues(alpha: 0.08)),
      focusedBorder: border(primaryGreen, width: 1.4),
      errorBorder: border(Colors.redAccent.withValues(alpha: 0.7)),
      focusedErrorBorder: border(Colors.redAccent, width: 1.4),
    );
  }

  TextStyle get _inputTextStyle {
    return const TextStyle(
      color: Color(0xFF1F5A50),
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
  }

  TextStyle get _multilineInputTextStyle {
    return const TextStyle(
      color: Color(0xFF1F5A50),
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.35,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Do'kon ochish",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
            : RefreshIndicator(
                color: primaryGreen,
                onRefresh: _loadApplication,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (_application != null)
                      _ApplicationStatusCard(application: _application!)
                    else
                      _buildForm(primaryGreen),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildForm(Color primaryGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Do'kon ochish arizasi",
          style: TextStyle(
            color: primaryGreen,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _firstNameCtrl,
          enabled: !_isSubmitting,
          cursorColor: primaryGreen,
          style: _inputTextStyle,
          decoration: _inputDecoration('Ism'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _lastNameCtrl,
          enabled: !_isSubmitting,
          cursorColor: primaryGreen,
          style: _inputTextStyle,
          decoration: _inputDecoration('Familiya'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneCtrl,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.phone,
          cursorColor: primaryGreen,
          style: _inputTextStyle,
          decoration: _inputDecoration('Telefon raqam'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _storeNameCtrl,
          enabled: !_isSubmitting,
          cursorColor: primaryGreen,
          style: _inputTextStyle,
          decoration: _inputDecoration("Do'kon nomi"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _purposeCtrl,
          enabled: !_isSubmitting,
          minLines: 2,
          maxLines: 4,
          cursorColor: primaryGreen,
          style: _multilineInputTextStyle,
          decoration: _inputDecoration('Maqsad'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _productsInfoCtrl,
          enabled: !_isSubmitting,
          minLines: 2,
          maxLines: 4,
          cursorColor: primaryGreen,
          style: _multilineInputTextStyle,
          decoration: _inputDecoration('Mahsulotlar haqida'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressCtrl,
          enabled: !_isSubmitting,
          minLines: 2,
          maxLines: 3,
          cursorColor: primaryGreen,
          style: _multilineInputTextStyle,
          decoration: _inputDecoration('Manzil'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 10),
          Text(
            _message!,
            style: TextStyle(
              color: primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitApplication,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.72),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Ariza yuborish'),
          ),
        ),
      ],
    );
  }
}

class _ApplicationStatusCard extends StatelessWidget {
  final SellerApplication application;

  const _ApplicationStatusCard({required this.application});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    final statusText = switch (application.status) {
      'approved' => 'Tasdiqlangan',
      'rejected' => 'Rad etilgan',
      _ => 'Ko‘rib chiqilmoqda',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.assignment_turned_in_rounded, color: primaryGreen),
          const SizedBox(height: 10),
          Text(
            statusText,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            application.reviewNote.isEmpty
                ? 'Arizangiz holati shu yerda ko‘rsatiladi.'
                : application.reviewNote,
            style: TextStyle(
              color: primaryGreen.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
