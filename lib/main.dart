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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          primary: Colors.black,
          secondary: Colors.grey.shade700,
        ),
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
  final List<Task> _tasks = [];
  int? _hoveredIndex;

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
      _dateTime = '${dayFormat.format(now)} ${dateFormat.format(now)}  ${timeFormat.format(now)}';
    });
  }
  
  void _showAddTaskDialog() {
    _taskController.clear(); // Clear any previous text
    
    // Show a dialog with just a text field
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0), // Reduce bottom padding
          content: TextField(
            controller: _taskController,
            autofocus: true, // Automatically focus and show keyboard
            decoration: InputDecoration(
              border: InputBorder.none, // Remove border
              hintText: 'Type your task...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
            ),
            style: TextStyle(color: Colors.black, fontSize: 16),
            // Add task when user presses Enter/Return key
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _tasks.add(Task(title: value));
                });
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add', style: TextStyle(color: Colors.black)),
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  setState(() {
                    _tasks.add(Task(title: _taskController.text));
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
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
  
  void _editTask(int index) {
    _taskController.text = _tasks[index].title;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: TextField(
            controller: _taskController,
            autofocus: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Edit task...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
            ),
            style: TextStyle(color: Colors.black, fontSize: 16),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _tasks[index].title = value;
                });
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save', style: TextStyle(color: Colors.black)),
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  setState(() {
                    _tasks[index].title = _taskController.text;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
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
        child: Focus(
          autofocus: true,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              // Check for Command+N shortcut
              if (event.logicalKey == LogicalKeyboardKey.keyN && 
                  (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
                _showAddTaskDialog();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // Main content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Time display - Left aligned with white background and black text
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                          child: Text(
                            _dateTime,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.left, // Left aligned text
                          ),
                        ),
                        
                        SizedBox(height: 25),
                        
                        // Todo List Section - White background with black text
                        Expanded(
                          child: Container(
                            width: double.infinity,
        child: Column(
                              children: [                              
                                // Task List
                                Expanded(
                                  child: _tasks.isEmpty 
                                      ? Center(
                                          child: Text(
                                            "No task yet",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          itemCount: _tasks.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 4.0),
                                              child: MouseRegion(
                                                onEnter: (_) => setState(() => _hoveredIndex = index),
                                                onExit: (_) => setState(() => _hoveredIndex = null),
                                                child: Dismissible(
                                                  key: Key(_tasks[index].title),
                                                  background: Container(
                                                    color: Colors.red.shade100,
                                                    alignment: Alignment.centerRight,
                                                    padding: EdgeInsets.only(right: 10),
                                                    child: Icon(Icons.delete, color: Colors.red),
                                                  ),
                                                  direction: DismissDirection.endToStart,
                                                  onDismissed: (direction) {
                                                    _deleteTask(index);
                                                  },
                                                  child: Container(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Padding(
                                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          child: Row(
                                                            children: [
                                                              Checkbox(
                                                                value: _tasks[index].isCompleted,
                                                                onChanged: (value) {
                                                                  _toggleTask(index);
                                                                },
                                                                activeColor: Colors.black,
                                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                visualDensity: VisualDensity.compact,
                                                              ),
                                                              SizedBox(width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  _tasks[index].title,
                                                                  style: TextStyle(
                                                                    color: Colors.black87,
                                                                    decoration: _tasks[index].isCompleted
                                                                        ? TextDecoration.lineThrough
                                                                        : null,
                                                                    decorationColor: Colors.black54,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (_hoveredIndex == index)
                                                          Padding(
                                                            padding: EdgeInsets.only(left: 40, bottom: 4),
                                                            child: Row(
                                                              children: [
                                                                TextButton.icon(
                                                                  icon: Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
                                                                  label: Text('Edit', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                                                  onPressed: () => _editTask(index),
                                                                  style: TextButton.styleFrom(
                                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                                    minimumSize: Size(0, 24),
                                                                  ),
                                                                ),
                                                                SizedBox(width: 8),
                                                                TextButton.icon(
                                                                  icon: Icon(Icons.delete, size: 16, color: Colors.grey.shade600),
                                                                  label: Text('Delete', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                                                  onPressed: () => _deleteTask(index),
                                                                  style: TextButton.styleFrom(
                                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                                    minimumSize: Size(0, 24),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
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
                      ],
                    ),
                  ),
                ),
                
                // Absolutely positioned "+" button at the bottom
                Positioned(
                  bottom: 20, // 20 pixels from bottom
                  left: 20, // Add left margin
                  right: 20, // Add right margin
                  child: Container(
                    height: 40, // Smaller height
                    padding: EdgeInsets.all(10), // 10 padding all around
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      // No shadow
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _showAddTaskDialog,
                        child: Center( // Center the content horizontally
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, // Center the row content
                            children: [
                              Text(
                                "+",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
            Text(
                                " add new task",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "⌘N",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}