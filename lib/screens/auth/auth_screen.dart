import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      confirmation = TextEditingController();
  bool register = false, obscure = true, busy = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit({bool demo = false}) async {
    if (!demo && !form.currentState!.validate()) return;
    setState(() => busy = true);
    final state = AppScope.read(context);
    try {
      final profile = demo
          ? await state.auth.login(
              AuthService.demoEmail,
              AuthService.demoPassword,
            )
          : register
          ? await state.auth.register(name.text, email.text, password.text)
          : await state.auth.login(email.text, password.text);
      await state.signIn(profile);
    } on FormatException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (_) {
      if (mounted) {
        toast(
          context,
          'Data lokal belum dapat disimpan. Periksa ruang penyimpanan lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void help() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bantuan masuk',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Akun contoh',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const SelectableText(
            'Email: demo@pinspire.app\nKata sandi: Pinspire123!',
            style: TextStyle(color: PColors.sage, height: 1.8),
          ),
          const SizedBox(height: 16),
          const Text(
            'Akun tambahan hanya tersimpan di perangkat ini. Pemulihan melalui email belum tersedia pada versi lokal.',
            style: TextStyle(color: PColors.muted, height: 1.6),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ContentWidth(
        maxWidth: 1000,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 35, 24, 30),
          child: LayoutBuilder(
            builder: (context, box) {
              final fields = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Brand(large: true),
                  const SizedBox(height: 38),
                  Text(
                    register
                        ? 'Awal dari banyak ide.'
                        : 'Senang melihatmu\nkembali.',
                    style: const TextStyle(
                      fontSize: 33,
                      height: 1.16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    register
                        ? 'Buat profil dan mulai koleksi inspirasimu.'
                        : 'Inspirasi berikutnya menunggumu.',
                    style: const TextStyle(color: PColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: form,
                    child: Column(
                      children: [
                        if (register) ...[
                          TextFormField(
                            controller: name,
                            maxLength: 40,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => requiredText(v, 'Nama'),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              size: 20,
                            ),
                          ),
                          validator: validEmail,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: password,
                          obscureText: obscure,
                          maxLength: 72,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Kata sandi',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              tooltip: obscure
                                  ? 'Tampilkan kata sandi'
                                  : 'Sembunyikan kata sandi',
                              onPressed: () =>
                                  setState(() => obscure = !obscure),
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (v) => (v?.length ?? 0) < 8
                              ? 'Gunakan minimal 8 karakter'
                              : null,
                        ),
                        if (register) ...[
                          if (password.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  Icon(
                                    password.text.length >= 8
                                        ? Icons.check_circle_rounded
                                        : Icons.info_outline_rounded,
                                    size: 15,
                                    color: password.text.length >= 8
                                        ? PColors.sage
                                        : PColors.muted,
                                  ),
                                  const SizedBox(width: 7),
                                  const Text(
                                    'Minimal 8 karakter',
                                    style: TextStyle(
                                      color: PColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          TextFormField(
                            controller: confirmation,
                            obscureText: obscure,
                            decoration: const InputDecoration(
                              labelText: 'Konfirmasi kata sandi',
                            ),
                            validator: (v) => v != password.text
                                ? 'Kata sandi belum sama'
                                : null,
                          ),
                          const SizedBox(height: 18),
                        ],
                      ],
                    ),
                  ),
                  if (!register)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: help,
                        child: const Text(
                          'Bantuan masuk',
                          style: TextStyle(fontSize: 12, color: PColors.muted),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : () => submit(),
                      child: Text(
                        busy
                            ? 'Memproses...'
                            : register
                            ? 'Buat profil lokal'
                            : 'Masuk',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : () => submit(demo: true),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                      label: const Text('Jelajahi dengan akun demo'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              setState(() => register = !register);
                              form.currentState?.reset();
                            },
                      child: Text(
                        register
                            ? 'Sudah punya profil? Masuk'
                            : 'Belum punya profil? Daftar',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Versi tugas kuliah • akun dan aktivitas tersimpan lokal. Gunakan data percobaan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PColors.muted,
                      fontSize: 10,
                      height: 1.7,
                    ),
                  ),
                ],
              );
              if (box.maxWidth < 780) {
                return ContentWidth(maxWidth: 440, child: fields);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 50, top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: const SizedBox(
                          height: 680,
                          child: PinImage('assets/images/interior.jpg'),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 420, child: fields),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
