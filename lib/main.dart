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
  String id; // Add an ID field for stable key generation
  
  Task({required this.title, this.isCompleted = false, String? id})
      : this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + '_' + (title.hashCode).toString();
  
  // Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'id': id, // Include ID in JSON serialization
    };
  }
  
  // Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'],
      id: json['id'], // Read ID from JSON
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
  
  // Task management state
  List<Task> _tasks = [];
  int? _hoveredIndex;
  int? _editingIndex;

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
    
    // Set up focus listener to handle task deletion when losing focus
    _taskFocusNode.addListener(() {
      if (!_taskFocusNode.hasFocus && _editingIndex != null) {
        if (_taskController.text.isEmpty) {
          // Delete task when focus is lost and the field is empty
          setState(() {
            if (_editingIndex! < _tasks.length) {
              _tasks.removeAt(_editingIndex!);
              _editingIndex = null;
              _saveTasks();
            }
          });
        }
      }
    });
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

  // Create a new empty task at the specified index and immediately edit it
  void _createNewTaskAt(int index) {
    // Save any current editing first
    if (_editingIndex != null) {
      _saveCurrentEditing();
    }
    
    setState(() {
      // Insert a new empty task at the specified index
      _tasks.insert(index, Task(title: ''));
      
      // Start editing the new task
      _editingIndex = index;
      _taskController.clear();
    });
    
    // Save tasks including the new empty one
    _saveTasks();
    
    // Ensure the text field is focused with visible cursor
    _focusTextField();
  }
  
  // Create a new task after the current task being edited
  void _createNewTaskAfter(int index) {
    // Make sure we have a valid index
    if (index < 0 || index >= _tasks.length) {
      return;
    }
    
    // First save any changes to the current task
    if (_editingIndex != null && _editingIndex! < _tasks.length) {
      final currentIndex = _editingIndex!;
      
      setState(() {
        // Update the current task with whatever content it has
        final Task updatedTask = Task(
          title: _taskController.text,
          isCompleted: _tasks[currentIndex].isCompleted,
          id: _tasks[currentIndex].id
        );
        
        // Replace the task at the index
        _tasks[currentIndex] = updatedTask;
      });
    }
    
    // Create a new task after the current one
    setState(() {
      // Insert a new empty task at the index after the current one
      _tasks.insert(index + 1, Task(title: ''));
      
      // Start editing the new task
      _editingIndex = index + 1;
      _taskController.clear();
    });
    
    // Save all tasks
    _saveTasks();
    
    // Ensure the text field is focused with visible cursor
    _focusTextField();
  }
  
  // Create a new task at the beginning of the list
  void _createFirstTask() {
    _createNewTaskAt(0);
  }

  // Save the task currently being edited
  void _saveCurrentEditing() {
    if (_editingIndex != null && _editingIndex! < _tasks.length) {
      final index = _editingIndex!;
      
      if (_taskController.text.isEmpty) {
        // Only remove the task if we're actually losing focus (not creating a new task)
        // We handle this by setting a flag or checking navigation direction
        setState(() {
          _tasks.removeAt(index);
          // Note: we don't clear _editingIndex here, as that will happen in the code
          // that called this method when moving to a different task
        });
      } else {
        setState(() {
          // Create a copy of the task with updated title but same ID and completion status
          final Task updatedTask = Task(
            title: _taskController.text,
            isCompleted: _tasks[index].isCompleted,
            id: _tasks[index].id
          );
          
          // Replace the task at the index
          _tasks[index] = updatedTask;
        });
      }
      
      // Save tasks
      _saveTasks();
    }
  }

  // Ensure text field gets focus with visible cursor
  void _focusTextField() {
    // First request focus
    _taskFocusNode.requestFocus();
    
    // Make sure the widget updates with the cursor visible immediately
    setState(() {});
    
    // Use a small delay to ensure the cursor is visible
    Future.delayed(Duration(milliseconds: 50), () {
      if (_taskFocusNode.hasFocus) {
        // Force cursor position
        _taskController.selection = TextSelection.fromPosition(
          TextPosition(offset: _taskController.text.length),
        );
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
    // Check index bounds
    if (index < 0 || index >= _tasks.length) {
      return;
    }
    
    // Save any current editing first
    if (_editingIndex != null) {
      _saveCurrentEditing();
    }
    
    setState(() {
      _editingIndex = index;
      _taskController.text = _tasks[index].title;
    });
    
    // Focus on the text field for editing with visible cursor
    _focusTextField();
  }

  // Toggle task completion
  void _toggleTask(int index) {
    // Check index bounds
    if (index < 0 || index >= _tasks.length) {
      return;
    }
    
    // Save any current editing first
    if (_editingIndex != null) {
      _saveCurrentEditing();
    }
    
    setState(() {
      // Update editing index if necessary
      if (_editingIndex == index) {
        _editingIndex = null;
        _taskController.clear();
      }
      
      // Create a copy of the task to prevent reference issues
      final Task taskToToggle = _tasks[index];
      final bool newCompletionState = !taskToToggle.isCompleted;
      
      // Create a new task with the same ID but toggled completion status
      final Task toggledTask = Task(
        title: taskToToggle.title,
        isCompleted: newCompletionState,
        id: taskToToggle.id // Keep the same ID
      );
      
      // Remove the original task
      _tasks.removeAt(index);
      
      // Insert the toggled task in the appropriate position
      if (newCompletionState) {
        // If now completed, add to the end
        _tasks.add(toggledTask);
      } else {
        // If now unchecked, find where to insert it among active tasks
        int firstCompletedIndex = _tasks.indexWhere((task) => task.isCompleted);
        if (firstCompletedIndex != -1) {
          _tasks.insert(firstCompletedIndex, toggledTask);
        } else {
          // No completed tasks, add to the end
          _tasks.add(toggledTask);
        }
      }
    });
    
    _saveTasks();
  }

  // Delete task
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
    
    // For macOS, we can get the screen size this way
    final screenWidth = WidgetsBinding.instance.window.physicalSize.width / devicePixelRatio;
    final screenHeight = WidgetsBinding.instance.window.physicalSize.height / devicePixelRatio;
    
    return Container(
      width: 350, // Fixed width of 350
      height: screenHeight, // Full screen height
      child: Material(
        type: MaterialType.transparency,
        child: Focus(
          autofocus: true,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              // Check for Command+N shortcut to create a new task at the top
              if (event.logicalKey == LogicalKeyboardKey.keyN && 
                  (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
                _createNewTaskAt(0);
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
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
                        textAlign: TextAlign.left,
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
                    
                    SizedBox(height: 15),
                    
                    // Todo List Section
                    Expanded(
                      child: _tasks.isEmpty
                          ? GestureDetector(
                              onTap: _createFirstTask,
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
                              itemCount: _tasks.length,
                              buildDefaultDragHandles: false,
                              proxyDecorator: (child, index, animation) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (BuildContext context, Widget? child) {
                                    final double animValue = Curves.easeInOut.transform(animation.value);
                                    final double elevation = lerpDouble(0, 6, animValue)!;
                                    return Material(
                                      elevation: elevation,
                                      color: Colors.white,
                                      shadowColor: Colors.black26,
                                      borderRadius: BorderRadius.circular(4),
                                      child: child,
                                    );
                                  },
                                  child: child,
                                );
                              },
                              onReorder: (int oldIndex, int newIndex) {
                                // First check the bounds
                                if (oldIndex < 0 || oldIndex >= _tasks.length || 
                                    newIndex < 0 || newIndex > _tasks.length) {
                                  return; // Prevent out-of-bounds operations
                                }
                                
                                // Create a local reference to avoid potential null issues
                                final Task? taskToMove = _tasks.length > oldIndex ? _tasks[oldIndex] : null;
                                if (taskToMove == null) {
                                  return; // Don't proceed if the task doesn't exist
                                }
                                
                                setState(() {
                                  // Save any current editing
                                  if (_editingIndex != null) {
                                    _saveCurrentEditing();
                                  }
                                
                                  // Handle index adjustment when moving an item down
                                  if (oldIndex < newIndex) {
                                    newIndex -= 1;
                                  }
                                  
                                  // Final bounds check after adjustment
                                  if (newIndex >= _tasks.length) {
                                    newIndex = _tasks.length - 1;
                                  }
                                  
                                  // Move the task safely
                                  _tasks.removeAt(oldIndex);
                                  _tasks.insert(newIndex, taskToMove);
                                  
                                  // Update editing index if necessary
                                  if (_editingIndex != null) {
                                    if (_editingIndex == oldIndex) {
                                      _editingIndex = newIndex;
                                    } else if (oldIndex < _editingIndex! && newIndex >= _editingIndex!) {
                                      _editingIndex = _editingIndex! - 1;
                                    } else if (oldIndex > _editingIndex! && newIndex <= _editingIndex!) {
                                      _editingIndex = _editingIndex! + 1;
                                    }
                                  }
                                });
                                
                                _saveTasks();
                              },
                              itemBuilder: (context, index) {
                                // Check if index is valid
                                if (index < 0 || index >= _tasks.length) {
                                  return SizedBox.shrink(key: Key('invalid_index_$index'));
                                }

                                // Check if task exists at this index
                                final Task? task = _tasks[index];
                                if (task == null) {
                                  return SizedBox.shrink(key: Key('null_task_$index'));
                                }
                                
                                // Editing existing task
                                if (_editingIndex == index) {
                                  return Padding(
                                    key: Key('editing_task_${task.id}'),
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Checkbox
                                        Material(
                                          type: MaterialType.transparency,
                                          child: Checkbox(
                                            value: task.isCompleted,
                                            onChanged: (value) => _toggleTask(index),
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
                                              hintText: 'Task name...',
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
                                              // Create a new task entry after the current one when Enter is pressed
                                              _createNewTaskAfter(index);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                // Regular task display
                                return Padding(
                                  key: Key('task_${task.id}'),
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: MouseRegion(
                                    onEnter: (_) => setState(() => _hoveredIndex = index),
                                    onExit: (_) => setState(() => _hoveredIndex = null),
                                    cursor: SystemMouseCursors.click,
                                    child: ReorderableDragStartListener(
                                      index: index,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () => _startEditingTask(index),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Checkbox
                                            GestureDetector(
                                              onTap: () => _toggleTask(index),
                                              child: Material(
                                                type: MaterialType.transparency,
                                                child: Checkbox(
                                                  value: task.isCompleted,
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
                                                task.title,
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  decoration: task.isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  decorationColor: Colors.black54,
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
          ),
        ),
      ),
    );
  }
}