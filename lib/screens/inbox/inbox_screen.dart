import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/demo_data.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  bool updates = false;
  void newChat() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mulai percakapan',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 15),
          ...demoCreators.map(
            (c) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(name: c.name, image: c.avatar, size: 42),
              title: Text(
                c.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: PColors.muted,
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/chat', arguments: c.id);
              },
            ),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final people = demoCreators
        .where((c) => state.messagesFor(c.id).isNotEmpty)
        .toList();
    return ContentWidth(
      maxWidth: 850,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              title: 'Ide lebih seru\nsaat dibicarakan.',
              eyebrow: 'RUANG OBROLAN',
              large: true,
              action: IconButton.outlined(
                tooltip: 'Percakapan baru',
                onPressed: newChat,
                icon: const Icon(Icons.edit_square, size: 20),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                FilterPill(
                  label: 'Pesan',
                  selected: !updates,
                  onTap: () => setState(() => updates = false),
                ),
                FilterPill(
                  label:
                      'Kabar${state.unreadCount > 0 ? ' (${state.unreadCount})' : ''}',
                  selected: updates,
                  onTap: () => setState(() => updates = true),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (updates)
              const NotificationList()
            else ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: PColors.lavender.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 20,
                      color: PColors.lavender,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ruang percakapan demo. Pesan tersimpan di perangkatmu dan tidak dikirim ke orang lain.',
                        style: TextStyle(
                          color: PColors.muted,
                          fontSize: 11,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (people.isEmpty)
                EmptyState(
                  title: 'Mulai dari sapaan kecil',
                  message:
                      'Pilih kreator contoh untuk mencoba alur percakapan.',
                  icon: Icons.chat_bubble_outline_rounded,
                  action: OutlinedButton(
                    onPressed: newChat,
                    child: const Text('Percakapan baru'),
                  ),
                ),
              ...people.map((c) {
                final messages = state.messagesFor(c.id);
                final last = messages.last;
                final unread = !state.readThreads.contains(c.id) && !last.mine;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: UserAvatar(
                      name: c.name,
                      image: c.avatar,
                      size: 53,
                      color: Color(c.color),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          dateLabel(last.createdAt),
                          style: const TextStyle(
                            color: PColors.muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        '${last.mine ? 'Kamu: ' : ''}${last.text}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: unread ? PColors.text : PColors.muted,
                        ),
                      ),
                    ),
                    trailing: unread
                        ? Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: PColors.coral,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () =>
                        Navigator.pushNamed(context, '/chat', arguments: c.id),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kabar untukmu')),
    body: const ContentWidth(
      maxWidth: 850,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: NotificationList(),
      ),
    ),
  );
}

class NotificationList extends StatelessWidget {
  const NotificationList({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.notificationsEnabled) {
      return const EmptyState(
        title: 'Kabar sedang dijeda',
        message: 'Aktifkan kembali notifikasi lokal melalui Pengaturan.',
        icon: Icons.notifications_off_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Kabar pilihan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            TextButton(
              onPressed: state.markAllRead,
              child: const Text(
                'Baca semua',
                style: TextStyle(fontSize: 10, color: PColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...state.notificationItems.map((n) {
          final unread = !state.readNotifications.contains(n['id']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: unread ? PColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                contentPadding: const EdgeInsets.all(14),
                leading: SizedBox(
                  width: 52,
                  height: 65,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: PinImage(n['image']!),
                  ),
                ),
                title: Text(
                  n['title']!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    n['body']!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: PColors.muted,
                      height: 1.6,
                    ),
                  ),
                ),
                trailing: unread
                    ? const Icon(Icons.circle, size: 6, color: PColors.coral)
                    : null,
                onTap: () {
                  state.markRead(n['id']!);
                  Navigator.pushNamed(context, '/pin', arguments: n['target']);
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        const Text(
          'Kabar contoh untuk menjelajahi koleksi. Tidak menggunakan push notification.',
          style: TextStyle(color: PColors.muted, fontSize: 10, height: 1.7),
        ),
      ],
    );
  }
}
