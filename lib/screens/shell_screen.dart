import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../services/media_service.dart';
import '../widgets/common.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'profile/profile_screen.dart';
import 'inbox/inbox_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;
  void select(int value) => setState(() => index = value);
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 940;
    final pages = IndexedStack(
      index: index,
      children: [
        HomeScreen(onSearch: () => select(1)),
        const SearchScreen(),
        const InboxScreen(),
        ProfileScreen(onDiscover: () => select(0)),
      ],
    );
    final content = Column(
      children: [
        if (MediaService.recoveredPhoto != null)
          MaterialBanner(
            content: const Text(
              'Gambar pilihan sebelumnya berhasil dipulihkan.',
              style: TextStyle(fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/create'),
                child: const Text('Lanjutkan pin'),
              ),
            ],
          ),
        if (state.storageError != null)
          MaterialBanner(
            content: Text(
              state.storageError!,
              style: const TextStyle(fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  state.storageError = null;
                  setState(() {});
                },
                child: const Text('Tutup'),
              ),
            ],
          ),
        Expanded(child: pages),
      ],
    );
    return Scaffold(
      body: wide
          ? Row(
              children: [
                Container(
                  width: 210,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: PColors.border, width: .6),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 46),
                            child: Brand(),
                          ),
                          _railItem(
                            'Beranda',
                            Icons.home_outlined,
                            Icons.home_rounded,
                            0,
                          ),
                          _railItem(
                            'Jelajah',
                            Icons.search_rounded,
                            Icons.search_rounded,
                            1,
                          ),
                          _railItem(
                            'Pesan',
                            Icons.chat_bubble_outline_rounded,
                            Icons.chat_bubble_rounded,
                            2,
                          ),
                          _railItem(
                            'Profil',
                            Icons.person_outline_rounded,
                            Icons.person_rounded,
                            3,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/create'),
                              icon: const Icon(Icons.add_rounded, size: 19),
                              label: const Text('Buat pin'),
                            ),
                          ),
                          const Spacer(),
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'A LITTLE INSPIRATION,\nEVERY DAY.',
                              style: TextStyle(
                                color: PColors.muted,
                                fontSize: 9,
                                height: 1.8,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            leading: UserAvatar(
                              name: state.profile.name,
                              image: state.profile.avatar,
                              size: 34,
                            ),
                            title: Text(
                              state.profile.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.settings_outlined,
                              size: 18,
                            ),
                            onTap: () =>
                                Navigator.pushNamed(context, '/settings'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            )
          : SafeArea(bottom: false, child: content),
      bottomNavigationBar: wide
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: PColors.surface,
                border: Border(
                  top: BorderSide(color: PColors.border, width: .6),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _nav(
                        'Beranda',
                        Icons.home_outlined,
                        Icons.home_rounded,
                        0,
                      ),
                      _nav(
                        'Jelajah',
                        Icons.search_rounded,
                        Icons.search_rounded,
                        1,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 44,
                              width: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(44, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/create'),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 26,
                                  semanticLabel: 'Buat pin',
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Buat',
                              style: TextStyle(
                                color: PColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _nav(
                        'Pesan',
                        Icons.chat_bubble_outline_rounded,
                        Icons.chat_bubble_rounded,
                        2,
                      ),
                      _nav(
                        'Profil',
                        Icons.person_outline_rounded,
                        Icons.person_rounded,
                        3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _railItem(String label, IconData normal, IconData active, int value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: index == value
              ? PColors.coral.withValues(alpha: .12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Icon(
              index == value ? active : normal,
              color: index == value ? PColors.coral : PColors.muted,
              size: 22,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: index == value ? PColors.coral : PColors.muted,
              ),
            ),
            onTap: () => select(value),
          ),
        ),
      );
  Widget _nav(String label, IconData normal, IconData active, int value) =>
      Expanded(
        child: Semantics(
          selected: index == value,
          button: true,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => select(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    index == value ? active : normal,
                    size: 24,
                    color: index == value ? PColors.coral : PColors.muted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: index == value ? PColors.coral : PColors.muted,
                      fontSize: 9,
                      fontWeight: index == value
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
