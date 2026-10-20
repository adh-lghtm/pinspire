import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../services/media_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      username = TextEditingController(),
      bio = TextEditingController();
  String avatar = '';
  bool initialized = false, saving = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      final u = AppScope.read(context).profile;
      name.text = u.name;
      username.text = u.username;
      bio.text = u.bio;
      avatar = u.avatar;
      initialized = true;
    }
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> photo() async {
    try {
      final picked = await MediaService.pickPhoto();
      if (picked != null && mounted) setState(() => avatar = picked.dataUri);
    } on FormatException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (_) {
      if (mounted) {
        toast(context, 'Foto belum dapat dipilih. Periksa izin galeri.');
      }
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    final state = AppScope.read(context);
    try {
      await state.updateProfile(
        state.profile.copyWith(
          name: name.text.trim(),
          username: username.text.trim().toLowerCase(),
          bio: bio.text.trim(),
          avatar: avatar,
        ),
      );
      if (!mounted) return;
      if (state.storageError != null) {
        toast(context, state.storageError!);
        setState(() => saving = false);
        return;
      }
      Navigator.pop(context);
      toast(context, 'Profil diperbarui');
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        toast(context, 'Profil belum dapat disimpan. Coba lagi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profil')),
    body: ContentWidth(
      maxWidth: 580,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    UserAvatar(
                      name: name.text,
                      image: avatar,
                      size: 100,
                      color: PColors.coral,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: photo,
                      icon: const Icon(Icons.photo_camera_outlined, size: 17),
                      label: const Text(
                        'Ganti foto',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (avatar.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => avatar = ''),
                        child: const Text(
                          'Hapus foto',
                          style: TextStyle(color: PColors.muted, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: name,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Nama tampilan'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => requiredText(v, 'Nama'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: username,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                ),
                validator: (v) =>
                    RegExp(r'^[a-zA-Z0-9_.]{3,24}$').hasMatch(v ?? '')
                    ? null
                    : '3–24 karakter: huruf, angka, titik, atau garis bawah',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: bio,
                maxLength: 160,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Tentang kamu'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 15),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Email akun'),
                child: Text(
                  AppScope.read(context).profile.email,
                  style: const TextStyle(color: PColors.muted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Menyimpan...' : 'Simpan perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
