import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'common.dart';

class BoardCard extends StatelessWidget {
  const BoardCard({super.key, required this.board});
  final Board board;
  @override
  Widget build(BuildContext context) {
    final pins = AppScope.of(context).pinsInBoard(board);
    Widget tile(int index) => index < pins.length
        ? PinImage(pins[index].image)
        : const ColoredBox(
            color: PColors.elevated,
            child: Center(
              child: Icon(Icons.add_rounded, color: PColors.border, size: 28),
            ),
          );
    return InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: () => Navigator.pushNamed(context, '/board', arguments: board.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1.35,
              child: Row(
                children: [
                  Expanded(flex: 3, child: SizedBox.expand(child: tile(0))),
                  const SizedBox(width: 3),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(child: SizedBox.expand(child: tile(1))),
                        const SizedBox(height: 3),
                        Expanded(child: SizedBox.expand(child: tile(2))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Text(
                  board.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
              if (board.secret)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: PColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${pins.length} pin${board.secret ? ' · Rahasia' : ''}',
            style: const TextStyle(color: PColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class BoardGrid extends StatelessWidget {
  const BoardGrid({super.key, required this.boards});
  final List<Board> boards;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final count = box.maxWidth < 650
          ? 2
          : box.maxWidth < 1050
          ? 3
          : 4;
      final width = (box.maxWidth - 14 * (count - 1)) / count;
      return Wrap(
        spacing: 14,
        runSpacing: 24,
        children: boards
            .map(
              (board) => SizedBox(
                width: width,
                child: BoardCard(board: board),
              ),
            )
            .toList(),
      );
    },
  );
}
