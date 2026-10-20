import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: large ? 44 : 34,
        height: large ? 44 : 34,
        decoration: BoxDecoration(
          color: PColors.coral,
          borderRadius: BorderRadius.circular(large ? 15 : 12),
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: PColors.background,
          size: large ? 27 : 22,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'pinspire',
        style: TextStyle(
          fontSize: large ? 30 : 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.3,
        ),
      ),
      const SizedBox(width: 3),
      const Icon(Icons.auto_awesome_rounded, color: PColors.coral, size: 13),
    ],
  );
}

class PinImage extends StatefulWidget {
  const PinImage(
    this.source, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });
  final String source;
  final BoxFit fit;
  final Alignment alignment;
  @override
  State<PinImage> createState() => _PinImageState();
}

class _PinImageState extends State<PinImage> {
  Uint8List? bytes;
  @override
  void initState() {
    super.initState();
    decode();
  }

  @override
  void didUpdateWidget(PinImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) decode();
  }

  void decode() {
    bytes = null;
    if (widget.source.startsWith('data:image/')) {
      try {
        bytes = base64Decode(widget.source.split(',').last);
      } catch (_) {
        bytes = null;
      }
    }
  }

  Widget fallback() => Container(
    color: PColors.elevated,
    alignment: Alignment.center,
    child: const Icon(Icons.image_outlined, color: PColors.muted, size: 28),
  );
  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    if (source.isEmpty) return fallback();
    if (source.startsWith('data:')) {
      return bytes == null
          ? fallback()
          : Image.memory(
              bytes!,
              fit: widget.fit,
              alignment: widget.alignment,
              gaplessPlayback: true,
              errorBuilder: (_, error, stack) => fallback(),
            );
    }
    if (source.startsWith('https://') || source.startsWith('http://')) {
      return Image.network(
        source,
        fit: widget.fit,
        alignment: widget.alignment,
        errorBuilder: (_, error, stack) => fallback(),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                color: PColors.elevated,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
      );
    }
    return Image.asset(
      source,
      fit: widget.fit,
      alignment: widget.alignment,
      errorBuilder: (_, error, stack) => fallback(),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.image = '',
    this.size = 38,
    this.color = PColors.lavender,
  });
  final String name, image;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: ClipOval(
      child: image.isNotEmpty
          ? PinImage(image)
          : ColoredBox(
              color: color,
              child: Center(
                child: Text(
                  initials(name),
                  style: TextStyle(
                    color: PColors.background,
                    fontSize: size * .34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    ),
  );
}

class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 1240});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.eyebrow,
    this.action,
    this.large = false,
  });
  final String title;
  final String? eyebrow;
  final Widget? action;
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null) ...[
              Text(
                eyebrow!,
                style: const TextStyle(
                  color: PColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 7),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: large ? 29 : 21,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
          ],
        ),
      ),
      if (action != null) action!,
    ],
  );
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color = PColors.coral,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Material(
      color: selected ? color : PColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? color : PColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? PColors.background : PColors.muted,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? PColors.background : PColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.auto_awesome_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: PColors.surface,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(icon, color: PColors.coral, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PColors.muted,
              height: 1.6,
              fontSize: 13,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    ),
  );
}

class PaletteBar extends StatelessWidget {
  const PaletteBar(
    this.colors, {
    super.key,
    this.height = 8,
    this.showCodes = false,
  });
  final List<int> colors;
  final double height;
  final bool showCodes;
  @override
  Widget build(BuildContext context) => Row(
    children: colors
        .map(
          (color) => Expanded(
            child: GestureDetector(
              onTap: showCodes
                  ? () => toast(
                      context,
                      '#${color.toRadixString(16).substring(2).toUpperCase()}',
                    )
                  : null,
              child: Container(
                height: height,
                color: Color(color),
                alignment: Alignment.center,
                child: showCodes
                    ? Text(
                        '#${color.toRadixString(16).substring(2).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(color).computeLuminance() > .4
                              ? Colors.black87
                              : Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        )
        .toList(),
  );
}

class SmallLabel extends StatelessWidget {
  const SmallLabel(this.text, {super.key, this.color = PColors.sage});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: .3,
      ),
    ),
  );
}
