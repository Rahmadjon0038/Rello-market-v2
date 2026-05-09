import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hello_flutter_app/screens/admin_panel_screen.dart';
import 'package:hello_flutter_app/screens/auth_screen.dart';
import 'package:hello_flutter_app/screens/my_stores_screen.dart';
import 'package:hello_flutter_app/screens/open_store_screen.dart';
import 'package:hello_flutter_app/screens/orders_screen.dart';
import 'package:hello_flutter_app/services/order_api_service.dart';
import 'package:hello_flutter_app/services/auth_api_service.dart';
import 'package:hello_flutter_app/services/push_api_service.dart';
import 'package:hello_flutter_app/services/push_token_manager.dart';
import 'package:hello_flutter_app/services/store_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onAuthCancelled;
  final VoidCallback? onAuthChanged;
  final ValueChanged<int>? onSellerOrdersBadgeChanged;

  const ProfileScreen({
    super.key,
    this.onAuthCancelled,
    this.onAuthChanged,
    this.onSellerOrdersBadgeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  bool _isCheckingSession = true;
  bool _authRouteOpen = false;
  bool _isSendingPushTest = false;
  String? _lastPushTestId;
  int? _lastPushSuccessCount;
  int? _lastPushFailureCount;
  String? _lastFcmTokenStatus;
  String _name = '';
  String _phone = '';
  String _role = 'user';
  String? _profileImg;
  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();
  final AuthApiService _authApi = AuthApiService();
  final PushApiService _pushApi = PushApiService();
  final StoreApiService _storeApi = StoreApiService();
  final OrderApiService _orderApi = OrderApiService();
  int _sellerOrdersBadge = 0;
  int _userReadyOrdersBadge = 0;
  static const String _userReadySeenAtKey = 'user_orders_ready_seen_at_ms';

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    final session = await _authApi.refreshSavedSession();
    if (!mounted) return;
    if (session == null) {
      setState(() {
        _isLoggedIn = false;
        _isCheckingSession = false;
        _name = '';
        _phone = '';
        _role = 'user';
        _profileImg = null;
        _avatarFile = null;
        _sellerOrdersBadge = 0;
        _userReadyOrdersBadge = 0;
      });
      return;
    }
    setState(() {
      _isLoggedIn = true;
      _isCheckingSession = false;
      _name = session.name;
      _phone = session.phone;
      _role = session.role;
      _profileImg = session.profileImg;
    });
    _refreshSellerBadges();
    _refreshUserOrdersBadge();
  }

  Future<void> _refreshSellerBadges() async {
    if (!mounted) return;
    final role = _role.trim().toLowerCase();
    if (role != 'seller') {
      if (_sellerOrdersBadge != 0) {
        setState(() => _sellerOrdersBadge = 0);
        widget.onSellerOrdersBadgeChanged?.call(0);
      }
      return;
    }
    try {
      final count = await _storeApi.getMyStoresOrdersBadge();
      if (!mounted) return;
      setState(() => _sellerOrdersBadge = count);
      widget.onSellerOrdersBadgeChanged?.call(count);
    } on Object {
      // best-effort
    }
  }

  Future<void> _refreshUserOrdersBadge() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenAtMs = prefs.getInt(_userReadySeenAtKey) ?? 0;
      final orders = await _orderApi.getMyOrders();
      if (!mounted) return;
      final count = orders.where((o) {
        final status = o.status.trim().toLowerCase();
        if (status != 'delivering' && status != 'shipped') return false;
        final updated = o.updatedAt;
        if (updated == null) return true;
        return updated.millisecondsSinceEpoch > seenAtMs;
      }).length;
      if (!mounted) return;
      setState(() => _userReadyOrdersBadge = count);
    } on Object {
      // best-effort
    }
  }

  String _platformLabel() {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  Future<void> _copyAccessToken() async {
    try {
      final session = await _authApi.loadSavedSession();
      final token = session?.accessToken.trim() ?? '';
      if (token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Access token topilmadi')));
        return;
      }
      await Clipboard.setData(ClipboardData(text: token));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access token copy qilindi')),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tokenni copy qilib bo‘lmadi')),
      );
    }
  }

  Future<void> _sendPushTest() async {
    if (_isSendingPushTest) return;
    setState(() => _isSendingPushTest = true);
    try {
      // Don't block UI waiting for iOS APNs token readiness. If token isn't
      // registered yet, `/push/test` will simply report 0 tokens.
      PushTokenManager().registerNow();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final hasToken = (fcmToken ?? '').trim().isNotEmpty;
      final now = DateTime.now();
      final id = now.toIso8601String();

      final response = await _pushApi.sendTestPush(
        title: 'Rello test push',
        body: 'Test ID: $id',
        data: {'type': 'test', 'id': id, 'platform': _platformLabel()},
      );

      if (!mounted) return;
      setState(() {
        _lastPushTestId = id;
        _lastPushSuccessCount = (response['successCount'] is num)
            ? (response['successCount'] as num).toInt()
            : null;
        _lastPushFailureCount = (response['failureCount'] is num)
            ? (response['failureCount'] as num).toInt()
            : null;
        _lastFcmTokenStatus = hasToken ? 'FCM token: OK' : 'FCM token: YO‘Q';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Test push yuborildi (ID: $id)')));
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Serverga ulanib bo'lmadi")));
    } finally {
      if (mounted) setState(() => _isSendingPushTest = false);
    }
  }

  Future<T?> _showFastBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool showDragHandle = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useRootNavigator = false,
    Color? backgroundColor,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useRootNavigator: useRootNavigator,
      backgroundColor: backgroundColor,
      shape: shape,
      builder: builder,
    );
  }

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + last).toUpperCase();
  }

  bool get _isSeller => _role.toLowerCase() == 'seller';

  bool get _isAdmin => _role.toLowerCase() == 'admin';

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

  Future<void> _logout() async {
    final session = await _authApi.loadSavedSession();
    await _authApi.clearSession();
    if (!mounted) return;
    _resetLoggedOutState();
    widget.onAuthChanged?.call();

    // Best-effort cleanup in background; don't block logout UX.
    final accessToken = session?.accessToken.trim() ?? '';
    if (accessToken.isEmpty) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    Future<void>(() async {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        final trimmed = (token ?? '').trim();
        if (trimmed.isEmpty) return;
        await _pushApi.unregisterDeviceTokenWithAccessToken(
          token: trimmed,
          accessToken: accessToken,
        );
      } on Object {
        // best-effort
      }
    });
  }

  void _resetLoggedOutState() {
    setState(() {
      _isLoggedIn = false;
      _isCheckingSession = false;
      _name = '';
      _phone = '';
      _avatarFile = null;
      _profileImg = null;
      _role = 'user';
      _sellerOrdersBadge = 0;
      _userReadyOrdersBadge = 0;
    });
  }

  Future<void> _openAuthPage() async {
    if (_authRouteOpen) return;
    _authRouteOpen = true;
    final result = await Navigator.of(
      context,
    ).push<AuthResult>(MaterialPageRoute(builder: (_) => const AuthScreen()));
    if (!mounted) return;
    _authRouteOpen = false;
    if (result == null) {
      widget.onAuthCancelled?.call();
      return;
    }
    setState(() {
      _isLoggedIn = true;
      _name = result.name;
      _phone = result.phone;
      _role = result.role;
      _profileImg = result.profileImg;
      _avatarFile = null;
    });
    widget.onAuthChanged?.call();
    _showLoginSuccessNotification();
  }

  void _showLoginSuccessNotification() {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopAuthNotification(
        message: 'Tizimga kirish muvaffaqiyatli',
        onClose: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 2600), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<File?> _pickAvatarFile() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return null;
    return File(file.path);
  }

  ImageProvider? get _avatarProvider {
    if (_avatarFile != null) return FileImage(_avatarFile!);
    final imageUrl = _profileImageUrl;
    if (imageUrl != null) return NetworkImage(imageUrl);
    return null;
  }

  String? get _profileImageUrl {
    final path = _profileImg;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = AuthApiService.baseUrlForFiles.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$base$normalizedPath';
  }

  void _openEditProfile() {
    _showFastBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return _EditProfileSheet(
          initialName: _name,
          initials: _initials,
          currentAvatar: _avatarFile,
          authApi: _authApi,
          pickAvatarFile: _pickAvatarFile,
          onInvalidSession: _resetLoggedOutState,
          onSaved: (session, pickedAvatar) {
            if (!mounted) return;
            setState(() {
              _name = session.name;
              _phone = session.phone;
              _role = session.role;
              _profileImg = session.profileImg;
              if (pickedAvatar != null) _avatarFile = pickedAvatar;
            });
          },
        );
      },
    );
  }

  void _openEditPhone() {
    final oldPhoneCtrl = TextEditingController(text: _phone);
    final newPhoneCtrl = TextEditingController(text: _phone);
    final codeCtrl = TextEditingController();
    var step = 0;
    var isSubmitting = false;
    String? message;
    String? errorText;

    _showFastBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> requestCode() async {
              if (isSubmitting) return;
              final oldPhone = oldPhoneCtrl.text.trim();
              final newPhone = newPhoneCtrl.text.trim();
              if (oldPhone.isEmpty) {
                setModalState(
                  () => errorText = 'Eski telefon raqamni kiriting',
                );
                return;
              }
              if (newPhone.isEmpty) {
                setModalState(
                  () => errorText = 'Yangi telefon raqamni kiriting',
                );
                return;
              }
              setModalState(() {
                isSubmitting = true;
                message = null;
                errorText = null;
              });
              try {
                final response = await _authApi.requestPhoneChangeCode(
                  oldPhone: oldPhone,
                  newPhone: newPhone,
                );
                if (!ctx.mounted) return;
                setModalState(() {
                  step = 1;
                  message = response.smsCode == null
                      ? response.message
                      : '${response.message}. Kod: ${response.smsCode}';
                });
              } on AuthApiException catch (error) {
                if (!ctx.mounted) return;
                if (AuthApiService.isInvalidSessionError(error)) {
                  Navigator.of(ctx).pop();
                  _resetLoggedOutState();
                  return;
                }
                setModalState(() => errorText = error.message);
              } on Object {
                if (!ctx.mounted) return;
                setModalState(
                  () => errorText = 'Server bilan bog‘lanib bo‘lmadi',
                );
              } finally {
                if (ctx.mounted) setModalState(() => isSubmitting = false);
              }
            }

            Future<void> verifyCode() async {
              if (isSubmitting) return;
              final oldPhone = oldPhoneCtrl.text.trim();
              final newPhone = newPhoneCtrl.text.trim();
              final code = codeCtrl.text.trim();
              if (code.isEmpty) {
                setModalState(() => errorText = 'SMS kodni kiriting');
                return;
              }
              setModalState(() {
                isSubmitting = true;
                errorText = null;
              });
              var saved = false;
              try {
                final session = await _authApi.verifyPhoneChangeCode(
                  oldPhone: oldPhone,
                  newPhone: newPhone,
                  code: code,
                );
                if (!mounted) return;
                setState(() {
                  _name = session.name;
                  _phone = session.phone;
                  _role = session.role;
                  _profileImg = session.profileImg;
                });
                saved = true;
                if (ctx.mounted) Navigator.of(ctx).pop();
              } on AuthApiException catch (error) {
                if (!ctx.mounted) return;
                if (AuthApiService.isInvalidSessionError(error)) {
                  Navigator.of(ctx).pop();
                  _resetLoggedOutState();
                  return;
                }
                setModalState(() => errorText = error.message);
              } on Object {
                if (!ctx.mounted) return;
                setModalState(
                  () => errorText = 'Server bilan bog‘lanib bo‘lmadi',
                );
              } finally {
                if (!saved && ctx.mounted) {
                  setModalState(() => isSubmitting = false);
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: oldPhoneCtrl,
                      enabled: !isSubmitting && step == 0,
                      keyboardType: TextInputType.phone,
                      cursorColor: const Color(0xFF1F5A50),
                      decoration: _inputDecoration('Eski telefon raqam'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPhoneCtrl,
                      enabled: !isSubmitting && step == 0,
                      keyboardType: TextInputType.phone,
                      cursorColor: const Color(0xFF1F5A50),
                      decoration: _inputDecoration('Yangi telefon raqam'),
                    ),
                    if (step == 1) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: codeCtrl,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.number,
                        cursorColor: const Color(0xFF1F5A50),
                        decoration: _inputDecoration('SMS kod'),
                      ),
                    ],
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message!,
                        style: const TextStyle(
                          color: Color(0xFF1F5A50),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F5A50),
                          disabledBackgroundColor: const Color(
                            0xFF1F5A50,
                          ).withValues(alpha: 0.72),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : step == 0
                            ? requestCode
                            : verifyCode,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(step == 0 ? 'Kod olish' : 'Tasdiqlash'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      oldPhoneCtrl.dispose();
      newPhoneCtrl.dispose();
      codeCtrl.dispose();
    });
  }

  Widget _buildSignedOutFallback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openAuthPage();
    });

    return _buildLoadingState();
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.46,
      child: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFF1F5A50),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    if (_isCheckingSession) {
      return _buildLoadingState();
    }

    if (!_isLoggedIn) {
      return _buildSignedOutFallback();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF1F5A50),
                  backgroundImage: _avatarProvider,
                  child: _avatarProvider == null
                      ? Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profil',
                        style: TextStyle(
                          color: Color(0xFF8A9A97),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _name,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openEditProfile,
                  icon: const Icon(Icons.edit, color: primaryGreen, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_rounded, color: primaryGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Telefon raqam',
                        style: TextStyle(
                          color: Color(0xFF8A9A97),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _phone,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openEditPhone,
                  icon: const Icon(Icons.edit, color: primaryGreen, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            title: 'Mening buyurtmalarim',
            icon: Icons.receipt_long,
            badgeCount: _userReadyOrdersBadge,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              ).then((_) => _refreshUserOrdersBadge());
            },
          ),
          const SizedBox(height: 8),
          if (!_isAdmin)
            _ActionTile(
              title: "Do'kon ochish",
              icon: Icons.storefront_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OpenStoreScreen()),
                );
              },
            ),
          if (_isSeller) ...[
            const SizedBox(height: 8),
            _ActionTile(
              title: "Mening do'konlarim",
              icon: Icons.store_mall_directory_rounded,
              badgeCount: _sellerOrdersBadge,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyStoresScreen()),
                ).then((_) => _refreshSellerBadges());
              },
            ),
          ],
          if (_isAdmin) ...[
            const SizedBox(height: 8),
            _ActionTile(
              title: 'Boshqaruv paneli',
              icon: Icons.admin_panel_settings_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                );
              },
            ),
          ],
          const SizedBox(height: 8),
          if (kDebugMode)
            _ActionTile(
              title: 'Access token (copy)',
              icon: Icons.key_rounded,
              onTap: _copyAccessToken,
            ),
          if (kDebugMode) const SizedBox(height: 8),
          _ActionTile(
            title: _isSendingPushTest
                ? 'Push test yuborilmoqda...'
                : 'Push test',
            icon: Icons.notifications_active_rounded,
            onTap: _isSendingPushTest ? null : _sendPushTest,
          ),
          if ((_lastPushTestId ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Oxirgi test: $_lastPushTestId'
              '${_lastPushSuccessCount == null && _lastPushFailureCount == null ? '' : ' (ok: ${_lastPushSuccessCount ?? '-'}, fail: ${_lastPushFailureCount ?? '-'})'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6C7A78),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if ((_lastFcmTokenStatus ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _lastFcmTokenStatus!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6C7A78),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Chiqish',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String initials;
  final File? currentAvatar;
  final AuthApiService authApi;
  final Future<File?> Function() pickAvatarFile;
  final VoidCallback onInvalidSession;
  final void Function(AuthSession session, File? pickedAvatar) onSaved;

  const _EditProfileSheet({
    required this.initialName,
    required this.initials,
    required this.currentAvatar,
    required this.authApi,
    required this.pickAvatarFile,
    required this.onInvalidSession,
    required this.onSaved,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  File? _pickedAvatar;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_isSaving) return;
    final picked = await widget.pickAvatarFile();
    if (!mounted || picked == null) return;
    setState(() => _pickedAvatar = picked);
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    final nextName = _nameCtrl.text.trim().isEmpty
        ? widget.initialName
        : _nameCtrl.text.trim();

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final session = await widget.authApi.updateProfile(
        fullName: nextName,
        profileImg: _pickedAvatar,
      );
      if (!mounted) return;
      widget.onSaved(session, _pickedAvatar);
      Navigator.of(context).pop();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      if (AuthApiService.isInvalidSessionError(error)) {
        widget.onInvalidSession();
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _saveError = error.message;
        _isSaving = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _saveError = 'Server bilan bog‘lanib bo‘lmadi';
        _isSaving = false;
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

  @override
  Widget build(BuildContext context) {
    final localAvatar = _pickedAvatar ?? widget.currentAvatar;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Center(
              child: GestureDetector(
                onTap: _isSaving ? null : _pickAvatar,
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF1F5A50),
                  backgroundImage: localAvatar != null
                      ? FileImage(localAvatar)
                      : null,
                  child: localAvatar == null
                      ? Text(
                          widget.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              enabled: !_isSaving,
              cursorColor: const Color(0xFF1F5A50),
              decoration: _inputDecoration('Ism familiya'),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 8),
              Text(
                _saveError!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F5A50),
                  disabledBackgroundColor: const Color(
                    0xFF1F5A50,
                  ).withValues(alpha: 0.72),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Saqlash',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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

class _TopAuthNotification extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _TopAuthNotification({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, -24 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  const _ActionTile({
    required this.title,
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F5A50);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: primaryGreen, size: 20),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: _CountBadge(count: badgeCount),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: primaryGreen),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}
