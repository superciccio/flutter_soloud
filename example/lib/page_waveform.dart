import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_soloud_example/waveform/bars.dart';
import 'package:flutter_soloud_example/waveform/filter_fx.dart';
import 'package:flutter_soloud_example/waveform/keyboard_widget.dart';
import 'package:flutter_soloud_example/waveform/knobs_groups.dart';
import 'package:flutter_soloud_example/waveform/text_slider.dart';
import 'package:star_menu/star_menu.dart';

/// Example to demostrate how waveforms work with a keyboard
///
class PageWaveform extends StatefulWidget {
  const PageWaveform({super.key});

  @override
  State<PageWaveform> createState() => _PageWaveformState();
}

class _PageWaveformState extends State<PageWaveform> {
  ValueNotifier<double> scale = ValueNotifier(0.25);
  ValueNotifier<double> detune = ValueNotifier(1);
  ValueNotifier<WaveForm> waveForm = ValueNotifier(WaveForm.fSquare);
  bool superWave = false;
  int octave = 2;
  double echoDelay = 0.1;
  double echoDecay = 0.7;
  double echoFilter = 0;
  double fadeIn = 0.5;
  double fadeOut = 0.5;
  double fadeSpeedIn = 0;
  double fadeSpeedOut = 0;
  double oscillateVol = 0;
  double oscillatePan = 0;
  double oscillateSpeed = 0;
  List<SoundProps> notes = [];

  @override
  void initState() {
    super.initState();

    /// listen to player events
    SoLoud().audioEvent.stream.listen((event) async {
      if (event == AudioEvent.isolateStarted) {
        /// When it starts initialize notes
        SoLoud().setVisualizationEnabled(true);
        await setupNotes();
        SoLoud().setGlobalVolume(0.6);
      }
      if (mounted) setState(() {});
    });
    SoLoud().startIsolate();
  }

  @override
  void dispose() {
    SoLoud().stopIsolate();
    SoLoud().stopCapture();
    SoLoud().disposeAllSound();
    super.dispose();
  }

  Future<void> setupNotes() async {
    await SoLoud().disposeAllSound();
    notes = await SoloudTools.initSounds(
      octave: octave,
      superwave: superWave,
      waveForm: waveForm.value,
    );

    /// set all sounds to pause state
    for (final s in notes) {
      await SoLoud().play(s, paused: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SoLoud().isPlayerInited) return const SizedBox.shrink();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final ret = await SoloudTools.loadFromAssets(
                  'assets/audio/8_bit_mentality.mp3',
                );
                SoLoud().play(ret!);
              },
              child: Text('play'),
            ),

            /// Scale
            ValueListenableBuilder<double>(
              valueListenable: scale,
              builder: (_, newScale, __) {
                return TextSlider(
                  text: 'scale  ',
                  min: 0,
                  max: 2,
                  value: newScale,
                  enabled: superWave,
                  onChanged: (value) {
                    scale.value = value;
                    for (var i = 0; i < notes.length; i++) {
                      SoLoud().setWaveformScale(notes[i], value);
                    }
                  },
                );
              },
            ),

            /// Detune
            ValueListenableBuilder<double>(
              valueListenable: detune,
              builder: (_, newDetune, __) {
                return TextSlider(
                  text: 'detune',
                  min: 0,
                  max: 1,
                  value: newDetune,
                  enabled: superWave,
                  onChanged: (value) {
                    detune.value = value;
                    for (var i = 0; i < notes.length; i++) {
                      SoLoud().setWaveformDetune(notes[i], value);
                    }
                  },
                );
              },
            ),

            /// Octave
            TextSlider(
              text: 'octave',
              min: 0,
              max: 4,
              value: octave.toDouble(),
              enabled: true,
              isDivided: true,
              onChanged: (value) async {
                octave = value.toInt();
                await setupNotes();
                if (mounted) setState(() {});
              },
            ),

