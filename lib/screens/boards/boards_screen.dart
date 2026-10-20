import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/board_card.dart';
import '../../widgets/board_sheets.dart';
import '../../widgets/common.dart';

class BoardsScreen extends StatefulWidget {
  const BoardsScreen({super.key});
  @override
  State<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {
  String query = '';
  bool alphabetical = false;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final boards = state.boards
        .where((b) => b.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (alphabetical) boards.sort((a, b) => a.title.compareTo(b.title));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua board'),
        actions: [
          IconButton(
            tooltip: 'Buat board',
            onPressed: () => showBoardEditor(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ContentWidth(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                title: 'Tempat ide-ide\nmenemukan rumah.',
                eyebrow: 'KOLEKSI MILIKMU',
                large: true,
              ),
              const SizedBox(height: 25),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari board milikmu',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    '${boards.length} board',
                    style: const TextStyle(color: PColors.muted, fontSize: 12),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => alphabetical = !alphabetical),
                    icon: const Icon(Icons.sort_rounded, size: 17),
                    label: Text(
                      alphabetical ? 'Nama A–Z' : 'Urutan dibuat',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (boards.isEmpty)
                EmptyState(
                  title: 'Satu tempat untuk ide baru',
                  message: 'Buat board pertamamu, lalu tambahkan pin yang kamu suka.',
                  icon: Icons.dashboard_outlined,
                  action: FilledButton(
                    onPressed: () => showBoardEditor(context),
                    child: const Text('Buat board'),
                  ),
                )
              else
                BoardGrid(boards: boards),
            ],
          ),
        ),
      ),
    );
  }
}
