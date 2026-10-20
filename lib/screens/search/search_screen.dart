import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/board_card.dart';
import '../../widgets/pin_grid.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery = '',
    this.standalone = false,
  });
  final String initialQuery;
  final bool standalone;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController query;
  String category = 'Semua', vibe = 'Semua', type = 'Pin', sort = 'Relevan';
  Timer? debounce;
  List<Pin> results = const [];
  List<Creator> people = const [];
  String lastQuery = '';
  bool searching = false;
  String? searchError;

  @override
  void initState() {
    super.initState();
    query = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) runSearch(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    query.dispose();
    super.dispose();
  }

  void onChanged(String value) {
    setState(() {});
    debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        results = const [];
        people = const [];
        lastQuery = '';
        searching = false;
        searchError = null;
      });
      return;
    }
    debounce = Timer(const Duration(milliseconds: 420), () {
      if (mounted) runSearch(value);
    });
  }

  Future<void> runSearch(String value) async {
    final term = value.trim();
    if (term.isEmpty) return;
    debounce?.cancel();
    final state = AppScope.read(context);
    setState(() {
      searching = true;
      searchError = null;
    });
    final found = await Future.wait<dynamic>([
      state.searchPins(term),
      state.searchUsers(term),
    ]);
    if (!mounted || query.text.trim() != term) return;
    setState(() {
      results = found[0] as List<Pin>;
      people = found[1] as List<Creator>;
      lastQuery = term;
      searching = false;
      searchError = state.error;
    });
  }

  void search(String value) {
    query.text = value;
    onChanged(value);
    AppScope.read(context).rememberSearch(value);
    runSearch(value);
    FocusScope.of(context).unfocus();
  }

  List<Pin> sortPins(List<Pin> input) {
    final pins = [...input];
    if (sort == 'Populer') {
      pins.sort((a, b) => b.likes.compareTo(a.likes));
    } else if (sort == 'Terbaru') {
      pins.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return pins;
  }

  void filters() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Persempit inspirasimu',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 25),
              const Text('Vibe', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                runSpacing: 10,
                children: vibes
                    .map(
                      (v) => FilterPill(
                        label: v,
                        selected: vibe == v,
                        color: PColors.lavender,
                        onTap: () {
                          setState(() => vibe = v);
                          update(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Urutan',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                runSpacing: 10,
                children: ['Relevan', 'Populer', 'Terbaru']
                    .map(
                      (v) => FilterPill(
                        label: v,
                        selected: sort == v,
                        onTap: () {
                          setState(() => sort = v);
                          update(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tampilkan hasil'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final q = query.text.trim();
    final active = q.isNotEmpty || category != 'Semua' || vibe != 'Semua';
    final basePins = q.isEmpty
        ? state.discover(query: '', category: category, vibe: vibe, sort: sort)
        : lastQuery == q
        ? results
              .where((pin) => category == 'Semua' || pin.category == category)
              .where((pin) => vibe == 'Semua' || pin.vibe == vibe)
              .toList()
        : <Pin>[];
    final pins = sortPins(basePins);
    final boards = state.boards
        .where(
          (b) => '${b.title} ${b.description}'.toLowerCase().contains(
            q.toLowerCase(),
          ),
        )
        .toList();
    final creators = q.isEmpty
        ? state.users
        : lastQuery == q
        ? people
        : <Creator>[];
    final waiting = q.isNotEmpty && (searching || lastQuery != q);
    final body = ContentWidth(
      child: SingleChildScrollView(
        key: const PageStorageKey('search-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(
              title: 'Ke mana rasa ingin\ntahumu hari ini?',
              eyebrow: 'JELAJAHI KEMUNGKINAN',
              large: true,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: query,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari ide, gaya, atau inspirasi',
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                      suffixIcon: q.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: () {
                                query.clear();
                                onChanged('');
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                    ),
                    onChanged: onChanged,
                    onSubmitted: search,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  height: 54,
                  child: IconButton.filledTonal(
                    tooltip: 'Filter pencarian',
                    onPressed: filters,
                    style: IconButton.styleFrom(
                      backgroundColor: vibe == 'Semua'
                          ? PColors.surface
                          : PColors.lavender.withValues(alpha: .25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 21),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (active) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Pin', 'Board', 'Kreator']
                      .map(
                        (v) => FilterPill(
                          label: v,
                          selected: type == v,
                          onTap: () => setState(() => type = v),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              if (type == 'Pin')
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories
                        .map(
                          (c) => FilterPill(
                            label: c,
                            selected: category == c,
                            color: PColors.sage,
                            onTap: () => setState(() => category = c),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (vibe != 'Semua' && type == 'Pin')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SmallLabel('Vibe: $vibe', color: PColors.lavender),
                ),
              const SizedBox(height: 22),
              Text(
                '${type == 'Pin'
                    ? pins.length
                    : type == 'Board'
                    ? boards.length
                    : creators.length} hasil${q.isNotEmpty ? ' untuk “$q”' : ''}',
                style: const TextStyle(color: PColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 45),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (q.isNotEmpty &&
                  searchError != null &&
                  pins.isEmpty &&
                  people.isEmpty)
                EmptyState(
                  title: 'Pencarian belum termuat',
                  message: searchError!,
                  icon: Icons.cloud_off_rounded,
                  action: FilledButton(
                    onPressed: () => runSearch(q),
                    child: const Text('Coba lagi'),
                  ),
                )
              else ...[
                if (type == 'Pin')
                  (pins.isEmpty
                      ? const EmptyState(
                          title: 'Belum menemukan yang pas',
                          message:
                              'Coba kata yang lebih singkat atau ubah filter.',
                          icon: Icons.search_off_rounded,
                        )
                      : PinGrid(pins: pins)),
                if (type == 'Board')
                  (boards.isEmpty
                      ? const EmptyState(
                          title: 'Belum ada board yang cocok',
                          message:
                              'Pencarian board menampilkan koleksi milikmu.',
                          icon: Icons.dashboard_outlined,
                        )
                      : BoardGrid(boards: boards)),
                if (type == 'Kreator')
                  (creators.isEmpty
                      ? const EmptyState(
                          title: 'Kreator belum ditemukan',
                          message: 'Coba kata kunci nama atau username lain.',
                          icon: Icons.person_search_outlined,
                        )
                      : Column(
                          children: creators
                              .map((c) => _creatorRow(c.id))
                              .toList(),
                        )),
              ],
            ] else ...[
              if (state.recentSearches.isNotEmpty) ...[
                Row(
                  children: [
                    const Text(
                      'Baru kamu cari',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: state.clearSearches,
                      child: const Text(
                        'Hapus',
                        style: TextStyle(fontSize: 11, color: PColors.muted),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.recentSearches
                      .map(
                        (value) => InputChip(
                          label: Text(
                            value,
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () => search(value),
                          onDeleted: () => state.removeSearch(value),
                          deleteIcon: const Icon(Icons.close_rounded, size: 13),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 26),
              ],
              const SectionHeading(
                title: 'Mulai dari sini',
                eyebrow: 'PILIH SEBUAH DUNIA',
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, box) {
                  final width = (box.maxWidth - 12) / 2;
                  const items = [
                    ('Interior', 'assets/images/interior.jpg'),
                    ('Travel', 'assets/images/beach.jpg'),
                    ('Fashion', 'assets/images/fashion.jpg'),
                    ('Kreatif', 'assets/images/ceramics.jpg'),
                  ];
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: items
                        .map(
                          (item) => SizedBox(
                            width: width,
                            height: 132,
                            child: GestureDetector(
                              onTap: () => setState(() => category = item.$1),
                              child: Semantics(
                                button: true,
                                label: 'Jelajahi ${item.$1}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(19),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      PinImage(item.$2),
                                      const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Color(0xB3000000),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 15,
                                        bottom: 14,
                                        child: Text(
                                          item.$1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const Positioned(
                                        right: 12,
                                        bottom: 16,
                                        child: Icon(
                                          Icons.arrow_outward_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 30),
              const SectionHeading(title: 'Sering jadi inspirasi'),
              const SizedBox(height: 15),
              Wrap(
                runSpacing: 10,
                children: ['minimalis', 'pantai', 'fotografi', 'kopi', 'hijau']
                    .map(
                      (value) => FilterPill(
                        label: value,
                        selected: false,
                        icon: Icons.north_east_rounded,
                        onTap: () => search(value),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 30),
              const SectionHeading(
                title: 'Temui para pengumpul ide',
                eyebrow: 'KREATOR PILIHAN',
              ),
              const SizedBox(height: 12),
              ...state.users.take(3).map((creator) => _creatorRow(creator.id)),
            ],
          ],
        ),
      ),
    );
    return widget.standalone
        ? Scaffold(
            appBar: AppBar(title: const Text('Jelajah')),
            body: body,
          )
        : body;
  }

  Widget _creatorRow(String id) {
    final state = AppScope.of(context);
    final c = state.creator(id);
    final followed = state.followedIds.contains(id);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: UserAvatar(
        name: c.name,
        image: c.avatar,
        size: 46,
        color: Color(c.color),
      ),
      title: Text(
        c.name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '@${c.username}',
        style: const TextStyle(color: PColors.muted, fontSize: 11),
      ),
      trailing: TextButton(
        onPressed: () => state.toggleFollow(id),
        child: Text(
          followed ? 'Mengikuti' : 'Ikuti',
          style: TextStyle(
            color: followed ? PColors.sage : PColors.coral,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      onTap: () => Navigator.pushNamed(context, '/creator', arguments: id),
    );
  }
}