            /// SuperWave
            Row(
              children: [
                const Text('superWave '),
                Checkbox.adaptive(
                  value: superWave,
                  onChanged: (value) {
                    superWave = value!;
                    for (var i = 0; i < notes.length; i++) {
                      SoLoud().setWaveformSuperWave(notes[i], value);
                    }
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),

            DefaultTabController(
              length: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    isScrollable: true,
                    dividerColor: Colors.blue,
                    tabs: [
                      Tab(text: 'faders'),
                      Tab(text: 'oscillators'),
                      Tab(text: 'Biquad Filter'),
                      Tab(text: 'Eq'),
                      Tab(text: 'Echo'),
                      Tab(text: 'Lofi'),
                      Tab(text: 'Flanger'),
                      Tab(text: 'DC Removal'),
                      Tab(text: 'Bassboost'),
                      Tab(text: 'Wave shaper'),
                      Tab(text: 'Robotize'),
                      Tab(text: 'Freeverb'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        /// Faders
                        KnobsGroup(
                          texts: const ['in', 'out', 'speed in', 'speed out'],
                          values: [fadeIn, fadeOut, fadeSpeedIn, fadeSpeedOut],
                          mins: const [0, 0, 0, 0],
                          maxs: const [2, 2, 2, 2],
                          onChanges: [
                            (value) => setState(() => fadeIn = value),
                            (value) => setState(() => fadeOut = value),
                            (value) => setState(() => fadeSpeedIn = value),
                            (value) => setState(() => fadeSpeedOut = value),
                          ],
                        ),

                        /// Oscillators
                        KnobsGroup(
                          texts: const ['volume', 'pan', 'speed'],
                          values: [oscillateVol, oscillatePan, oscillateSpeed],
                          mins: const [0, 0, 0],
                          maxs: const [0.5, 0.5, 0.5],
                          onChanges: [
                            (value) => setState(() => oscillateVol = value),
                            (value) => setState(() => oscillatePan = value),
                            (value) => setState(() => oscillateSpeed = value),
                          ],
                        ),

                        /// Biquad Resonant
                        const FilterFx(filterType: FilterType.biquadResonantFilter),

                        /// Eq
                        const FilterFx(filterType: FilterType.eqFilter),

                        /// Echo
                        const FilterFx(filterType: FilterType.echoFilter),

                        /// Lofi
                        const FilterFx(filterType: FilterType.lofiFilter),

                        /// Flanger
                        const FilterFx(filterType: FilterType.flangerFilter),

                        /// DC Removal
                        const FilterFx(filterType: FilterType.dcRemovalFilter),

                        /// Bassboost
                        const FilterFx(filterType: FilterType.bassboostFilter),

                        /// Wave Shaper
                        const FilterFx(filterType: FilterType.waveShaperFilter),

                        /// Robotize
                        const FilterFx(filterType: FilterType.robotizeFilter),

                        /// Freeverb
                        const FilterFx(filterType: FilterType.freeverbFilter),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// Choose wave form
            StarMenu(
              params: StarMenuParameters(
                shape: MenuShape.linear,
                boundaryBackground: BoundaryBackground(
                  color: Colors.white.withOpacity(0.1),
                  blurSigmaX: 6,
                  blurSigmaY: 6,
                ),
                linearShapeParams: LinearShapeParams(
                  angle: -90,
                  space: Platform.isAndroid || Platform.isIOS ? -10 : 10,
                  alignment: LinearAlignment.left,
                ),
              ),
              onItemTapped: (index, controller) {
                controller.closeMenu!();
              },
              items: [
                for (int i = 0; i < WaveForm.values.length; i++)
                  ActionChip(
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      waveForm.value = WaveForm.values[i];
                      setupNotes();
                      if (mounted) setState(() {});
                    },
                    label: Text(WaveForm.values[i].name),
                  ),
              ],
              child: Chip(
                label: Text(WaveForm.values[waveForm.value.index].name),
                backgroundColor: Colors.blue,
                avatar: const Icon(Icons.arrow_drop_down),
              ),
            ),

            const SizedBox(height: 8),
            KeyboardWidget(
              notes: notes,
              fadeIn: fadeIn,
              fadeOut: fadeOut,
              fadeSpeedIn: fadeSpeedIn,
              fadeSpeedOut: fadeSpeedOut,
              oscillateVolume: oscillateVol,
              oscillatePan: oscillatePan,
              oscillateSpeed: oscillateSpeed,
            ),
            const SizedBox(height: 8),
            Bars(key: UniqueKey()),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
