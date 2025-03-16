import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Nook'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _dateTime = '';
  Timer? _timer;
  static const platform = MethodChannel('com.example.nook/window');

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    // Update time every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final dayFormat = DateFormat('EEE'); // Day of week (Sun)
    final dateFormat = DateFormat('MMM d'); // Month and day (Mar 16)
    final timeFormat = DateFormat('h:mm a'); // Hour and minute (3:07 a.m.)
    
    setState(() {
      _dateTime = '${dayFormat.format(now)}\n${dateFormat.format(now)}  ${timeFormat.format(now)}';
    });
  }
  
  // Methods to control window visibility from Flutter if needed
  Future<void> hideWindow() async {
    try {
      await platform.invokeMethod('hideWindow');
    } on PlatformException catch (e) {
      print("Failed to hide window: ${e.message}");
    }
  }
  
  Future<void> showWindow() async {
    try {
      await platform.invokeMethod('showWindow');
    } on PlatformException catch (e) {
      print("Failed to show window: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the primary display size
    final flutterView = ui.PlatformDispatcher.instance.views.first;
    final devicePixelRatio = flutterView.devicePixelRatio;
    
    // This gets the window size, not the full screen
    final windowSize = flutterView.physicalSize;
    
    // For macOS, we can get the screen size this way
    final screenWidth = WidgetsBinding.instance.window.physicalSize.width / devicePixelRatio;
    final screenHeight = WidgetsBinding.instance.window.physicalSize.height / devicePixelRatio;
    
    return Container(
      width: 350, // Fixed width of 350
      height: screenHeight, // Full screen height
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.indigo.shade900,
                Colors.purple.shade800,
                Colors.deepPurple.shade600,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _dateTime,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}