import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hello_flutter_app/screens/orders_screen.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Akmal Karimov';
  String _phone = '+998 90 123 45 67';
  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();

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

  Future<File?> _pickAvatarFile() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return null;
    return File(file.path);
  }

  void _openEditProfile() {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    _showFastBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                const SizedBox(height: 4),
                StatefulBuilder(
                  builder: (context, setModalState) {
                    File? localAvatar = _avatarFile;
                    return Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await _pickAvatarFile();
                          if (picked == null) return;
                          setState(() => _avatarFile = picked);
                          setModalState(() => localAvatar = picked);
                        },
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF0F2F2B),
                          backgroundImage: localAvatar != null
                              ? FileImage(localAvatar!)
                              : null,
                          child: localAvatar == null
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
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ism familiya',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon raqam',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2F2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _name = nameCtrl.text.trim().isEmpty
                            ? _name
                            : nameCtrl.text.trim();
                        _phone = phoneCtrl.text.trim().isEmpty
                            ? _phone
                            : phoneCtrl.text.trim();
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text(
                      'Saqlash',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);

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
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: primaryGreen.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF0F2F2B),
                  backgroundImage:
                      _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null
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
                      Text(
                        _name,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _phone,
                        style: const TextStyle(
                          color: Color(0xFF8A9A97),
                          fontSize: 12,
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
          const SizedBox(height: 12),
          _ActionTile(
            title: 'Mening buyurtmalarim',
            icon: Icons.receipt_long,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withOpacity(0.5)),
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

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionTile({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F2F2B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryGreen.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryGreen, size: 20),
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
