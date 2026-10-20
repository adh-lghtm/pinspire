import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../state/app_state.dart';
import '../../widgets/board_sheets.dart';
import '../../widgets/common.dart';
import '../../widgets/pin_grid.dart';

class BoardDetailScreen extends StatefulWidget {
  const BoardDetailScreen({super.key, required this.boardId});
  final String boardId;
  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  bool popular = false;
  Future<void> menu(String value) async {
    final state = AppScope.read(context);
    final board = state.boardById(widget.boardId);
    if (board == null) return;
    if (value == 'edit') {
      await showBoardEditor(context, board: board);
      return;
    }
    if (value == 'delete') {
      final yes = await confirmAction(
        context,
        title: 'Hapus board ini?',
        message:
            'Board “${board.title}” akan dihapus. Pin buatanmu tetap ada di profil.',
      );
      if (yes && mounted) {
        state.deleteBoard(board.id);
        Navigator.pop(context);
      }
    }
  }

  void addPins() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddPins(boardId: widget.boardId),
  );
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final board = state.boardById(widget.boardId);
    if (board == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          title: 'Board sudah dihapus',
          message: 'Kembali ke profil untuk melihat koleksi lainnya.',
        ),
      );
    }
    final pins = state.pinsInBoard(board);
    if (popular) pins.sort((a, b) => b.likes.compareTo(a.likes));
    final palette = pins.expand((p) => p.palette).toSet().take(5).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Board'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Pengaturan board',
            onSelected: menu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit board')),
              PopupMenuItem(value: 'delete', child: Text('Hapus board')),
            ],
          ),
        ],
      ),
      body: ContentWidth(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SmallLabel(
                    board.secret ? 'BOARD RAHASIA' : 'BOARD INSPIRASI',
                    color: board.secret ? PColors.lavender : PColors.sage,
                  ),
                  const Spacer(),
                  Icon(
                    board.secret
                        ? Icons.lock_outline_rounded
                        : Icons.dashboard_outlined,
                    color: PColors.muted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                board.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.2,
                ),
              ),
              if (board.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  board.description,
                  style: const TextStyle(
                    color: PColors.muted,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  UserAvatar(
                    name: state.profile.name,
                    image: state.profile.avatar,
                    size: 28,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    state.profile.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text('  ·  ', style: TextStyle(color: PColors.muted)),
                  Text(
                    '${pins.length} pin',
                    style: const TextStyle(color: PColors.muted, fontSize: 11),
                  ),
                ],
              ),
              if (palette.isNotEmpty) ...[
                const SizedBox(height: 25),
                const Text(
                  'PALET BOARD · KURASI',
                  style: TextStyle(
                    color: PColors.muted,
                    fontSize: 9,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: PaletteBar(palette, height: 30),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: addPins,
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('Tambahkan pin'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    tooltip: popular
                        ? 'Urutkan sesuai simpan'
                        : 'Urutkan terpopuler',
                    onPressed: () => setState(() => popular = !popular),
                    icon: Icon(
                      Icons.sort_rounded,
                      color: popular ? PColors.coral : PColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              if (pins.isEmpty)
                EmptyState(
                  title: 'Board ini menunggu cerita',
                  message: 'Tambahkan pin dari koleksi inspirasi atau buat pinmu sendiri.',
                  icon: Icons.dashboard_outlined,
                  action: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/create',
                      arguments: board.id,
                    ),
                    child: const Text('Buat pin baru'),
                  ),
                )
              else
                PinGrid(pins: pins, boardId: board.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPins extends StatefulWidget {
  const _AddPins({required this.boardId});
  final String boardId;
  @override
  State<_AddPins> createState() => _AddPinsState();
}

class _AddPinsState extends State<_AddPins> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final board = state.boardById(widget.boardId);
    final pins = state.pins
        .where(
          (p) => '${p.title} ${p.category}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambahkan inspirasi',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari dalam semua pin',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: pins.isEmpty
                  ? const EmptyState(
                      title: 'Pin belum ditemukan',
                      message: 'Coba kata pencarian lain.',
                    )
                  : ListView.builder(
                      itemCount: pins.length,
                      itemBuilder: (context, i) {
                        final p = pins[i];
                        final selected = board?.pinIds.contains(p.id) ?? false;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 5,
                          ),
                          leading: SizedBox(
                            width: 50,
                            height: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: PinImage(p.image),
                            ),
                          ),
                          title: Text(
                            p.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            p.category,
                            style: const TextStyle(
                              color: PColors.muted,
                              fontSize: 10,
                            ),
                          ),
                          trailing: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            color: selected ? PColors.sage : PColors.muted,
                          ),
                          onTap: () =>
                              state.toggleBoardPin(widget.boardId, p.id),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Selesai · ${board?.pinIds.length ?? 0} pin'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
