import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/demo_data.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  final selected = <String>{'Interior', 'Travel', 'Kreatif'};
  bool busy = false;
  Future<void> finish() async {
    setState(() => busy = true);
    await AppScope.read(context).finishIntro(selected.toList());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ContentWidth(
        maxWidth: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: step == 0
                ? Column(
                    key: const ValueKey('welcome'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Brand(large: true),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height < 760
                            ? 245
                            : 330,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: const SizedBox.expand(
                                  child: PinImage(
                                    'assets/images/quiet_corner.jpg',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: const SizedBox.expand(
                                        child: PinImage(
                                          'assets/images/beach.jpg',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: const SizedBox.expand(
                                        child: PinImage(
                                          'assets/images/flowers.jpg',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      const SmallLabel('TEMUKAN VIBE-MU'),
                      const SizedBox(height: 14),
                      const Text(
                        'Ide kecil.\nKemungkinan besar.',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Jelajahi yang menginspirasimu. Simpan dalam board, lalu buat sesuatu yang terasa seperti dirimu.',
                        style: TextStyle(
                          color: PColors.muted,
                          fontSize: 14,
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => setState(() => step = 1),
                          label: const Text('Mulai temukan inspirasi'),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: busy ? null : finish,
                          child: const Text(
                            'Sudah punya akun? Masuk',
                            style: TextStyle(
                              color: PColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('interests'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => step = 0),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          const Text(
                            '01 / 01',
                            style: TextStyle(
                              color: PColors.muted,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Brand(),
                      const SizedBox(height: 36),
                      const Text(
                        'Apa yang membuatmu\npenasaran?',
                        style: TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pilih minatmu untuk menyusun inspirasi awal. Kamu bisa mengubahnya kapan saja.',
                        style: TextStyle(color: PColors.muted, height: 1.6),
                      ),
                      const SizedBox(height: 26),
                      Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: categories
                            .skip(1)
                            .map(
                              (category) => FilterChip(
                                label: Text(category),
                                selected: selected.contains(category),
                                selectedColor: PColors.sage.withValues(
                                  alpha: .2,
                                ),
                                checkmarkColor: PColors.sage,
                                padding: const EdgeInsets.all(12),
                                onSelected: (value) => setState(
                                  () => value
                                      ? selected.add(category)
                                      : selected.remove(category),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 36),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: const SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: PinImage('assets/images/workspace.jpg'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: selected.isEmpty || busy ? null : finish,
                          child: Text(
                            busy
                                ? 'Menyiapkan...'
                                : 'Lanjut dengan ${selected.length} minat',
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}
