import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(200, 170),
    center: true,
    title: "Custom Timer",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Custom Timer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TimerPage(),
    );
  }
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WindowListener {
  int _timeInSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isAlwaysOnTop = false;

  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _timeController.text = _formatTime(_timeInSeconds);
  }

  void _toggleAlwaysOnTop() async {
    _isAlwaysOnTop = !_isAlwaysOnTop;
    await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
    setState(() {});
  }

  Future<void> _restoreDefaultWindowSize() async {
    await windowManager.setSize(const Size(200, 170)); // Ukuran default
    await windowManager.setAlignment(Alignment.topRight); // Posisikan ke tengah
    await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
  }

  Future<void> _resizeAndCenterWindow() async {
    await windowManager.setSize(const Size(600, 400)); // Ukuran besar
    await windowManager.setAlignment(Alignment.center); // Posisikan ke tengah
    await windowManager.setAlwaysOnTop(!_isAlwaysOnTop);
  }

  void _startTimer() {
    if (_timeInSeconds > 0) {
      setState(() {
        _isRunning = true;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeInSeconds > 0) {
          setState(() {
            _timeInSeconds--;
            _timeController.text =
                _formatTime(_timeInSeconds); // Sinkronkan teks
          });
        } else {
          timer.cancel();
          setState(() {
            _isRunning = false;
          });
          _showTimerCompleteDialog();

          _resizeAndCenterWindow();
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timeInSeconds = 0;
      _timeController.text = _formatTime(_timeInSeconds); // Sinkronkan teks
      _isRunning = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  String _formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _showTimerCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Waktu Sudah Habis 🙏'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateTimeFromInput(String input) {
    final parts = input.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;

      setState(() {
        _timeInSeconds = (hours * 3600) + (minutes * 60) + seconds;
        _timeController.text = _formatTime(_timeInSeconds); // Sinkronkan teks
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Input field for time in HH:MM:SS format
              LayoutBuilder(builder: (context, constraints) {
                return TextField(
                  controller: _timeController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.2,
                    fontWeight: FontWeight.bold,
                    color: _timeInSeconds <= 10 ? Colors.red : Colors.grey[800],
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '00:00:00',
                    counterText: '',
                  ),
                  onSubmitted: _updateTimeFromInput,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9:]')), // Allow only numbers and ':'
                  ],
                );
              }),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play Button
                    ElevatedButton(
                      onPressed: _isRunning
                          ? null
                          : () {
                              _updateTimeFromInput(_timeController.text);
                              if (_timeInSeconds > 0) {
                                _startTimer();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(15),
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 24,
                      ),
                    ),
                    // Reset Button
                    ElevatedButton(
                      onPressed: _resetTimer,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(15),
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      child: const Icon(
                        Icons.refresh,
                        size: 24,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _restoreDefaultWindowSize,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(15),
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      child: const Icon(
                        Icons.settings_backup_restore,
                        size: 24,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _toggleAlwaysOnTop,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(15),
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      child: Icon(
                        _isAlwaysOnTop
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }
}
