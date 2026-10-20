import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/pin_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSearch});
  final VoidCallback onSearch;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String category = 'Semua', vibe = 'Semua', sort = 'Relevan';
  bool following = false;
  int edition = 0;
  Future<void> refresh() async {
    setState(() => edition++);
  }

  void chooseVibe() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ikuti suasana hatimu',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          const Text(
            'Vibe mengelompokkan pin berdasarkan nuansanya.',
            style: TextStyle(color: PColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 23),
          Wrap(
            runSpacing: 12,
            children: vibes
                .map(
                  (v) => FilterPill(
                    label: v,
                    selected: vibe == v,
                    color: PColors.lavender,
                    onTap: () {
                      setState(() => vibe = v);
                      Navigator.pop(ctx);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    var pins = state.discover(
      category: category,
      vibe: vibe,
      following: following,
      sort: sort,
    );
    if (edition > 0 && sort == 'Relevan' && pins.isNotEmpty) {
      final offset = edition % pins.length;
      pins = [...pins.skip(offset), ...pins.take(offset)];
    }
    return RefreshIndicator(
      color: PColors.coral,
      onRefresh: refresh,
      child: SingleChildScrollView(
        key: const PageStorageKey('home-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Brand(),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Cari inspirasi',
                      onPressed: widget.onSearch,
                      icon: const Icon(Icons.search_rounded, size: 23),
                    ),
                    Badge(
                      isLabelVisible: state.unreadCount > 0,
                      label: Text('${state.unreadCount}'),
                      backgroundColor: PColors.coral,
                      textColor: PColors.background,
                      child: IconButton(
                        tooltip: 'Notifikasi',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/notifications'),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  'SELAMAT DATANG, ${state.profile.name.split(' ').first.toUpperCase()}',
                  style: const TextStyle(
                    color: PColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 11),
                const Text(
                  'Sedikit ide,\nbanyak kemungkinan.',
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.15,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => setState(() {
                    category = 'Interior';
                    vibe = 'Calm';
                    following = false;
                  }),
                  child: Semantics(
                    button: true,
                    label: 'Jelajahi koleksi interior Calm',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 174,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const Positioned(
                              left: 100,
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: PinImage(
                                'assets/images/living.jpg',
                                alignment: Alignment.centerRight,
                              ),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF292F2A),
                                    Color(0xF0292F2A),
                                    Color(0x10292F2A),
                                  ],
                                  stops: [0, .4, 1],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'THE SLOW EDIT',
                                    style: TextStyle(
                                      color: PColors.sage,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Ruang tenang,\npikiran lapang.',
                                    style: TextStyle(
                                      fontSize: 23,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -.7,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Lihat koleksi',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: Colors.white.withValues(
                                          alpha: .8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    _tab(
                      'Untukmu',
                      !following,
                      () => setState(() => following = false),
                    ),
                    const SizedBox(width: 23),
                    _tab(
                      'Mengikuti',
                      following,
                      () => setState(() => following = true),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Urutkan pin',
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: PColors.muted,
                        size: 20,
                      ),
                      initialValue: sort,
                      onSelected: (value) => setState(() => sort = value),
                      itemBuilder: (_) => ['Relevan', 'Populer', 'Terbaru']
                          .map((v) => PopupMenuItem(value: v, child: Text(v)))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterPill(
                        label: vibe == 'Semua' ? 'Vibe' : vibe,
                        selected: vibe != 'Semua',
                        onTap: chooseVibe,
                        icon: Icons.auto_awesome_rounded,
                        color: PColors.lavender,
                      ),
                      ...categories.map(
                        (c) => FilterPill(
                          label: c,
                          selected: c == category,
                          onTap: () => setState(() => category = c),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      following
                          ? 'Dari kreator pilihanmu'
                          : 'Ditemukan untukmu',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${pins.length} ide',
                      style: const TextStyle(
                        color: PColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                if (pins.isEmpty)
                  EmptyState(
                    title: following
                        ? 'Belum ada inspirasi di sini'
                        : 'Belum ada pin untuk filter ini',
                    message: following
                        ? 'Ikuti kreator dari halaman detail pin, atau gunakan filter lain.'
                        : 'Coba kategori atau Vibe yang berbeda.',
                    action: OutlinedButton(
                      onPressed: () => setState(() {
                        category = 'Semua';
                        vibe = 'Semua';
                        following = false;
                      }),
                      child: const Text('Lihat semua ide'),
                    ),
                  )
                else
                  PinGrid(pins: pins),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '•  Ide bagus layak menemukan tempatnya.',
                    style: TextStyle(
                      color: PColors.muted.withValues(alpha: .7),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String title, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: selected ? PColors.text : PColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: selected ? 24 : 0,
              decoration: BoxDecoration(
                color: PColors.coral,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );
}
