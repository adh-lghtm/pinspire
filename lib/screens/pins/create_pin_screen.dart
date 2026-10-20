import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/demo_data.dart';
import '../../services/media_service.dart';
import '../../state/app_state.dart';
import '../../widgets/board_sheets.dart';
import '../../widgets/common.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key, this.initialBoardId, this.editPinId});
  final String? initialBoardId, editPinId;
  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      description = TextEditingController(),
      source = TextEditingController(),
      tags = TextEditingController();
  String image = '', imageUrlValue = '';
  String category = 'Interior', vibe = 'Calm';
  String? boardId;
  Uint8List? imageBytes;
  String imageMime = 'image/jpeg', imageName = 'pin.jpg';
  bool imageChanged = false;
  double aspectRatio = .75;
  bool loading = false, dirty = false;
  int paletteIndex = 0;
  static const palettes = [
    [0xFFE2D3C0, 0xFFA88C70, 0xFF5D594C],
    [0xFFDCE3D0, 0xFF9AB08D, 0xFF476B57],
    [0xFFE6D6E8, 0xFFAC98C8, 0xFF5C507A],
    [0xFFFFCCB6, 0xFFDA7C65, 0xFF704B4B],
  ];
  List<int>? existingPalette;
  @override
  void initState() {
    super.initState();
    boardId = widget.initialBoardId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = AppScope.read(context);
      final pin = widget.editPinId == null
          ? null
          : state.pinById(widget.editPinId!);
      if (pin != null) {
        setState(() {
          title.text = pin.title;
          description.text = pin.description;
          source.text = pin.sourceUrl;
          tags.text = pin.tags.join(', ');
          image = pin.image;
          imageUrlValue = pin.image.startsWith('http') ? pin.image : '';
          category = pin.category;
          vibe = pin.vibe;
          aspectRatio = pin.aspectRatio;
          existingPalette = pin.palette;
        });
      } else if (MediaService.recoveredPhoto != null) {
        final p = MediaService.recoveredPhoto!;
        MediaService.recoveredPhoto = null;
        setState(() {
          image = p.dataUri;
          imageBytes = p.bytes;
          imageMime = p.mimeType;
          imageName = p.filename;
          imageChanged = true;
          aspectRatio = p.aspectRatio;
          dirty = true;
        });
        toast(context, 'Gambar yang dipilih sebelumnya berhasil dipulihkan.');
      }
    });
  }

  void usePhoto(SelectedPhoto photo) {
    setState(() {
      image = photo.dataUri;
      imageBytes = photo.bytes;
      imageMime = photo.mimeType;
      imageName = photo.filename;
      imageUrlValue = '';
      imageChanged = true;
      aspectRatio = photo.aspectRatio;
      dirty = true;
    });
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    source.dispose();
    tags.dispose();
    super.dispose();
  }

  Future<void> gallery() async {
    try {
      final photo = await MediaService.pickPhoto();
      if (photo != null && mounted) usePhoto(photo);
    } on FormatException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (_) {
      if (mounted) {
        toast(
          context,
          'Galeri belum dapat dibuka. Periksa izin foto atau pilih gambar contoh.',
        );
      }
    }
  }

  Future<void> imageUrl() async {
    final ctrl = TextEditingController(
      text: image.startsWith('http') ? image : '',
    );
    final key = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gunakan URL gambar'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://.../gambar.jpg',
            ),
            validator: (v) => validWebUrl(v, optional: false),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: const Text('Pakai URL'),
          ),
        ],
      ),
    );
    // Controller dialog dibuang setelah animasi rute selesai.
    Future<void>.delayed(const Duration(milliseconds: 350), ctrl.dispose);
    if (value != null && mounted) {
      setState(() {
        image = value;
        imageUrlValue = value;
        imageBytes = null;
        imageChanged = true;
        aspectRatio = .75;
        dirty = true;
      });
    }
  }

  void sample() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih gambar contoh',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gambar contoh akan diunggah sebagai bagian dari pin baru.',
              style: TextStyle(color: PColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: .8,
                ),
                itemCount: demoPins.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () async {
                    try {
                      final photo = await MediaService.fromAsset(
                        demoPins[i].image,
                      );
                      if (!mounted) return;
                      usePhoto(photo);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (_) {
                      if (ctx.mounted) {
                        toast(ctx, 'Gambar contoh belum dapat dimuat.');
                      }
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: PinImage(demoPins[i].image),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (image.trim().isEmpty) {
      toast(context, 'Pilih gambar terlebih dahulu');
      return;
    }
    final state = AppScope.read(context);
    setState(() => loading = true);
    final pinTags = tags.text
        .split(',')
        .map((t) => t.trim().replaceFirst('#', ''))
        .where((t) => t.isNotEmpty)
        .take(8)
        .toList();
    final palette = existingPalette ?? palettes[paletteIndex];
    if (widget.editPinId != null) {
      final ok = await state.updatePin(
        widget.editPinId!,
        title: title.text,
        description: description.text,
        category: category,
        vibe: vibe,
        tags: pinTags,
        palette: palette,
        sourceUrl: source.text,
        imageUrl: imageUrlValue,
        imageBytes: imageBytes,
        imageMime: imageMime,
        imageName: imageName,
        imageChanged: imageChanged,
        boardId: boardId,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => loading = false);
        toast(context, state.error ?? 'Pin belum dapat diperbarui.');
        return;
      }
      dirty = false;
      Navigator.pop(context);
      toast(context, 'Pin diperbarui');
      return;
    }

    final pin = await state.publishPin(
      title: title.text,
      description: description.text,
      category: category,
      vibe: vibe,
      palette: palette,
      aspectRatio: aspectRatio,
      sourceUrl: source.text,
      boardId: boardId,
      tags: pinTags,
      imageUrl: imageUrlValue,
      imageBytes: imageBytes,
      imageMime: imageMime,
      imageName: imageName,
    );
    if (!mounted) return;
    if (pin == null) {
      setState(() => loading = false);
      toast(context, state.error ?? 'Pin belum dapat diterbitkan.');
      return;
    }
    dirty = false;
    Navigator.pushReplacementNamed(context, '/pin', arguments: pin.id);
    toast(context, 'Pin baru berhasil dibuat');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final media = Column(
      children: [
        GestureDetector(
          onTap: image.isEmpty
              ? gallery
              : () => Navigator.pushNamed(context, '/image', arguments: image),
          child: Container(
            height: image.isEmpty ? 330 : null,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: PColors.surface,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: PColors.border),
            ),
            child: image.isEmpty
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 43,
                        color: PColors.coral,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Awali dengan sebuah gambar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ketuk untuk memilih dari galeri',
                        style: TextStyle(color: PColors.muted, fontSize: 11),
                      ),
                    ],
                  )
                : AspectRatio(
                    aspectRatio: aspectRatio.clamp(.65, 1.5),
                    child: PinImage(image),
                  ),
          ),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: gallery,
              icon: const Icon(Icons.photo_library_outlined, size: 15),
              label: const Text('Galeri', style: TextStyle(fontSize: 11)),
            ),
            OutlinedButton.icon(
              onPressed: sample,
              icon: const Icon(Icons.grid_view_rounded, size: 15),
              label: const Text('Contoh', style: TextStyle(fontSize: 11)),
            ),
            OutlinedButton.icon(
              onPressed: imageUrl,
              icon: const Icon(Icons.link_rounded, size: 15),
              label: const Text('URL', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ],
    );
    final fields = Form(
      key: form,
      onChanged: () {
        if (!dirty) setState(() => dirty = true);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SmallLabel('IDE MILIKMU'),
          const SizedBox(height: 16),
          TextFormField(
            controller: title,
            maxLength: 90,
            decoration: const InputDecoration(
              labelText: 'Judul pin',
              hintText: 'Beri nama untuk inspirasimu',
            ),
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => requiredText(v, 'Judul'),
          ),
          const SizedBox(height: 13),
          TextFormField(
            controller: description,
            maxLines: 4,
            maxLength: 800,
            decoration: const InputDecoration(
              labelText: 'Ceritakan idemu (opsional)',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  isExpanded: true,
                  items: categories
                      .skip(1)
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    category = v!;
                    dirty = true;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: vibe,
                  decoration: const InputDecoration(labelText: 'Vibe'),
                  items: vibes
                      .skip(1)
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    vibe = v!;
                    dirty = true;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          const Text(
            'Palet untuk pinmu',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Pilih kombinasi warna yang ingin kamu gunakan.',
            style: TextStyle(color: PColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              palettes.length,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == palettes.length - 1 ? 0 : 9,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      paletteIndex = i;
                      existingPalette = null;
                      dirty = true;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: existingPalette == null && paletteIndex == i
                              ? PColors.coral
                              : PColors.border,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: PaletteBar(palettes[i], height: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: source,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Tautan sumber (opsional)',
              prefixIcon: Icon(Icons.link_rounded, size: 19),
            ),
            validator: validWebUrl,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: tags,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Tag (pisahkan dengan koma)',
              hintText: 'minimalis, rumah, inspirasi',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey('board-$boardId-${state.boards.length}'),
            initialValue: boardId ?? '',
            decoration: const InputDecoration(labelText: 'Tambahkan ke board'),
            isExpanded: true,
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Tanpa board', style: TextStyle(fontSize: 12)),
              ),
              ...state.boards.map(
                (b) => DropdownMenuItem(
                  value: b.id,
                  child: Text(
                    b.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() {
              boardId = v == '' ? null : v;
              dirty = true;
            }),
          ),
          TextButton.icon(
            onPressed: () async {
              final id = await showBoardEditor(context);
              if (id != null && mounted) setState(() => boardId = id);
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Buat board baru',
              style: TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : save,
              icon: Icon(
                widget.editPinId == null
                    ? Icons.auto_awesome_rounded
                    : Icons.check_rounded,
                size: 18,
              ),
              label: Text(
                loading
                    ? 'Menyimpan...'
                    : widget.editPinId == null
                    ? 'Terbitkan pin'
                    : 'Simpan perubahan',
              ),
            ),
          ),
        ],
      ),
    );
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final yes = await confirmAction(
          context,
          title: 'Tinggalkan perubahan?',
          message: 'Perubahan yang belum disimpan akan hilang.',
          action: 'Tinggalkan',
        );
        if (yes && context.mounted) {
          setState(() => dirty = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context);
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.editPinId == null
                ? 'Buat sesuatu yang menginspirasi'
                : 'Edit pin',
          ),
        ),
        body: ContentWidth(
          maxWidth: 980,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 35),
            child: LayoutBuilder(
              builder: (context, box) => box.maxWidth > 720
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: media),
                        const SizedBox(width: 32),
                        Expanded(child: fields),
                      ],
                    )
                  : Column(
                      children: [media, const SizedBox(height: 30), fields],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
