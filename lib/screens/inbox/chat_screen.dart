import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
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
  bool loading = true, sending = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final state = AppScope.read(context);
      await state.ensureConversation(widget.creatorId);
      await state.markThreadRead(widget.creatorId);
      if (!mounted) return;
      setState(() => loading = false);
      bottom();
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
  Future<void> send() async {
    if (message.text.trim().isEmpty || sending) return;
    setState(() => sending = true);
    final state = AppScope.read(context);
    final ok = await state.sendMessage(widget.creatorId, message.text);
    if (!mounted) return;
    setState(() => sending = false);
    if (!ok) {
      toast(context, state.error ?? 'Pesan belum dapat dikirim.');
      return;
    }
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
                    Text(
                      '@${creator.username}',
                      style: const TextStyle(fontSize: 9, color: PColors.muted),
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
                'Pesan tersimpan di server Pinspire.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: PColors.muted),
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
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
                                  time(m.createdAt),
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
                        tooltip: 'Kirim pesan',
                        onPressed: sending ? null : send,
                        icon: sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded, size: 21),
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
