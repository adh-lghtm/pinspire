import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/demo_data.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  void interests(BuildContext context) {
    final state = AppScope.read(context);
    final selected = state.interests.toSet();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Minatmu bisa berubah',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pilih kategori yang ingin kamu lihat lebih dulu.',
                style: TextStyle(color: PColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .skip(1)
                    .map(
                      (c) => FilterChip(
                        label: Text(c, style: const TextStyle(fontSize: 12)),
                        selected: selected.contains(c),
                        selectedColor: PColors.sage.withValues(alpha: .2),
                        checkmarkColor: PColors.sage,
                        onSelected: (value) => update(
                          () => value ? selected.add(c) : selected.remove(c),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          state.updateInterests(selected.toList());
                          Navigator.pop(ctx);
                          toast(context, 'Minat diperbarui');
                        },
                  child: const Text('Simpan minat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signOut(BuildContext context) async {
    final state = AppScope.read(context);
    await state.signOut();
    if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ContentWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 35),
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 10,
              ),
              leading: UserAvatar(
                name: state.profile.name,
                image: state.profile.avatar,
                size: 50,
              ),
              title: Text(
                state.profile.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                state.profile.email,
                style: const TextStyle(fontSize: 11, color: PColors.muted),
              ),
            ),
            const SizedBox(height: 25),
            const _Group('AKUN'),
            _row(
              Icons.person_outline_rounded,
              'Edit profil',
              'Nama, foto, dan cerita tentangmu',
              () => Navigator.pushNamed(context, '/edit-profile'),
            ),
            _row(
              Icons.interests_outlined,
              'Minat inspirasi',
              'Atur kategori pilihanmu',
              () => interests(context),
            ),
            const SizedBox(height: 23),
            const _Group('SUASANA & KABAR'),
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 3),
              secondary: const Icon(
                Icons.dark_mode_outlined,
                size: 21,
                color: PColors.muted,
              ),
              title: const Text(
                'Hitam pekat',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Gunakan latar hitam sebagai ganti charcoal.',
                style: TextStyle(fontSize: 10, color: PColors.muted),
              ),
              value: state.oled,
              onChanged: state.setOled,
            ),
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 3),
              secondary: const Icon(
                Icons.notifications_none_rounded,
                size: 21,
                color: PColors.muted,
              ),
              title: const Text(
                'Kabar di aplikasi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Tampilkan atau jeda notifikasi contoh.',
                style: TextStyle(fontSize: 10, color: PColors.muted),
              ),
              value: state.notificationsEnabled,
              onChanged: state.setNotifications,
            ),
            const SizedBox(height: 23),
            const _Group('DATA LOKAL'),
            _row(
              Icons.visibility_outlined,
              'Pulihkan rekomendasi',
              '${state.hiddenIds.length} pin disembunyikan',
              () {
                state.showHiddenPins();
                toast(context, 'Semua pin kembali ke rekomendasi');
              },
            ),
            _row(
              Icons.history_rounded,
              'Hapus riwayat pencarian',
              'Bersihkan kata yang pernah kamu cari',
              () {
                state.clearSearches();
                toast(context, 'Riwayat pencarian dihapus');
              },
            ),
            _row(
              Icons.restart_alt_rounded,
              'Reset aktivitas akun ini',
              'Kembalikan board, pin, dan aktivitas ke data awal',
              () async {
                final yes = await confirmAction(
                  context,
                  title: 'Reset aktivitas lokal?',
                  message: 'Pin buatanmu, komentar, pesan, dan perubahan board akun ini akan dihapus. Profil dan akun tetap tersimpan.',
                  action: 'Reset',
                );
                if (yes) {
                  await state.resetData();
                  if (context.mounted) {
                    toast(context, 'Aktivitas dikembalikan ke data awal');
                  }
                }
              },
            ),
            const SizedBox(height: 23),
            const _Group('PINSpIRE'),
            _row(
              Icons.auto_awesome_outlined,
              'Tentang Pinspire',
              'Cerita, fitur, dan sumber aset',
              () => Navigator.pushNamed(context, '/about'),
            ),
            _row(
              Icons.logout_rounded,
              'Keluar',
              'Aktivitas tetap tersimpan di perangkat ini',
              () => signOut(context),
            ),
            _row(
              Icons.delete_outline_rounded,
              'Hapus akun lokal',
              'Hapus profil dan aktivitas akun ini dari perangkat',
              () async {
                final yes = await confirmAction(
                  context,
                  title: 'Hapus akun lokal?',
                  message: 'Profil dan aktivitas akun ini akan dihapus dari perangkat. Data akun lokal ini tidak dapat dipulihkan.',
                  action: 'Hapus akun',
                );
                if (yes) {
                  await state.deleteLocalAccount();
                  if (context.mounted) {
                    Navigator.popUntil(context, (r) => r.isFirst);
                  }
                }
              },
              color: PColors.coral,
            ),
            const SizedBox(height: 35),
            const Center(
              child: Text(
                'Pinspire 1.0.0  ·  Made for curious minds. •',
                style: TextStyle(color: PColors.muted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action, {
    Color? color,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
    leading: Icon(icon, size: 21, color: color ?? PColors.muted),
    title: Text(
      title,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        subtitle,
        style: const TextStyle(fontSize: 10, color: PColors.muted, height: 1.6),
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: PColors.muted,
    ),
    onTap: action,
  );
}

class _Group extends StatelessWidget {
  const _Group(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 3),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: PColors.muted,
        fontSize: 9,
        letterSpacing: 2,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tentang Pinspire')),
    body: ContentWidth(
      maxWidth: 680,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Brand(large: true),
            const SizedBox(height: 30),
            const Text(
              'Temukan ide.\nSimpan cerita.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pinspire adalah proyek Mobile Development untuk mengumpulkan inspirasi visual. Alur penemuan ide, pin, dan board terinspirasi Pinterest, dengan identitas visual dan fitur suasana milik Pinspire.',
              style: TextStyle(color: PColors.muted, fontSize: 13, height: 1.9),
            ),
            const SizedBox(height: 25),
            const SmallLabel(
              'YANG MEMBUATNYA PINSpIRE',
              color: PColors.lavender,
            ),
            const SizedBox(height: 18),
            const Text(
              '•  Vibe: Calm, Warm, Bold, dan Fresh.\n•  Palet warna kurasi di setiap pin dan board.\n•  Tema charcoal dengan coral dan sage.\n•  Ruang koleksi yang tetap nyaman saat offline.',
              style: TextStyle(fontSize: 13, height: 2.1),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mode lokal',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 9),
            const Text(
              'Akun, unggahan, komentar, percakapan, dan kabar merupakan simulasi di perangkat ini. Data tidak tersinkron ke akun Pinterest maupun perangkat lain. Board rahasia ditandai privat dan tidak disertakan saat menyalin profil.',
              style: TextStyle(color: PColors.muted, height: 1.8, fontSize: 12),
            ),
            const SizedBox(height: 25),
            const Text(
              'Sumber aset',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 9),
            const Text(
              'Foto contoh: Unsplash. Font: Plus Jakarta Sans (SIL Open Font License). Identitas kreator, deskripsi, dan angka interaksi merupakan data contoh.',
              style: TextStyle(color: PColors.muted, height: 1.8, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await launchUrl(
                    Uri.parse('https://unsplash.com/license'),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {
                  if (context.mounted) {
                    toast(context, 'Tautan belum dapat dibuka.');
                  }
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Lisensi foto', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Pinspire',
                applicationVersion: '1.0.0',
              ),
              child: const Text(
                'Lisensi perangkat lunak',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
