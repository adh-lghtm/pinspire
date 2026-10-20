import 'package:flutter/material.dart';

String compactNumber(int value) =>
    value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : '$value';
String initials(String name) => name.trim().isEmpty
    ? 'P'
    : name
          .trim()
          .split(RegExp(r'\s+'))
          .take(2)
          .map((e) => e[0].toUpperCase())
          .join();
String dateLabel(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return 'Baru saja';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inHours < 1) return '${diff.inMinutes} menit';
  if (diff.inDays < 1) return '${diff.inHours} jam';
  return '${date.day}/${date.month}/${date.year}';
}

String? requiredText(String? value, String label) =>
    value == null || value.trim().isEmpty ? '$label wajib diisi' : null;
String? validEmail(String? value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
    ? null
    : 'Masukkan alamat email yang valid';
String? validWebUrl(String? value, {bool optional = true}) {
  if ((value ?? '').trim().isEmpty) return optional ? null : 'URL wajib diisi';
  final uri = Uri.tryParse(value!.trim());
  return uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.contains('.')
      ? null
      : 'Gunakan URL http:// atau https:// yang valid';
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String action = 'Hapus',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

Route<T> pageRoute<T>(Widget page) =>
    MaterialPageRoute<T>(builder: (_) => page);
