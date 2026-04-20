import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hello_flutter_app/models/seller_application.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/store_api_service.dart';
import 'package:image_picker/image_picker.dart';

const _primaryGreen = Color(0xFF1F5A50);
const _ink = Color(0xFF1F2933);
const _muted = Color(0xFF6B7280);
const _line = Color(0xFFE5E7EB);
const _surface = Color(0xFFF8FAF9);

class OpenStoreScreen extends StatefulWidget {
  const OpenStoreScreen({super.key});

  @override
  State<OpenStoreScreen> createState() => _OpenStoreScreenState();
}

class _OpenStoreScreenState extends State<OpenStoreScreen> {
  final StoreApiService _storeApi = StoreApiService();
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _birthDateCtrl = TextEditingController();
  final TextEditingController _primaryPhoneCtrl = TextEditingController();
  final TextEditingController _additionalPhoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _livingAddressCtrl = TextEditingController();
  final TextEditingController _passportSeriesNumberCtrl =
      TextEditingController();
  final TextEditingController _passportIssuedByCtrl = TextEditingController();
  final TextEditingController _passportIssuedDateCtrl = TextEditingController();
  final TextEditingController _jshshirCtrl = TextEditingController();
  final TextEditingController _storeNameCtrl = TextEditingController();
  final TextEditingController _activityTypeCtrl = TextEditingController();
  final TextEditingController _storeDescriptionCtrl = TextEditingController();
  final TextEditingController _storeAddressCtrl = TextEditingController();
  final TextEditingController _storeMapLocationCtrl = TextEditingController();
  final TextEditingController _workingHoursCtrl = TextEditingController();
  final TextEditingController _deliveryAreaCtrl = TextEditingController();
  final TextEditingController _deliveryPriceCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  SellerApplication? _application;
  File? _storeLogoFile;
  String _storeLogoPath = '';
  List<File> _storeBannerImageFiles = [];
  List<String> _storeBannerImagePaths = [];
  String _gender = '';
  String _storeType = 'online';
  bool _hasDelivery = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isFormOpen = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _birthDateCtrl.dispose();
    _primaryPhoneCtrl.dispose();
    _additionalPhoneCtrl.dispose();
    _emailCtrl.dispose();
    _livingAddressCtrl.dispose();
    _passportSeriesNumberCtrl.dispose();
    _passportIssuedByCtrl.dispose();
    _passportIssuedDateCtrl.dispose();
    _jshshirCtrl.dispose();
    _storeNameCtrl.dispose();
    _activityTypeCtrl.dispose();
    _storeDescriptionCtrl.dispose();
    _storeAddressCtrl.dispose();
    _storeMapLocationCtrl.dispose();
    _workingHoursCtrl.dispose();
    _deliveryAreaCtrl.dispose();
    _deliveryPriceCtrl.dispose();
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
        if (application?.status == 'rejected') {
          _fillForm(application!);
        } else {
          _clearForm();
        }
        _isFormOpen = false;
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
      fullName: _fullNameCtrl.text.trim(),
      birthDate: _birthDateCtrl.text.trim(),
      gender: _gender,
      primaryPhone: _compactUzPhone(_primaryPhoneCtrl.text),
      additionalPhone: _additionalPhoneCtrl.text.trim().isEmpty
          ? ''
          : _compactUzPhone(_additionalPhoneCtrl.text),
      email: _emailCtrl.text.trim(),
      livingAddress: _livingAddressCtrl.text.trim(),
      passportSeriesNumber: _passportSeriesNumberCtrl.text.trim(),
      passportIssuedBy: _passportIssuedByCtrl.text.trim(),
      passportIssuedDate: _passportIssuedDateCtrl.text.trim(),
      jshshir: _jshshirCtrl.text.trim(),
      storeName: _storeNameCtrl.text.trim(),
      storeType: _storeType,
      activityType: _activityTypeCtrl.text.trim(),
      storeDescription: _storeDescriptionCtrl.text.trim(),
      storeAddress: _storeAddressCtrl.text.trim(),
      storeMapLocation: _storeMapLocationCtrl.text.trim(),
      workingHours: _workingHoursCtrl.text.trim(),
      hasDelivery: _hasDelivery,
      deliveryArea: _deliveryAreaCtrl.text.trim(),
      deliveryPrice: _hasDelivery
          ? num.tryParse(_deliveryPriceCtrl.text.trim()) ?? -1
          : 0,
      storeLogoFile: _storeLogoFile,
      storeBannerImageFiles: _storeBannerImageFiles,
    );
    final validationError = _validateInput(input);
    if (validationError != null) {
      setState(() => _error = validationError);
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
        _isFormOpen = false;
        _clearForm();
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isSubmitting = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            "Ariza yuborishda kutilmagan xato: ${error.runtimeType}: $error";
        _isSubmitting = false;
      });
    }
  }

  void _fillForm(SellerApplication application) {
    _fullNameCtrl.text = application.fullName;
    _birthDateCtrl.text = _dateOnly(application.birthDate);
    _gender = application.gender;
    _primaryPhoneCtrl.text = application.primaryPhone;
    _formatPhoneController(_primaryPhoneCtrl);
    _additionalPhoneCtrl.text = application.additionalPhone;
    _formatPhoneController(_additionalPhoneCtrl);
    _emailCtrl.text = application.email;
    _livingAddressCtrl.text = application.livingAddress;
    _passportSeriesNumberCtrl.text = application.passportSeriesNumber;
    _passportIssuedByCtrl.text = application.passportIssuedBy;
    _passportIssuedDateCtrl.text = _dateOnly(application.passportIssuedDate);
    _jshshirCtrl.text = application.jshshir;
    _storeNameCtrl.text = application.storeName;
    _storeType = _normalizeStoreType(application.storeType);
    _activityTypeCtrl.text = application.activityType;
    _storeDescriptionCtrl.text = application.storeDescription;
    _storeAddressCtrl.text = application.storeAddress;
    _storeMapLocationCtrl.text = application.storeMapLocation;
    _workingHoursCtrl.text = application.workingHours;
    _hasDelivery = application.hasDelivery;
    _deliveryAreaCtrl.text = application.deliveryArea;
    _deliveryPriceCtrl.text = application.deliveryPrice == 0
        ? ''
        : application.deliveryPrice.toString();
    _storeLogoPath = application.storeLogo;
    _storeLogoFile = null;
    _storeBannerImagePaths = application.storeBannerImages;
    _storeBannerImageFiles = [];
  }

  String _dateOnly(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(trimmed);
    if (match != null) return match.group(1)!;
    return trimmed;
  }

  void _clearForm() {
    _fullNameCtrl.clear();
    _birthDateCtrl.clear();
    _primaryPhoneCtrl.clear();
    _additionalPhoneCtrl.clear();
    _emailCtrl.clear();
    _livingAddressCtrl.clear();
    _passportSeriesNumberCtrl.clear();
    _passportIssuedByCtrl.clear();
    _passportIssuedDateCtrl.clear();
    _jshshirCtrl.clear();
    _storeNameCtrl.clear();
    _activityTypeCtrl.clear();
    _storeDescriptionCtrl.clear();
    _storeAddressCtrl.clear();
    _storeMapLocationCtrl.clear();
    _workingHoursCtrl.clear();
    _deliveryAreaCtrl.clear();
    _deliveryPriceCtrl.clear();
    _storeLogoPath = '';
    _storeLogoFile = null;
    _storeBannerImagePaths = [];
    _storeBannerImageFiles = [];
    _gender = '';
    _storeType = 'online';
    _hasDelivery = false;
  }

  String? _validateInput(SellerApplicationCreateInput input) {
    final missingFields = <String>[
      if (input.fullName.isEmpty) 'Ism familiya',
      if (input.birthDate.isEmpty) 'Tug‘ilgan sana',
      if (input.gender.isEmpty) 'Jinsi',
      if (input.primaryPhone.isEmpty) 'Asosiy telefon',
      if (input.email.isEmpty) 'Email',
      if (input.livingAddress.isEmpty) 'Yashash manzili',
      if (input.passportSeriesNumber.isEmpty) 'Pasport seriya raqami',
      if (input.jshshir.isEmpty) 'JSHSHIR',
      if (input.passportIssuedBy.isEmpty) 'Pasport kim tomonidan berilgan',
      if (input.passportIssuedDate.isEmpty) 'Pasport berilgan sana',
      if (input.storeName.isEmpty) "Do'kon nomi",
      if (input.storeType.isEmpty) "Do'kon turi",
      if (input.activityType.isEmpty) "Faoliyat yo'nalishi",
      if (input.storeDescription.isEmpty) "Do'kon tavsifi",
      if (input.storeMapLocation.isEmpty) 'Google Map link yoki koordinata',
      if (input.workingHours.isEmpty) 'Ish vaqti',
      if (input.storeLogoFile == null) "Do'kon rasmi/logo",
    ];

    if (missingFields.isNotEmpty) {
      return 'Quyidagilarni to‘ldiring: ${missingFields.join(', ')}';
    }

    if (!_isDate(input.birthDate) || !_isDate(input.passportIssuedDate)) {
      return 'Sanani YYYY-MM-DD formatida kiriting';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input.email)) {
      return "Email noto'g'ri formatda";
    }

    if (!RegExp(r'^[A-Z]{2}\d{7}$').hasMatch(input.passportSeriesNumber)) {
      return 'Pasport seriya raqami AD2467890 formatida bo‘lishi kerak';
    }

    if (!RegExp(r'^\d{14}$').hasMatch(input.jshshir)) {
      return 'JSHSHIR 14 ta raqamdan iborat bo‘lishi kerak';
    }

    if (!RegExp(r'^\+998\d{9}$').hasMatch(input.primaryPhone)) {
      return 'Asosiy telefon +998 90-123-45-67 formatida bo‘lishi kerak';
    }

    if (input.additionalPhone.isNotEmpty &&
        !RegExp(r'^\+998\d{9}$').hasMatch(input.additionalPhone)) {
      return 'Qo‘shimcha telefon +998 90-123-45-67 formatida bo‘lishi kerak';
    }

    if (!['online', 'offline', 'both'].contains(input.storeType)) {
      return "Do'kon turi online, offline yoki both bo‘lishi kerak";
    }

    if ((input.storeType == 'offline' || input.storeType == 'both') &&
        input.storeAddress.isEmpty) {
      return "Offline do'kon uchun manzil majburiy";
    }

    if (input.hasDelivery) {
      if (input.deliveryArea.isEmpty ||
          _deliveryPriceCtrl.text.trim().isEmpty) {
        return 'Yetkazib berish hududi va narxini kiriting';
      }

      if (input.deliveryPrice < 0) {
        return 'Yetkazib berish narxi 0 yoki undan katta bo‘lishi kerak';
      }
    }

    final logoError = _validateImageFile(input.storeLogoFile);
    if (logoError != null) return "Do'kon rasmi/logo: $logoError";

    if (input.storeBannerImageFiles.length > 10) {
      return "Banner rasmlar 10 tadan oshmasligi kerak";
    }

    for (var i = 0; i < input.storeBannerImageFiles.length; i += 1) {
      final error = _validateImageFile(input.storeBannerImageFiles[i]);
      if (error != null) return '${i + 1}-banner rasm: $error';
    }

    return null;
  }

  String? _validateImageFile(File? file) {
    if (file == null) return null;
    final lower = file.path.toLowerCase();
    final isImage =
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
    if (!isImage) return 'Faqat image file yuklash mumkin';
    final size = file.lengthSync();
    const maxBytes = 50 * 1024 * 1024;
    if (size > maxBytes) return 'Rasm hajmi 50 MB dan oshmasligi kerak';
    return null;
  }

  String _normalizeStoreType(String value) {
    return switch (value) {
      'offline' => 'offline',
      'both' || 'ikkalasi' => 'both',
      _ => 'online',
    };
  }

  bool _isDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final parts = value.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1], parts[2]);
    return date.year == parts[0] &&
        date.month == parts[1] &&
        date.day == parts[2];
  }

  String _compactUzPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('998') ? digits.substring(3) : digits;
    return '+998${local.length > 9 ? local.substring(0, 9) : local}';
  }

  void _formatPhoneController(TextEditingController controller) {
    final text = _UzPhoneFormatter.formatText(controller.text);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _pickStoreLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _storeLogoFile = File(picked.path);
      _storeLogoPath = '';
      _error = null;
    });
  }

  void _removeStoreLogo() {
    if (_isSubmitting) return;
    setState(() {
      _storeLogoFile = null;
      _storeLogoPath = '';
      _error = null;
    });
  }

  Future<void> _pickStoreBannerImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _storeBannerImageFiles = picked.map((item) => File(item.path)).toList();
      _storeBannerImagePaths = [];
      _error = null;
    });
  }

  void _removeStoreBannerImage(int index) {
    if (_isSubmitting) return;
    setState(() {
      if (_storeBannerImageFiles.isNotEmpty) {
        _storeBannerImageFiles = List<File>.from(_storeBannerImageFiles)
          ..removeAt(index);
      } else if (_storeBannerImagePaths.isNotEmpty) {
        _storeBannerImagePaths = List<String>.from(_storeBannerImagePaths)
          ..removeAt(index);
      }
      _error = null;
    });
  }

  InputDecoration _inputDecoration(String label) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _muted,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: _ink,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(_line),
      disabledBorder: border(_line.withValues(alpha: 0.72)),
      focusedBorder: border(_ink, width: 1.4),
      errorBorder: border(Colors.redAccent.withValues(alpha: 0.7)),
      focusedErrorBorder: border(Colors.redAccent, width: 1.4),
    );
  }

  TextStyle get _inputTextStyle {
    return const TextStyle(
      color: _ink,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
  }

  TextStyle get _multilineInputTextStyle {
    return const TextStyle(
      color: _ink,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.35,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Do'kon ochish",
          style: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primaryGreen),
              )
            : RefreshIndicator(
                color: _primaryGreen,
                onRefresh: _loadApplication,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (_application != null)
                      _ApplicationStatusCard(application: _application!),
                    if (_application?.status == 'pending') ...[
                      const SizedBox(height: 16),
                      const _PendingApplicationNotice(),
                    ] else ...[
                      if (_application != null) const SizedBox(height: 16),
                      if (_isFormOpen)
                        _buildForm()
                      else
                        _OpenApplicationButton(
                          application: _application,
                          onPressed: () {
                            setState(() {
                              if (_application?.status == 'rejected') {
                                _fillForm(_application!);
                              }
                              _error = null;
                              _message = null;
                              _isFormOpen = true;
                            });
                          },
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Do'kon ochish arizasi",
          style: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        const _FormSectionTitle(title: "Shaxsiy ma'lumotlar"),
        const SizedBox(height: 10),
        TextField(
          controller: _fullNameCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration('F.I.Sh'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _birthDateCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          keyboardType: TextInputType.datetime,
          inputFormatters: [
            _DateInputFormatter(),
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: _inputDecoration('Tug‘ilgan sana').copyWith(
            hintText: '1995-05-20',
            suffixIcon: const Icon(Icons.calendar_month_rounded, color: _muted),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _gender.isEmpty ? null : _gender,
          items: const [
            DropdownMenuItem(value: 'erkak', child: Text('Erkak')),
            DropdownMenuItem(value: 'ayol', child: Text('Ayol')),
          ],
          onChanged: _isSubmitting
              ? null
              : (value) => setState(() => _gender = value ?? ''),
          decoration: _inputDecoration('Jinsi'),
          dropdownColor: Colors.white,
          style: _inputTextStyle,
          iconEnabledColor: _ink,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _primaryPhoneCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          keyboardType: TextInputType.phone,
          inputFormatters: [_UzPhoneFormatter()],
          decoration: _inputDecoration('Asosiy telefon'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _additionalPhoneCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          keyboardType: TextInputType.phone,
          inputFormatters: [_UzPhoneFormatter()],
          decoration: _inputDecoration('Qo‘shimcha telefon'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _emailCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('Email'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _livingAddressCtrl,
          enabled: !_isSubmitting,
          minLines: 2,
          maxLines: 4,
          cursorColor: _ink,
          style: _multilineInputTextStyle,
          decoration: _inputDecoration(
            'Yashash manzili',
          ).copyWith(hintText: "Viloyat, tuman, ko'cha va uy raqami"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passportSeriesNumberCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            _UppercasePassportFormatter(),
            LengthLimitingTextInputFormatter(9),
          ],
          decoration: _inputDecoration(
            'Pasport seriya raqami',
          ).copyWith(hintText: 'AD2467890', counterText: ''),
          maxLength: 9,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _jshshirCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(14),
          ],
          decoration: _inputDecoration(
            'JSHSHIR',
          ).copyWith(hintText: '14 ta raqam', counterText: ''),
          maxLength: 14,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passportIssuedByCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration('Pasport kim tomonidan berilgan'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passportIssuedDateCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          keyboardType: TextInputType.datetime,
          inputFormatters: [
            _DateInputFormatter(),
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: _inputDecoration('Pasport berilgan sana').copyWith(
            hintText: '2020-01-15',
            suffixIcon: const Icon(Icons.calendar_month_rounded, color: _muted),
          ),
        ),
        const SizedBox(height: 18),
        const _FormSectionTitle(title: "Do'kon haqida ma'lumot"),
        const SizedBox(height: 10),
        TextField(
          controller: _storeNameCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration("Do'kon nomi"),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _storeType,
          items: const [
            DropdownMenuItem(value: 'online', child: Text('Online')),
            DropdownMenuItem(value: 'offline', child: Text('Offline')),
            DropdownMenuItem(value: 'both', child: Text('Online va offline')),
          ],
          onChanged: _isSubmitting
              ? null
              : (value) => setState(() => _storeType = value ?? 'online'),
          decoration: _inputDecoration("Do'kon turi"),
          dropdownColor: Colors.white,
          style: _inputTextStyle,
          iconEnabledColor: _ink,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _activityTypeCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(
            "Faoliyat yo'nalishi",
          ).copyWith(hintText: 'Elektronika, kiyim-kechak, oziq-ovqat'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _storeDescriptionCtrl,
          enabled: !_isSubmitting,
          minLines: 2,
          maxLines: 4,
          cursorColor: _ink,
          style: _multilineInputTextStyle,
          decoration: _inputDecoration("Do'kon tavsifi"),
        ),
        if (_storeType == 'offline' || _storeType == 'both') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _storeAddressCtrl,
            enabled: !_isSubmitting,
            minLines: 2,
            maxLines: 3,
            cursorColor: _ink,
            style: _multilineInputTextStyle,
            decoration: _inputDecoration(
              "Do'kon manzili",
            ).copyWith(hintText: "Viloyat, tuman, ko'cha va mo'ljal"),
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _storeMapLocationCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          keyboardType: TextInputType.url,
          decoration: _inputDecoration('Google Map link yoki koordinata'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _workingHoursCtrl,
          enabled: !_isSubmitting,
          cursorColor: _ink,
          style: _inputTextStyle,
          decoration: _inputDecoration(
            'Ish vaqti',
          ).copyWith(hintText: '09:00-21:00'),
        ),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          value: _hasDelivery,
          onChanged: _isSubmitting
              ? null
              : (value) => setState(() => _hasDelivery = value),
          contentPadding: const EdgeInsets.symmetric(horizontal: 2),
          activeThumbColor: _primaryGreen,
          title: const Text(
            'Yetkazib berish mavjud',
            style: TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (_hasDelivery) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _deliveryAreaCtrl,
            enabled: !_isSubmitting,
            cursorColor: _ink,
            style: _inputTextStyle,
            decoration: _inputDecoration('Yetkazib berish hududi'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _deliveryPriceCtrl,
            enabled: !_isSubmitting,
            cursorColor: _ink,
            style: _inputTextStyle,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
              'Yetkazib berish narxi',
            ).copyWith(hintText: '20000'),
          ),
        ],
        const SizedBox(height: 10),
        _StoreLogoPicker(
          file: _storeLogoFile,
          existingPath: _storeLogoPath,
          enabled: !_isSubmitting,
          onPick: _pickStoreLogo,
          onRemove: _removeStoreLogo,
        ),
        const SizedBox(height: 10),
        _StoreBannerPicker(
          files: _storeBannerImageFiles,
          existingPaths: _storeBannerImagePaths,
          enabled: !_isSubmitting,
          onPick: _pickStoreBannerImages,
          onRemove: _removeStoreBannerImage,
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
              color: _ink,
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
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primaryGreen.withValues(alpha: 0.72),
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

class _FormSectionTitle extends StatelessWidget {
  final String title;

  const _FormSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _StoreLogoPicker extends StatelessWidget {
  final File? file;
  final String existingPath;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _StoreLogoPicker({
    required this.file,
    required this.existingPath,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = file != null || existingPath.isNotEmpty;

    return InkWell(
      onTap: enabled ? onPick : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 58,
                    height: 58,
                    color: Colors.white,
                    child: file != null
                        ? Image.file(file!, fit: BoxFit.cover)
                        : const Icon(
                            Icons.add_photo_alternate_rounded,
                            color: _primaryGreen,
                          ),
                  ),
                ),
                if (hasImage)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: _RemoveImageButton(
                      enabled: enabled,
                      onPressed: onRemove,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Do'kon rasmi/logo",
                    style: TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file != null
                        ? file!.path.split(Platform.pathSeparator).last
                        : hasImage
                        ? "Qayta yuborish uchun yangi rasm tanlang"
                        : 'Galereyadan rasm tanlang',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: enabled ? onPick : null,
              icon: const Icon(Icons.photo_library_rounded),
              color: _primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreBannerPicker extends StatelessWidget {
  final List<File> files;
  final List<String> existingPaths;
  final bool enabled;
  final VoidCallback onPick;
  final void Function(int index) onRemove;

  const _StoreBannerPicker({
    required this.files,
    required this.existingPaths,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final count = files.isNotEmpty ? files.length : existingPaths.length;

    return InkWell(
      onTap: enabled ? onPick : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Banner rasmlar',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: enabled ? onPick : null,
                  icon: const Icon(Icons.collections_rounded),
                  color: _primaryGreen,
                ),
              ],
            ),
            Text(
              count == 0
                  ? 'Ixtiyoriy. Galereyadan bir nechta rasm tanlash mumkin'
                  : '$count ta rasm tanlangan',
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (files.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            files[index],
                            width: 84,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: -7,
                          top: -7,
                          child: _RemoveImageButton(
                            enabled: enabled,
                            onPressed: () => onRemove(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ] else if (existingPaths.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: existingPaths.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 84,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _line),
                          ),
                          child: const Icon(
                            Icons.image_rounded,
                            color: _primaryGreen,
                          ),
                        ),
                        Positioned(
                          right: -7,
                          top: -7,
                          child: _RemoveImageButton(
                            enabled: enabled,
                            onPressed: () => onRemove(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RemoveImageButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _RemoveImageButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.redAccent,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            Icons.close_rounded,
            color: enabled ? Colors.white : Colors.white70,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _OpenApplicationButton extends StatelessWidget {
  final SellerApplication? application;
  final VoidCallback onPressed;

  const _OpenApplicationButton({
    required this.application,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isRejected = application?.status == 'rejected';
    final isApproved = application?.status == 'approved';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRejected
                ? "Arizani qayta yuborish"
                : isApproved
                ? "Yana do'kon ochish"
                : "Yangi do'kon ochish",
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRejected
                ? "Ma'lumotlarni to'g'rilab, arizani qayta yuborishingiz mumkin."
                : "Ariza yuborish uchun shaxsiy va pasport ma'lumotlaringizni kiriting.",
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.edit_document),
              label: Text(isRejected ? 'Qayta yuborish' : 'Ariza yuborish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApplicationNotice extends StatelessWidget {
  const _PendingApplicationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ariza ko'rib chiqilmoqda",
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Admin javob bermaguncha yangi ariza yuborib bo'lmaydi. Ariza rad etilsa, shu yerda qayta yuborish tugmasi chiqadi.",
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.hourglass_top_rounded),
              label: const Text("Javob kutilmoqda"),
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: _primaryGreen.withValues(alpha: 0.35),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    for (var index = 0; index < limited.length; index += 1) {
      if (index == 4 || index == 6) buffer.write('-');
      buffer.write(limited[index]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _UzPhoneFormatter extends TextInputFormatter {
  static String formatText(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998')) digits = digits.substring(3);
    if (digits.length > 9) digits = digits.substring(0, 9);

    final buffer = StringBuffer('+998');
    if (digits.isNotEmpty) {
      buffer.write(' ');
      buffer.write(digits.substring(0, digits.length < 2 ? digits.length : 2));
    }
    if (digits.length > 2) {
      buffer.write('-');
      buffer.write(digits.substring(2, digits.length < 5 ? digits.length : 5));
    }
    if (digits.length > 5) {
      buffer.write('-');
      buffer.write(digits.substring(5, digits.length < 7 ? digits.length : 7));
    }
    if (digits.length > 7) {
      buffer.write('-');
      buffer.write(digits.substring(7, digits.length < 9 ? digits.length : 9));
    }

    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = formatText(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ApplicationStatusCard extends StatelessWidget {
  final SellerApplication application;

  const _ApplicationStatusCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final statusText = switch (application.status) {
      'approved' => 'Tasdiqlangan',
      'rejected' => 'Rad etilgan',
      _ => 'Ko‘rib chiqilmoqda',
    };
    final statusDescription = switch (application.status) {
      'approved' =>
        'Arizangiz tasdiqlandi. Do‘koningiz "Mening do‘konlarim" bo‘limida ko‘rinadi.',
      'rejected' =>
        application.reviewNote.isEmpty
            ? 'Arizangiz rad etildi. Ma’lumotlarni yangilab qayta yuborishingiz mumkin.'
            : application.reviewNote,
      _ => 'Arizangiz ko‘rib chiqilmoqda. Natijasi shu yerda ko‘rsatiladi.',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.assignment_turned_in_rounded, color: _primaryGreen),
          const SizedBox(height: 10),
          Text(
            statusText,
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (application.fullName.isNotEmpty ||
              application.storeName.isNotEmpty ||
              application.primaryPhone.isNotEmpty ||
              application.passportSeriesNumber.isNotEmpty ||
              application.livingAddress.isNotEmpty) ...[
            const SizedBox(height: 14),
            if (application.fullName.isNotEmpty)
              _ApplicationInfoRow(
                icon: Icons.person_rounded,
                text: application.fullName,
              ),
            if (application.storeName.isNotEmpty)
              _ApplicationInfoRow(
                icon: Icons.storefront_rounded,
                text: application.storeName,
              ),
            if (application.primaryPhone.isNotEmpty)
              _ApplicationInfoRow(
                icon: Icons.phone_rounded,
                text: application.primaryPhone,
              ),
            if (application.passportSeriesNumber.isNotEmpty)
              _ApplicationInfoRow(
                icon: Icons.badge_rounded,
                text: application.passportSeriesNumber,
              ),
            if (application.livingAddress.isNotEmpty)
              _ApplicationInfoRow(
                icon: Icons.location_on_rounded,
                text: application.livingAddress,
              ),
          ],
        ],
      ),
    );
  }
}

class _UppercasePassportFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = newValue.text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );

    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

class _ApplicationInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ApplicationInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _ink.withValues(alpha: 0.82),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
