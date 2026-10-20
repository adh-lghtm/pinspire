import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../state/app_state.dart';
import '../../widgets/board_card.dart';
import '../../widgets/board_sheets.dart';
import '../../widgets/common.dart';
import '../../widgets/pin_grid.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onDiscover, this.standalone = false});
  final VoidCallback? onDiscover;
  final bool standalone;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String tab = 'Board';
  void following() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) {
        final state = AppScope.of(ctx);
        final people = state.following;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kreator yang kamu ikuti',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              if (people.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 25),
                  child: Text(
                    'Belum ada kreator yang diikuti.',
                    style: TextStyle(color: PColors.muted),
                  ),
                ),
              ...people.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatar(name: c.name, image: c.avatar, size: 40),
                  title: Text(
                    c.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await state.toggleFollow(c.id);
                      update(() {});
                    },
                    child: const Text(
                      'Batal ikuti',
                      style: TextStyle(color: PColors.muted, fontSize: 10),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/creator', arguments: c.id);
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  Future<void> copyProfile() async {
    final state = AppScope.read(context);
    final public = state.boards
        .where((b) => !b.secret)
        .map((b) => '• ${b.title} (${b.pinIds.length} pin)')
        .join('\n');
    await Clipboard.setData(
      ClipboardData(
        text:
            '${state.profile.name} · @${state.profile.username}\n${state.profile.bio}\n\nBoard publik:\n$public\n\nPinspire •',
      ),
    );
    if (mounted) {
      toast(
        context,
        'Ringkasan profil disalin. Board rahasia tidak disertakan.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.profile;
    final content = ContentWidth(
      child: SingleChildScrollView(
        key: const PageStorageKey('profile-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Ruang pribadimu',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Semua board',
                  onPressed: () => Navigator.pushNamed(context, '/boards'),
                  icon: const Icon(Icons.dashboard_outlined, size: 22),
                ),
                IconButton(
                  tooltip: 'Pengaturan',
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  icon: const Icon(Icons.settings_outlined, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 19),
            SizedBox(
              height: 192,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 143,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const PinImage('assets/images/sunset.jpg'),
                          const ColoredBox(color: Color(0x50000000)),
                          Positioned(
                            right: 19,
                            top: 20,
                            child: Text(
                              'COLLECT MOMENTS.\nCREATE SOMETHING.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .9),
                                fontSize: 9,
                                letterSpacing: 1.9,
                                fontWeight: FontWeight.w800,
                                height: 1.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 17,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: UserAvatar(
                        name: user.name,
                        image: user.avatar,
                        size: 88,
                        color: PColors.coral,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 10,
                    bottom: 12,
                    child: SmallLabel('IDE COLLECTOR', color: PColors.lavender),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '@${user.username}',
              style: const TextStyle(color: PColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 13),
            if (user.bio.isNotEmpty)
              Text(
                user.bio,
                style: const TextStyle(
                  fontSize: 12,
                  color: PColors.muted,
                  height: 1.7,
                ),
              ),
            const SizedBox(height: 21),
            Row(
              children: [
                _stat(
                  '${state.savedPins.length}',
                  'Pin disimpan',
                  () => setState(() => tab = 'Tersimpan'),
                ),
                const SizedBox(width: 28),
                _stat(
                  '${state.boards.length}',
                  'Board',
                  () => setState(() => tab = 'Board'),
                ),
                const SizedBox(width: 28),
                _stat('${state.following.length}', 'Mengikuti', following),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/edit-profile'),
                    child: const Text(
                      'Edit profil',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  tooltip: 'Salin ringkasan profil',
                  onPressed: copyProfile,
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Board', 'Tersimpan', 'Dibuat', 'Disukai']
                    .map(
                      (t) => FilterPill(
                        label: t,
                        selected: tab == t,
                        onTap: () => setState(() => tab = t),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 22),
            if (tab == 'Board') ...[
              Row(
                children: [
                  const Text(
                    'Koleksi idemu',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => showBoardEditor(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Board baru',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.boards.isEmpty)
                EmptyState(
                  title: 'Buat tempat untuk ide baru',
                  message:
                      'Satu board bisa menjadi awal dari sesuatu yang menarik.',
                  icon: Icons.dashboard_outlined,
                  action: FilledButton(
                    onPressed: () => showBoardEditor(context),
                    child: const Text('Buat board'),
                  ),
                )
              else
                BoardGrid(boards: state.boards),
            ],
            if (tab == 'Tersimpan')
              (state.savedPins.isEmpty
                  ? EmptyState(
                      title: 'Simpan yang menginspirasimu',
                      message: 'Ketuk ikon bookmark pada pin untuk menambahkannya ke board.',
                      action: OutlinedButton(
                        onPressed:
                            widget.onDiscover ??
                            () => Navigator.pushNamed(context, '/search'),
                        child: const Text('Jelajahi inspirasi'),
                      ),
                    )
                  : PinGrid(pins: state.savedPins)),
            if (tab == 'Dibuat')
              (state.customPins.isEmpty
                  ? EmptyState(
                      title: 'Idemu layak dibagikan',
                      message: 'Buat pin dengan foto, cerita, dan Vibe milikmu sendiri.',
                      icon: Icons.add_photo_alternate_outlined,
                      action: FilledButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/create'),
                        child: const Text('Buat pin pertama'),
                      ),
                    )
                  : PinGrid(pins: state.customPins)),
            if (tab == 'Disukai')
              (state.likedPins.isEmpty
                  ? const EmptyState(
                      title: 'Yang kamu suka, ada di sini',
                      message: 'Ketuk ikon hati pada detail pin untuk mengisi koleksi ini.',
                      icon: Icons.favorite_border_rounded,
                    )
                  : PinGrid(pins: state.likedPins)),
          ],
        ),
      ),
    );
    return widget.standalone
        ? Scaffold(
            appBar: AppBar(title: const Text('Profil')),
            body: content,
          )
        : content;
  }

  Widget _stat(String count, String label, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: PColors.muted, fontSize: 9)),
      ],
    ),
  );
}

class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key, required this.creatorId});
  final String creatorId;
  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  bool loading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AppScope.read(context).loadCreatorPins(widget.creatorId);
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.creatorId == 'me') return const ProfileScreen(standalone: true);
    final state = AppScope.of(context);
    final creator = state.creator(widget.creatorId);
    final followed = state.followedIds.contains(widget.creatorId);
    final pins = state.pinsForCreator(widget.creatorId);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil kreator')),
      body: ContentWidth(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    UserAvatar(
                      name: creator.name,
                      image: creator.avatar,
                      size: 96,
                      color: Color(creator.color),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      creator.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '@${creator.username}',
                      style: const TextStyle(
                        color: PColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (creator.bio.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        creator.bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: PColors.muted,
                          height: 1.7,
                        ),
                      ),
                    ],
                    const SizedBox(height: 13),
                    Text(
                      '${pins.length} ide dikurasi · ${creator.followersCount} pengikut',
                      style: const TextStyle(
                        color: PColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton(
                          onPressed: () async {
                            await state.toggleFollow(widget.creatorId);
                            if (mounted) setState(() {});
                          },
                          child: Text(followed ? 'Mengikuti' : 'Ikuti kreator'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: widget.creatorId,
                          ),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 17,
                          ),
                          label: const Text(
                            'Pesan',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              const SectionHeading(
                title: 'Cara mereka melihat dunia',
                eyebrow: 'KOLEKSI PIN',
              ),
              const SizedBox(height: 22),
              if (loading && pins.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (pins.isEmpty)
                const EmptyState(
                  title: 'Belum ada pin',
                  message: 'Kreator ini belum membagikan inspirasi.',
                  icon: Icons.photo_library_outlined,
                )
              else
                PinGrid(pins: pins),
            ],
          ),
        ),
      ),
    );
  }
}
