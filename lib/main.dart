import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:ui';

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

class Task {
  String title;
  bool isCompleted;
  
  Task({required this.title, this.isCompleted = false});
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
  final TextEditingController _taskController = TextEditingController();
  
  // Sample tasks
  final List<Task> _tasks = [
    Task(title: 'Complete project proposal'),
    Task(title: 'Buy groceries', isCompleted: true),
    Task(title: 'Schedule dentist appointment'),
    Task(title: 'Call mom'),
  ];

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
    _taskController.dispose();
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
  
  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(Task(title: _taskController.text));
        _taskController.clear();
      });
    }
  }
  
  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }
  
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
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
      child: Material(
        type: MaterialType.transparency, // Use transparent material
        child: Scaffold(
          backgroundColor: Colors.transparent, // Transparent background
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Time display with frosted glass effect
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _dateTime,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 20.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 25),
                  
                  // Todo List Section
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Todo List Header
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Text(
                                  'Todo List',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              
                              // Add Task Input
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _taskController,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Add a new task',
                                          hintStyle: TextStyle(color: Colors.white70),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.white30),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.white30),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.white),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    IconButton(
                                      icon: Icon(Icons.add, color: Colors.white),
                                      onPressed: _addTask,
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 10),
                              
                              // Task List
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  itemCount: _tasks.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Dismissible(
                                        key: Key(_tasks[index].title),
                                        background: Container(
                                          color: Colors.red.withOpacity(0.5),
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.only(right: 20),
                                          child: Icon(Icons.delete, color: Colors.white),
                                        ),
                                        direction: DismissDirection.endToStart,
                                        onDismissed: (direction) {
                                          _deleteTask(index);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: ListTile(
                                            leading: Checkbox(
                                              value: _tasks[index].isCompleted,
                                              onChanged: (value) {
                                                _toggleTask(index);
                                              },
                                              checkColor: Colors.white,
                                              fillColor: MaterialStateProperty.resolveWith(
                                                (states) => Colors.deepPurple.shade300.withOpacity(0.7),
                                              ),
                                            ),
                                            title: Text(
                                              _tasks[index].title,
                                              style: TextStyle(
                                                color: Colors.white,
                                                decoration: _tasks[index].isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                decorationColor: Colors.white,
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(Icons.delete, color: Colors.white70),
                                              onPressed: () => _deleteTask(index),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
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
}