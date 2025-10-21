import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const JAverageTimerApp());

class JAverageTimerApp extends StatelessWidget {
  const JAverageTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JAverage Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E2A78)),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 64, fontWeight: FontWeight.w800),
        ),
      ),
      home: const TimerPage(),
    );
  }
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const _tick = Duration(seconds: 1);

  Duration _initial = const Duration(minutes: 1);
  Duration _remaining = const Duration(minutes: 1);

  Timer? _timer;
  bool get _isRunning => _timer?.isActive == true;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --------- LÓGICA ---------
  void _start() {
    if (_isRunning || _remaining.inSeconds <= 0) return;
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      setState(() {
        final next = _remaining - _tick;
        if (next.inSeconds <= 0) {
          _remaining = Duration.zero;
          _timer?.cancel();
        } else {
          _remaining = next;
        }
      });
    });
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    setState(() => _remaining = _initial);
  }

  void _addSeconds(int seconds) {
    if (seconds <= 0) return;
    setState(() => _remaining += Duration(seconds: seconds));
  }

  bool get _resetDisabled {
    // Deshabilitado sólo si está “parado” sin cambios:
    // no corriendo y el restante es exactamente el inicial.
    return !_isRunning && _remaining == _initial;
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$m:$s';
    return '$m:$s';
  }

  Duration? _parse(String text) {
    // Acepta "MM:SS" o "M:SS"
    final rx = RegExp(r'^\s*(\d{1,2}):([0-5]\d)\s*$');
    final m = rx.firstMatch(text);
    if (m == null) return null;
    final minutes = int.parse(m.group(1)!);
    final seconds = int.parse(m.group(2)!);
    return Duration(minutes: minutes, seconds: seconds);
  }

  Future<void> _editTimeDialog() async {
    final controller = TextEditingController(text: _fmt(_remaining));
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar tiempo (MM:SS)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                ],
                decoration: InputDecoration(
                  hintText: 'MM:SS',
                  errorText: error,
                ),
                onChanged: (_) {
                  // Revalida en caliente
                  error = null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = _parse(controller.text);
                if (parsed == null || parsed.inSeconds == 0) {
                  // muestra error local
                  error = 'Formato inválido. Ejemplo: 05:30';
                  (ctx as Element).markNeedsBuild();
                  return;
                }
                setState(() {
                  _remaining = parsed;
                  _initial = parsed;
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAddPicker() async {
    final options = List<int>.generate(12, (i) => (i + 1) * 5); // 5..60
    int index = 5; // por defecto 30s
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Agregar segundos',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(
                  height: 160,
                  child: CupertinoPicker(
                    itemExtent: 36,
                    scrollController:
                        FixedExtentScrollController(initialItem: index),
                    onSelectedItemChanged: (i) => index = i,
                    children: options
                        .map((v) => Center(
                              child: Text('$v s',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _addSeconds(options[index]);
                  },
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------- UI ---------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.surface, cs.surfaceTint.withOpacity(.04)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ===== TIEMPO CENTRADO (editable con tap) =====
            Expanded(
              child: Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _editTimeDialog,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _fmt(_remaining),
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(color: cs.onSurface),
                    ),
                  ),
                ),
              ),
            ),

            // ===== CONTROLES ABAJO =====
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // +30s (tap) / picker (long press)
                  GestureDetector(
                    onLongPress: _openAddPicker,
                    child: ElevatedButton.icon(
                      onPressed: () => _addSeconds(30),
                      icon: const Icon(Icons.add),
                      label: const Text('+30 s'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Iniciar / Pausar (centro)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FilledButton.icon(
                        onPressed: _isRunning ? _pause : _start,
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                        label:
                            Text(_isRunning ? 'Pausar' : 'Iniciar'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Reiniciar (derecha)
                  ElevatedButton(
                    onPressed: _resetDisabled ? null : _reset,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Icon(Icons.restart_alt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
