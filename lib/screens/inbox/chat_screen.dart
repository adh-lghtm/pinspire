import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.creatorId});
  final String creatorId;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final message = TextEditingController();
  final scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppScope.read(context).markThreadRead(widget.creatorId);
        bottom();
      }
    });
  }

  @override
  void dispose() {
    message.dispose();
    scroll.dispose();
    super.dispose();
  }

  void bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });
  void send() {
    if (message.text.trim().isEmpty) return;
    AppScope.read(context).sendMessage(widget.creatorId, message.text);
    message.clear();
    bottom();
  }

  String time(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    return d == null
        ? ''
        : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final creator = state.creator(widget.creatorId);
    final messages = state.messagesFor(widget.creatorId);
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, '/creator', arguments: creator.id),
          child: Row(
            children: [
              UserAvatar(name: creator.name, image: creator.avatar, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Percakapan demo',
                      style: TextStyle(fontSize: 9, color: PColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: ContentWidth(
        maxWidth: 800,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 14),
              child: Text(
                'Pesan di ruang ini hanya disimpan secara lokal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: PColors.muted),
              ),
            ),
            Expanded(
              child: messages.isEmpty
                  ? const EmptyState(
                      title: 'Sapa dan mulai cerita',
                      message: 'Coba tuliskan pesan pertamamu.',
                      icon: Icons.chat_bubble_outline_rounded,
                    )
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[i];
                        return Align(
                          alignment: m.mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .74,
                            ),
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: m.mine
                                  ? PColors.coral.withValues(alpha: .16)
                                  : PColors.surface,
                              border: Border.all(
                                color: m.mine
                                    ? PColors.coral.withValues(alpha: .18)
                                    : PColors.border,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(m.mine ? 20 : 5),
                                bottomRight: Radius.circular(m.mine ? 5 : 20),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  m.text,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.7,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${time(m.createdAt)}${m.mine ? ' · Disimpan' : ''}',
                                  style: const TextStyle(
                                    color: PColors.muted,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: message,
                        maxLength: 1000,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Tulis sebuah pesan...',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IconButton.filled(
                        tooltip: 'Simpan pesan',
                        onPressed: send,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 21),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
