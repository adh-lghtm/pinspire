import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'common.dart';

Future<String?> showBoardEditor(BuildContext context, {Board? board}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BoardEditor(board: board),
    );

class _BoardEditor extends StatefulWidget {
  const _BoardEditor({this.board});
  final Board? board;
  @override
  State<_BoardEditor> createState() => _BoardEditorState();
}

class _BoardEditorState extends State<_BoardEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, description;
  late bool secret;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.board?.title);
    description = TextEditingController(text: widget.board?.description);
    secret = widget.board?.secret ?? false;
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  void save() {
    if (!form.currentState!.validate()) return;
    final state = AppScope.read(context);
    final board = widget.board;
    String id;
    if (board == null) {
      id = state.createBoard(name.text, description.text, secret);
    } else {
      id = board.id;
      state.editBoard(
        board.copyWith(
          title: name.text.trim(),
          description: description.text.trim(),
          secret: secret,
        ),
      );
    }
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      0,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.board == null ? 'Beri tempat untuk idemu' : 'Edit board',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kumpulkan pin dalam satu cerita.',
              style: TextStyle(color: PColors.muted),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              maxLength: 45,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nama board',
                hintText: 'Contoh: Ruang untuk pulang',
              ),
              validator: (v) => requiredText(v, 'Nama board'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: description,
              maxLength: 180,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Board rahasia',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Ditandai privat di profil lokalmu.',
                style: TextStyle(color: PColors.muted, fontSize: 12),
              ),
              value: secret,
              onChanged: (v) => setState(() => secret = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: save,
                child: Text(
                  widget.board == null ? 'Buat board' : 'Simpan perubahan',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showSaveSheet(BuildContext context, String pinId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SaveSheet(pinId: pinId),
    );

class _SaveSheet extends StatelessWidget {
  const _SaveSheet({required this.pinId});
  final String pinId;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .78,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 6),
            child: Text(
              'Simpan ke board',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pin yang sama dapat ada di beberapa board.',
              style: TextStyle(color: PColors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: state.boards.map((board) {
                final saved = board.pinIds.contains(pinId);
                final pins = state.pinsInBoard(board);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 5,
                  ),
                  leading: SizedBox(
                    width: 52,
                    height: 58,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: pins.isEmpty
                          ? const ColoredBox(
                              color: PColors.elevated,
                              child: Icon(
                                Icons.dashboard_outlined,
                                color: PColors.muted,
                              ),
                            )
                          : PinImage(pins.first.image),
                    ),
                  ),
                  title: Text(
                    board.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${board.pinIds.length} pin${board.secret ? ' · Rahasia' : ''}',
                    style: const TextStyle(color: PColors.muted, fontSize: 12),
                  ),
                  trailing: Icon(
                    saved
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: saved ? PColors.sage : PColors.muted,
                  ),
                  onTap: () => state.toggleBoardPin(board.id, pinId),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final id = await showBoardEditor(context);
                  if (id != null) state.toggleBoardPin(id, pinId);
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Buat board baru'),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Selesai'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
