import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// Custom text selection controls with minimal visual feedback
class MinimalTextSelectionControls extends TextSelectionControls {
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight, [VoidCallback? onTap]) {
    return Container(width: 0, height: 0); // Invisible handle
  }

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return Container(); // Empty toolbar
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }

  @override
  Size getHandleSize(double textLineHeight) {
    return Size(0, 0); // Zero size handle
  }
}

void main() {
  // Set system UI overlay style to remove highlight effects
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  
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
        // Remove splash and highlight effects
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        // Set text selection theme
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionHandleColor: Colors.transparent,
        ),
        // Override all button styles to remove highlight effects
        buttonTheme: ButtonThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        // Override checkbox theme
        checkboxTheme: CheckboxThemeData(
          splashRadius: 0,
        ),
        // Override input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          fillColor: Colors.transparent,
        ),
        // Disable all material tap highlights
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      home: const MyHomePage(title: 'Nook'),
    );
  }
}

class Task {
  String title;
  bool isCompleted;
  
  Task({required this.title, this.isCompleted = false});
  
  // Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }
  
  // Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'],
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
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _taskFocusNode = FocusNode();
  final MinimalTextSelectionControls _textSelectionControls = MinimalTextSelectionControls();
  
  // Sample tasks
  List<Task> _tasks = [];
  int? _hoveredIndex;
  int? _editingIndex;
  bool _isAddingNewTask = false;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
    
