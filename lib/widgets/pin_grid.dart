import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'board_sheets.dart';
import 'common.dart';

class PinGrid extends StatelessWidget {
  const PinGrid({super.key, required this.pins, this.onOpen, this.boardId});
  final List<Pin> pins;
  final ValueChanged<String>? onOpen;
  final String? boardId;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final count = box.maxWidth < 600
          ? 2
          : box.maxWidth < 850
          ? 3
          : box.maxWidth < 1100
          ? 4
          : 5;
      const gap = 12.0;
      final width = (box.maxWidth - gap * (count - 1)) / count;
      final columns = List.generate(count, (_) => <Pin>[]);
      final heights = List.filled(count, 0.0);
      for (final pin in pins) {
        int target = 0;
        for (int i = 1; i < count; i++) {
          if (heights[i] < heights[target]) target = i;
        }
        columns[target].add(pin);
        heights[target] += width / pin.aspectRatio + 70;
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          count,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : gap / 2,
                right: i == count - 1 ? 0 : gap / 2,
              ),
              child: Column(
                children: columns[i]
                    .map(
                      (pin) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: PinCard(
                          pin: pin,
                          boardId: boardId,
                          onOpen: onOpen,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class PinCard extends StatelessWidget {
  const PinCard({super.key, required this.pin, this.onOpen, this.boardId});
  final Pin pin;
  final String? boardId;
  final ValueChanged<String>? onOpen;
  Future<void> options(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) {
      final state = AppScope.of(ctx);
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                pin.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Pilihan pin'),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add_outlined),
              title: const Text('Simpan ke board'),
              onTap: () {
                Navigator.pop(ctx);
                showSaveSheet(context, pin.id);
              },
            ),
            if (boardId != null)
              ListTile(
                leading: const Icon(Icons.bookmark_remove_outlined),
                title: const Text('Keluarkan dari board ini'),
                onTap: () {
                  state.removeFromBoard(boardId!, pin.id);
                  Navigator.pop(ctx);
                  toast(context, 'Pin dikeluarkan dari board');
                },
              ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Sembunyikan dari rekomendasi'),
              onTap: () {
                state.hidePin(pin.id);
                Navigator.pop(ctx);
                toast(
                  context,
                  'Pin disembunyikan. Pulihkan melalui Pengaturan.',
                );
              },
            ),
          ],
        ),
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final author = state.creator(pin.authorId);
    final saved = state.isSaved(pin.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onOpen != null
              ? onOpen!(pin.id)
              : Navigator.pushNamed(context, '/pin', arguments: pin.id),
          onLongPress: () => options(context),
          child: Semantics(
            button: true,
            label: 'Buka pin ${pin.title}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: pin.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PinImage(pin.image),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 75,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x65000000)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 11,
                      child: Text(
                        pin.vibe.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Material(
                        color: Colors.black.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(25),
                        child: IconButton(
                          tooltip: saved
                              ? 'Atur board ${pin.title}'
                              : 'Simpan ${pin.title}',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: () => showSaveSheet(context, pin.id),
                          icon: Icon(
                            saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 19,
                            color: saved ? PColors.sage : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 3, top: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  pin.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ),
              SizedBox(
                width: 24,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Pilihan ${pin.title}',
                  onPressed: () => options(context),
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: PColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 3, top: 5),
          child: Row(
            children: [
              UserAvatar(
                name: author.name,
                image: author.avatar,
                size: 17,
                color: Color(author.color),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  author.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: PColors.muted, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
