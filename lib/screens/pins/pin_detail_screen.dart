import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/image_sources.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/board_sheets.dart';
import '../../widgets/common.dart';
import '../../widgets/pin_grid.dart';

class PinDetailScreen extends StatefulWidget {
  const PinDetailScreen({super.key, required this.pinId});
  final String pinId;
  @override
  State<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends State<PinDetailScreen> {
  final comment = TextEditingController();
  final commentSection = GlobalKey();
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  String shareText(Pin pin) {
    final source = pin.sourceUrl.isNotEmpty
        ? pin.sourceUrl
        : imageSources[pin.image] ?? '';
    return '${pin.title}\n\n${pin.description}\n${source.isEmpty ? '' : '\n$source'}\n\nDisimpan dengan Pinspire •';
  }

  Future<void> share(Pin pin) async {
    final box = context.findRenderObject() as RenderBox?;
    final rect = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText(pin),
          subject: pin.title,
          sharePositionOrigin: rect,
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareText(pin)));
      if (mounted) {
        toast(context, 'Teks pin disalin. Tempel ke aplikasi pilihanmu.');
      }
    }
  }

  Future<void> openSource(Pin pin) async {
    final url = pin.sourceUrl.isNotEmpty
        ? pin.sourceUrl
        : imageSources[pin.image];
    if (url == null) return;
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) toast(context, 'Tautan belum dapat dibuka.');
    } catch (_) {
      if (mounted) toast(context, 'Tautan belum dapat dibuka.');
    }
  }

  void more(Pin pin) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: const Text('Salin teks pin'),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: shareText(pin)));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) toast(context, 'Teks pin disalin');
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: const Text('Sembunyikan dari rekomendasi'),
            onTap: () {
              AppScope.read(context).hidePin(pin.id);
              Navigator.pop(ctx);
              toast(context, 'Pin disembunyikan dari rekomendasi');
            },
          ),
          if (pin.authorId == 'me')
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit pin'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/edit-pin', arguments: pin.id);
              },
            ),
          if (pin.authorId == 'me')
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: PColors.coral,
              ),
              title: const Text('Hapus pin ini'),
              onTap: () async {
                Navigator.pop(ctx);
                final yes = await confirmAction(
                  context,
                  title: 'Hapus pin?',
                  message: 'Pin ini akan dihapus dari profil dan semua board milikmu.',
                );
                if (yes && mounted) {
                  AppScope.read(context).deletePin(pin.id);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pin = state.pinById(widget.pinId);
    if (pin == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          title: 'Pin sudah dihapus',
          message: 'Kembali untuk menjelajahi inspirasi lainnya.',
        ),
      );
    }
    final author = state.creator(pin.authorId);
    final liked = state.likedIds.contains(pin.id),
        saved = state.isSaved(pin.id),
        followed = state.followedIds.contains(author.id);
    final comments = state.commentsFor(pin.id);
    final related = state
        .discover(category: pin.category)
        .where((p) => p.id != pin.id)
        .toList();
    final image = GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/image', arguments: pin.image),
      child: Semantics(
        button: true,
        label: 'Perbesar gambar',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AspectRatio(
            aspectRatio: pin.aspectRatio.clamp(.66, 1.3),
            child: PinImage(pin.image),
          ),
        ),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SmallLabel(pin.category),
            const SizedBox(width: 8),
            SmallLabel(pin.vibe, color: PColors.lavender),
            const Spacer(),
            IconButton(
              tooltip: 'Bagikan pin',
              onPressed: () => share(pin),
              icon: const Icon(Icons.ios_share_rounded, size: 21),
            ),
            IconButton(
              tooltip: 'Pilihan pin',
              onPressed: () => more(pin),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          pin.title,
          style: const TextStyle(
            fontSize: 29,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          pin.description,
          style: const TextStyle(
            color: PColors.muted,
            height: 1.8,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/creator',
                  arguments: author.id,
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      name: author.name,
                      image: author.avatar,
                      color: Color(author.color),
                      size: 42,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${author.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (author.id != 'me')
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(70, 38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 9,
                  ),
                ),
                onPressed: () => state.toggleFollow(author.id),
                child: Text(
                  followed ? 'Mengikuti' : 'Ikuti',
                  style: TextStyle(
                    fontSize: 11,
                    color: followed ? PColors.sage : PColors.text,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: liked ? 'Batal suka' : 'Suka pin',
              style: IconButton.styleFrom(
                backgroundColor: liked
                    ? PColors.coral.withValues(alpha: .15)
                    : PColors.surface,
              ),
              onPressed: () => state.toggleLike(pin.id),
              icon: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? PColors.coral : PColors.muted,
                size: 22,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              compactNumber(pin.likes + (liked ? 1 : 0)),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => showSaveSheet(context, pin.id),
              icon: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 18,
              ),
              label: Text(saved ? 'Tersimpan' : 'Simpan pin'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: PColors.surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: PColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.palette_outlined,
                    size: 17,
                    color: PColors.lavender,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Palet kurasi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Salin kode warna',
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text: pin.palette
                              .map(
                                (c) =>
                                    '#${c.toRadixString(16).substring(2).toUpperCase()}',
                              )
                              .join(', '),
                        ),
                      );
                      if (context.mounted) toast(context, 'Kode warna disalin');
                    },
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: PColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: PaletteBar(pin.palette, height: 38, showCodes: true),
              ),
            ],
          ),
        ),
        if (pin.sourceUrl.isNotEmpty || imageSources.containsKey(pin.image))
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: TextButton.icon(
              onPressed: () => openSource(pin),
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: PColors.muted,
              ),
              label: Text(
                pin.sourceUrl.isEmpty
                    ? 'Lihat sumber foto'
                    : 'Kunjungi tautan sumber',
                style: const TextStyle(color: PColors.muted, fontSize: 11),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pin.tags
              .map(
                (tag) => ActionChip(
                  label: Text(
                    '#$tag',
                    style: const TextStyle(fontSize: 10, color: PColors.muted),
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/search', arguments: tag),
                ),
              )
              .toList(),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspirasi, lebih dekat'),
        actions: [
          IconButton(
            tooltip: 'Komentar',
            onPressed: () {
              final ctx = commentSection.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(
                  ctx,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                );
              }
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 21),
          ),
        ],
      ),
      body: ContentWidth(
        maxWidth: 1050,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, box) => box.maxWidth > 740
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: image),
                          const SizedBox(width: 30),
                          Expanded(child: details),
                        ],
                      )
                    : Column(
                        children: [image, const SizedBox(height: 19), details],
                      ),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 15),
              Row(
                key: commentSection,
                children: [
                  Text(
                    'Obrolan ide',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SmallLabel('${comments.length}', color: PColors.lavender),
                ],
              ),
              const SizedBox(height: 15),
              if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Text(
                    'Apa yang menginspirasimu dari pin ini? Jadilah yang pertama berbagi.',
                    style: TextStyle(
                      color: PColors.muted,
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                ),
              ...comments.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        name: state.creator(c.author).name,
                        image: state.creator(c.author).avatar,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.creator(c.author).name} · ${dateLabel(c.createdAt)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: PColors.muted,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              c.text,
                              style: const TextStyle(fontSize: 12, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      if (c.author == 'me')
                        IconButton(
                          tooltip: 'Hapus komentar',
                          onPressed: () => state.deleteComment(c.id),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: PColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: comment,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Bagikan pendapatmu...',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: IconButton.filled(
                      tooltip: 'Kirim komentar',
                      onPressed: () {
                        if (comment.text.trim().isEmpty) return;
                        state.addComment(pin.id, comment.text);
                        comment.clear();
                        FocusScope.of(context).unfocus();
                      },
                      icon: const Icon(Icons.arrow_upward_rounded, size: 21),
                    ),
                  ),
                ],
              ),
              if (related.isNotEmpty) ...[
                const SizedBox(height: 32),
                const SectionHeading(
                  title: 'Masih satu frekuensi',
                  eyebrow: 'LANJUTKAN MENJELAJAH',
                ),
                const SizedBox(height: 20),
                PinGrid(pins: related),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.image});
  final String image;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      title: const Text('Lihat lebih dekat'),
    ),
    body: Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            minScale: .8,
            maxScale: 5,
            child: Center(
              child: SizedBox.expand(
                child: PinImage(image, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Cubit atau gulir untuk memperbesar',
              style: TextStyle(color: PColors.muted, fontSize: 11),
            ),
          ),
        ),
      ],
    ),
  );
}