    // Configure focus node to minimize highlight effect
    _taskFocusNode.addListener(() {
      if (_taskFocusNode.hasFocus) {
        // When focused, ensure minimal visual feedback
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ));
      }
    });
    
    // Load saved tasks
    _loadTasks();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskController.dispose();
    _taskFocusNode.dispose();
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

  // Save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert tasks to JSON
    final List<String> tasksJson = _tasks.map((task) => 
      jsonEncode(task.toJson())
    ).toList();
    
    // Save JSON string list to SharedPreferences
    await prefs.setStringList('tasks', tasksJson);
  }

  // Load tasks from SharedPreferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get JSON string list from SharedPreferences
    final List<String>? tasksJson = prefs.getStringList('tasks');
    
    if (tasksJson != null) {
      // Convert JSON to tasks
      setState(() {
        _tasks = tasksJson.map((taskJson) => 
          Task.fromJson(jsonDecode(taskJson))
        ).toList();
        
        // Sort tasks to ensure completed tasks are at the end
        _sortTasks();
      });
    }
  }
  
  // Sort tasks with completed tasks at the end
  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) {
        return 1; // a comes after b
      } else if (!a.isCompleted && b.isCompleted) {
        return -1; // a comes before b
      } else {
        return 0; // maintain relative order
      }
    });
  }

  // Calculate the percentage of completed tasks
  double _calculateCompletionPercentage() {
    if (_tasks.isEmpty) return 0.0;
    
    int completedTasks = _tasks.where((task) => task.isCompleted).length;
    return completedTasks / _tasks.length;
  }

  // Add a new task
  void _addTask(String title) {
    if (title.isNotEmpty) {
      setState(() {
        _tasks.insert(0, Task(title: title)); // Insert at the beginning instead of adding to the end
        _taskController.clear();
        _isAddingNewTask = true; // Keep in adding mode for next task
      });
      _saveTasks();
      
      // Ensure focus and cursor are visible for the next task
      // Use a short delay to allow the UI to update first
      Future.delayed(Duration(milliseconds: 10), () {
        _focusTextField();
        // Force cursor to be visible
        setState(() {});
      });
    }
  }

  // Ensure text field gets focus with visible cursor
  void _focusTextField() {
    // First request focus
    _taskFocusNode.requestFocus();
    
    // Make sure the widget updates with the cursor visible immediately
    setState(() {});
    
    // Then use a small delay to ensure the cursor is visible
    Future.delayed(Duration(milliseconds: 50), () {
      // Always ensure cursor is visible by setting selection
      if (_taskFocusNode.hasFocus) {
        _taskController.selection = TextSelection.fromPosition(
          TextPosition(offset: _taskController.text.length),
        );
        
        // Make sure the widget updates with the cursor visible
        setState(() {});
      } else {
        // If focus was lost somehow, try again
        _taskFocusNode.requestFocus();
        setState(() {});
      }
    });
  }

  // Start editing a task
  void _startEditingTask(int index) {
    setState(() {
      _editingIndex = index;
      _taskController.text = _tasks[index].title;
      _isAddingNewTask = false;
    });
    // Focus on the text field for editing with visible cursor
    _focusTextField();
  }

  // Save edited task
  void _saveEditedTask(int index, String newTitle) {
    if (newTitle.isNotEmpty) {
      setState(() {
        _tasks[index].title = newTitle;
        _editingIndex = null;
        _taskController.clear();
      });
      _saveTasks();
    }
  }

  // Toggle task completion
  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      
      // If task is completed, move it to the end of the list
      if (_tasks[index].isCompleted) {
        final Task completedTask = _tasks.removeAt(index);
        _tasks.add(completedTask);
      } else {
        // If a task is unchecked, move it to be with the active tasks
        // Find the position of the first completed task
        int firstCompletedIndex = _tasks.indexWhere((task) => task.isCompleted);
        
        // If there are completed tasks and this task is after the first completed task
        if (firstCompletedIndex != -1 && firstCompletedIndex < index) {
          final Task uncheckedTask = _tasks.removeAt(index);
          _tasks.insert(firstCompletedIndex, uncheckedTask);
        }
      }
    });
    _saveTasks();
  }

  // Delete task with keyboard shortcut
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = null;
        _taskController.clear();
      } else if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
    });
    _saveTasks();
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
              // Check for Command+N shortcut - now just focuses the new task field
              if (event.logicalKey == LogicalKeyboardKey.keyN && 
                  (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
                setState(() {
                  _editingIndex = null;
                  _isAddingNewTask = true;
                  _taskController.clear();
                });
                _taskFocusNode.requestFocus();
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
                        
                        // Progress bar showing task completion percentage
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Percentage text
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Progress",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    "${(_calculateCompletionPercentage() * 100).toInt()}%",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              // Progress bar
                              Container(
                                height: 4,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _calculateCompletionPercentage(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 15), // Reduced from 25 to 15
                        
                        // Todo List Section - White background with black text
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            child: Column(
                              children: [                              
                                // Task List
                                Expanded(
                                  child: _tasks.isEmpty && !_isAddingNewTask
                                      ? GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isAddingNewTask = true;
                                              _taskController.clear();
                                            });
                                            // Ensure focus and cursor are visible
                                            _focusTextField();
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Center(
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: Text(
                                                "create your first task",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : ReorderableListView.builder(
                                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                          itemCount: _tasks.length + (_isAddingNewTask ? 1 : 0) + (!_isAddingNewTask ? 1 : 0), // Add extra item for "Add new task" line
                                          buildDefaultDragHandles: false, // We'll use custom drag configuration
                                          proxyDecorator: (child, index, animation) {
                                            // Return the child with a subtle lift effect for dragging
                                            return Material(
                                              elevation: 2,
                                              color: Colors.white,
                                              shadowColor: Colors.black26,
                                              borderRadius: BorderRadius.circular(4),
                                              child: child,
                                            );
                                          },
                                          onReorder: (oldIndex, newIndex) {
                                            // Don't allow reordering the "Add new task" item or the input field
                                            if (oldIndex == _tasks.length || newIndex == _tasks.length) {
                                              return;
                                            }
                                            
                                            setState(() {
                                              if (oldIndex < newIndex) {
                                                newIndex -= 1;
                                              }
                                              final Task item = _tasks.removeAt(oldIndex);
                                              _tasks.insert(newIndex, item);
                                            });
                                            _saveTasks();
                                          },
                                          itemBuilder: (context, index) {
                                            // New task input field at the end
                                            if (_isAddingNewTask && index == _tasks.length) {
                                              return Padding(
                                                key: Key('new_task_input'),
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    // Checkbox
                                                    Material(
                                                      type: MaterialType.transparency,
                                                      child: Checkbox(
                                                        value: false,
                                                        onChanged: null,
                                                        activeColor: Colors.black,
                                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        visualDensity: VisualDensity.compact,
                                                        hoverColor: Colors.transparent,
                                                        focusColor: Colors.transparent,
                                                        splashRadius: 0,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    // Text field for new task
                                                    Expanded(
                                                      child: TextField(
                                                        controller: _taskController,
                                                        focusNode: _taskFocusNode,
                                                        selectionControls: _textSelectionControls,
                                                        decoration: InputDecoration(
                                                          border: InputBorder.none,
                                                          hintText: 'Add a new task...',
                                                          hintStyle: TextStyle(color: Colors.grey.shade400),
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.zero,
                                                          focusedBorder: InputBorder.none,
                                                          enabledBorder: InputBorder.none,
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 14,
                                                        ),
                                                        cursorColor: Colors.black,
                                                        cursorWidth: 1.5,
                                                        showCursor: true,
                                                        autofocus: true,
                                                        enableInteractiveSelection: true,
                                                        keyboardType: TextInputType.text,
                                                        textInputAction: TextInputAction.next,
                                                        onSubmitted: (value) {
                                                          if (value.isNotEmpty) {
                                                            _addTask(value);
                                                          }
                                                        },
                                                        onEditingComplete: () {
                                                          // Handle Return/Enter key press
                                                          if (_taskController.text.isNotEmpty) {
                                                            _addTask(_taskController.text);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                            
                                            // "Add new task" line at the bottom
                                            if (!_isAddingNewTask && index == _tasks.length) {
                                              return Padding(
                                                key: Key('add_new_task'),
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: MouseRegion(
                                                  cursor: SystemMouseCursors.click,
                                                  child: GestureDetector(
                                                    behavior: HitTestBehavior.opaque,
                                                    onTap: () {
                                                      setState(() {
                                                        _isAddingNewTask = true;
                                                        _editingIndex = null;
                                                        _taskController.clear();
                                                      });
                                                      // Ensure focus and cursor are visible
                                                      _focusTextField();
                                                    },
                                                    child: Row(
                                                      children: [
                                                        // Add some padding to align with other tasks
                                                        SizedBox(width: 32),
                                                        Text(
                                                          "+ Add new task",
                                                          style: TextStyle(
                                                            color: Colors.grey.shade600,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            
                                            // Editing existing task
                                            if (_editingIndex == index) {
                                              return Padding(
                                                key: Key('editing_task_${index}'),
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    // Checkbox
                                                    Material(
                                                      type: MaterialType.transparency,
                                                      child: Checkbox(
                                                        value: _tasks[index].isCompleted,
                                                        onChanged: (value) {
                                                          _toggleTask(index);
                                                        },
                                                        activeColor: Colors.black,
                                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        visualDensity: VisualDensity.compact,
                                                        hoverColor: Colors.transparent,
                                                        focusColor: Colors.transparent,
                                                        splashRadius: 0,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    // Text field for editing
                                                    Expanded(
                                                      child: TextField(
                                                        controller: _taskController,
                                                        focusNode: _taskFocusNode,
                                                        selectionControls: _textSelectionControls,
                                                        decoration: InputDecoration(
                                                          border: InputBorder.none,
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.zero,
                                                          focusedBorder: InputBorder.none,
                                                          enabledBorder: InputBorder.none,
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 14,
                                                          decoration: _tasks[index].isCompleted
                                                              ? TextDecoration.lineThrough
                                                              : null,
                                                          decorationColor: Colors.black54,
                                                        ),
                                                        cursorColor: Colors.black,
                                                        cursorWidth: 1.5,
                                                        showCursor: true,
                                                        autofocus: true,
                                                        enableInteractiveSelection: true,
                                                        keyboardType: TextInputType.text,
                                                        textInputAction: TextInputAction.next,
                                                        onSubmitted: (value) {
                                                          if (value.isNotEmpty) {
                                                            _saveEditedTask(index, value);
                                                            // After editing, move to adding a new task
                                                            setState(() {
                                                              _isAddingNewTask = true;
                                                              _taskController.clear();
                                                            });
                                                            // Focus the text field and make cursor visible
                                                            _focusTextField();
                                                          }
                                                        },
                                                        onEditingComplete: () {
                                                          // Also handle Return/Enter key press
                                                          if (_taskController.text.isNotEmpty) {
                                                            _saveEditedTask(index, _taskController.text);
                                                            // After editing, move to adding a new task
                                                            setState(() {
                                                              _isAddingNewTask = true;
                                                              _taskController.clear();
                                                            });
                                                            // Focus the text field and make cursor visible
                                                            _focusTextField();
                                                          } else if (_taskController.text.isEmpty) {
                                                            setState(() {
                                                              _editingIndex = null;
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                            
                                            // Regular task display
                                            return Padding(
                                              key: Key(_tasks[index].title + index.toString()),
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: MouseRegion(
                                                onEnter: (_) => setState(() => _hoveredIndex = index),
                                                onExit: (_) => setState(() => _hoveredIndex = null),
                                                cursor: SystemMouseCursors.grab,
                                                child: ReorderableDragStartListener(
                                                  index: index,
                                                  child: GestureDetector(
                                                    onTap: () => _startEditingTask(index),
                                                    behavior: HitTestBehavior.opaque,
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        // Checkbox
                                                        GestureDetector(
                                                          onTap: () => _toggleTask(index),
                                                          child: Material(
                                                            type: MaterialType.transparency,
                                                            child: Checkbox(
                                                              value: _tasks[index].isCompleted,
                                                              onChanged: null,
                                                              activeColor: Colors.black,
                                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              visualDensity: VisualDensity.compact,
                                                              hoverColor: Colors.transparent,
                                                              focusColor: Colors.transparent,
                                                              splashRadius: 0,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                        // Task text
                                                        Expanded(
                                                          child: Text(
                                                            _tasks[index].title,
                                                            style: TextStyle(
                                                              color: Colors.black87,
                                                              fontSize: 14,
                                                              decoration: _tasks[index].isCompleted
                                                                  ? TextDecoration.lineThrough
                                                                  : null,
                                                              decorationColor: Colors.black54,
                                                            ),
                                                          ),
                                                        ),
                                                        // Show delete icon on hover
                                                        if (_hoveredIndex == index)
                                                          MouseRegion(
                                                            cursor: SystemMouseCursors.click,
                                                            child: GestureDetector(
                                                              onTap: () => _deleteTask(index),
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 8.0),
                                                                child: Icon(
                                                                  Icons.close,
                                                                  size: 16,
                                                                  color: Colors.grey.shade400,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}