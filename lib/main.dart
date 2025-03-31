import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// Updated MinimalTextSelectionControls class with correct method signatures
class MinimalTextSelectionControls extends MaterialTextSelectionControls {
  @override
  bool canCut(TextSelectionDelegate delegate) => false;
  
  @override
  bool canCopy(TextSelectionDelegate delegate) => false;
  
  @override
  bool canSelectAll(TextSelectionDelegate delegate) => false;
  
  @override
  bool canPaste(TextSelectionDelegate delegate) => false;
  
  @override
  void handleCut(TextSelectionDelegate delegate) {}
  
  @override
  void handleCopy(TextSelectionDelegate delegate) {}
  
  @override
  Future<void> handlePaste(TextSelectionDelegate delegate) async {}
  
  @override
  void handleSelectAll(TextSelectionDelegate delegate) {}
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
  bool isCollapsed;
  String id;
  List<Task> subtasks;
  
  Task({
    required this.title, 
    this.isCompleted = false, 
    this.isCollapsed = false,
    String? id,
    List<Task>? subtasks
  }) : 
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + '_' + (title.hashCode).toString(),
    this.subtasks = subtasks ?? [];
  
  // Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'isCollapsed': isCollapsed,
      'id': id,
      'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
    };
  }
  
  // Create Task from JSON
  static Task fromJson(Map<String, dynamic> json) {
    // Ensure we handle null subtasks properly
    List<dynamic>? subtasksJson = json['subtasks'] as List<dynamic>?;
    List<Task> parsedSubtasks = [];
    
    if (subtasksJson != null) {
      parsedSubtasks = subtasksJson
          .map((subtaskJson) => Task.fromJson(subtaskJson as Map<String, dynamic>))
          .toList();
    }
    
    return Task(
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      isCollapsed: json['isCollapsed'] as bool? ?? false,
      id: json['id'] as String,
      subtasks: parsedSubtasks,
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
  
  // Task management state
  List<Task> _tasks = [];
  int? _hoveredIndex;
  int? _editingIndex;
  List<List<Task>> _undoStack = [];
  List<List<Task>> _redoStack = [];

  // Add these state variables to track indentation
  Map<String, int> _taskIndentLevels = {}; // Maps task ID to indent level

  // Add this state variable to track whether completed tasks are shown
  bool _showCompletedTasks = true;

  bool _isTitleTask(Task task) {
    final index = _tasks.indexOf(task);
    return _hasIndentedChild(index);
  }

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
    _loadTaskIndentation(); // Load task indentation levels
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
      });
    }
  }
  
  // Calculate the percentage of completed tasks
  double _calculateCompletionPercentage() {
    final realTasks = _tasks.where((task) {
    return !_isTitleTask(task) &&
           task.title.trim() != '' &&
           task.title.trim() != '---';
    }).toList();

    if (realTasks.isEmpty) return 0.0;

    int completedTasks = realTasks.where((task) => task.isCompleted).length;
    return completedTasks / realTasks.length;
  }

  // Create a new empty task at the specified index and immediately edit it
  void _createNewTaskAt(int index) {
    _snapshotTasks();
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
    _snapshotTasks();
    // First save the current task content
    if (_editingIndex != null && _editingIndex! < _tasks.length) {
      final currentIndex = _editingIndex!;
      
      // Save the current task's content
      setState(() {
        // Update the current task with whatever content it has
        final Task updatedTask = Task(
          title: _taskController.text,
          isCompleted: _tasks[currentIndex].isCompleted,
          isCollapsed: _tasks[currentIndex].isCollapsed,
          id: _tasks[currentIndex].id
        );
        
        // Replace the task at the index
        _tasks[currentIndex] = updatedTask;
      });
      
      // Save changes
      _saveTasks();
    }
    
    // Then create a new empty task after it
    setState(() {
      // Insert a new empty task at the index after the current one
      final Task newTask = Task(title: '');
      _tasks.insert(index + 1, newTask);
      
      // Get the indentation level of the current task
      final int currentTaskIndent = _taskIndentLevels[_tasks[index].id] ?? 0;
      
      // Set the new task's indentation to match the current task's indentation
      _taskIndentLevels[newTask.id] = currentTaskIndent;
      
      // Set editing to the new task
      _editingIndex = index + 1;
      _taskController.clear();
    });
    
    // Save tasks with the new empty one included
    _saveTasks();
    _saveTaskIndentation();
    
    // Ensure the text field is focused with visible cursor
    _focusTextField();
  }
  
  // Create a new task at the beginning of the list
  void _createFirstTask() {
    _createNewTaskAt(0);
  }

  // Save the task currently being edited
  void _saveCurrentEditing() {
    _snapshotTasks();
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
            isCollapsed: _tasks[index].isCollapsed,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskFocusNode.requestFocus();
      
      // Ensure cursor is positioned at the end of the text
      if (_taskController.text.isNotEmpty) {
        _taskController.selection = TextSelection.collapsed(offset: _taskController.text.length);
      }
      
      // Force additional refresh to ensure cursor visibility
      setState(() {});
    });
  }

  // Start editing a task
  void _startEditingTask(int index, {bool shouldUnfocus = true}) {
    // Add bounds check to prevent range error
    if (index < 0 || index >= _tasks.length) return;

    if (_editingIndex != null) {
      _saveCurrentEditing();
    }

    setState(() {
      _editingIndex = index;
      _taskController.text = _tasks[index].title;
    });

    if (shouldUnfocus) {
      _taskFocusNode.unfocus(); 
    }

    // Ensure proper focus and cursor positioning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskFocusNode.requestFocus();
      if (_taskController.text.isNotEmpty) {
        _taskController.selection = TextSelection.collapsed(offset: _taskController.text.length);
      }
      // Force a UI refresh to ensure cursor visibility
      setState(() {});
    });
  }

  // Toggle task completion
  void _toggleTask(int index) {
    if (_isTitleTask(_tasks[index])) return;
    // Check index bounds
    if (index < 0 || index >= _tasks.length) {
      return;
    }
    
    _snapshotTasks();
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
      
      // Simply toggle the completion status without moving the task
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
    
    _saveTasks();
  }

  // Delete task
  void _deleteTask(int index) {
    _snapshotTasks();
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

  // Simplified nesting function to get core functionality working
  void _nestTaskUnderParent(int index) {
    // Check if this task can be nested (not the first task)
    if (index <= 0 || index >= _tasks.length) {
      return; // Can't nest the first task or invalid indices
    }
    
    // Save the current task content
    String taskContent = _taskController.text;
    
    setState(() {
      // Create an indentation marker to simulate nesting
      _taskController.text = "    " + taskContent; // Add 4 spaces to indent
    });
    
    // For now, this is a visual indication of nesting
    // In a future update, we can implement actual task hierarchy
    
    _focusTextField(); // Keep focus on the text field
  }

  // Add this to your state class
  List<MapEntry<Task, int>> _getFlattenedTasks() {
    List<MapEntry<Task, int>> flattenedTasks = [];
    
    void _flattenTaskList(List<Task> tasks, int level) {
      for (var task in tasks) {
        flattenedTasks.add(MapEntry(task, level));
        if (task.subtasks.isNotEmpty) {
          _flattenTaskList(task.subtasks, level + 1);
        }
      }
    }
    
    _flattenTaskList(_tasks, 0);
    return flattenedTasks;
  }

  // Method to indent a task and all its children by one level, with constraints
  void _indentTask(int index) {
    _snapshotTasks();
    // Check if this task can be indented (not the first task)
    if (index <= 0 || index >= _tasks.length) {
      return; // Can't indent the first task or invalid indices
    }
    
    // Get the current task ID and the task above it
    final String taskId = _tasks[index].id;
    final String previousTaskId = _tasks[index - 1].id;
    
    // Get current indent levels
    final int currentIndent = _taskIndentLevels[taskId] ?? 0;
    final int previousTaskIndent = _taskIndentLevels[previousTaskId] ?? 0;
    
    // CONSTRAINT: Only allow indent if current indent is not already deeper than previous task
    // A task can only be indented one level deeper than the task above it
    if (currentIndent <= previousTaskIndent) {
      setState(() {
        // Increase indent by 1, but never more than one level deeper than previous task
        _taskIndentLevels[taskId] = currentIndent + 1;
        
        // Calculate the indent change
        final int indentChange = (previousTaskIndent + 1) - currentIndent;
        
        // Find all child tasks (tasks that are currently indented more than this task)
        final List<int> childIndices = [];
        final List<int> childCurrentIndents = [];
        
        // Store the parent's new indent level
        final int newParentIndent = previousTaskIndent + 1;
        
        // Start checking from the task after the parent
        for (int i = index + 1; i < _tasks.length; i++) {
          final String childTaskId = _tasks[i].id;
          final int childIndent = _taskIndentLevels[childTaskId] ?? 0;
          
          // A child task has a greater indent level than the parent's original level
          if (childIndent <= currentIndent) {
            // We've found a task that's not a child of this task
            break;
          }
          
          // Store the child index and its current indent level
          childIndices.add(i);
          childCurrentIndents.add(childIndent);
        }
        
        // Now update all child tasks with the same indent change
        for (int i = 0; i < childIndices.length; i++) {
          final int childIndex = childIndices[i];
          final int childCurrentIndent = childCurrentIndents[i];
          final String childTaskId = _tasks[childIndex].id;
          
          // Apply the same indent change to the child
          _taskIndentLevels[childTaskId] = childCurrentIndent + indentChange;
        }
      });
      
      // Save the indentation state
      _saveTaskIndentation();
    }
  }

  // Method to outdent a task and all its children
  void _outdentTask(int index) {
    _snapshotTasks();
    if (index < 0 || index >= _tasks.length) {
      return; // Invalid index
    }
    
    final String taskId = _tasks[index].id;
    final int currentIndent = _taskIndentLevels[taskId] ?? 0;
    
    if (currentIndent > 0) {
      setState(() {
        // Calculate the indent change (how much we're decreasing indent by)
        final int indentChange = -1; // Always reduce by 1 level
        
        // Reduce indent level by 1
        _taskIndentLevels[taskId] = currentIndent - 1;
        
        // Find and outdent all child tasks
        _indentChildTasks(index, indentChange);
      });
      
      // Save the indentation state
      _saveTaskIndentation();
    }
  }

  // Helper method to identify and update indent levels of child tasks
  void _indentChildTasks(int parentIndex, int indentChange) {
    if (parentIndex >= _tasks.length - 1) {
      return; // No tasks after this one
    }
    
    final int parentIndent = _taskIndentLevels[_tasks[parentIndex].id] ?? 0;
    
    // Start checking from the task after the parent
    for (int i = parentIndex + 1; i < _tasks.length; i++) {
      final String childTaskId = _tasks[i].id;
      final int childIndent = _taskIndentLevels[childTaskId] ?? 0;
      
      // A child task has a greater indent level than the parent
      // Once we find a task with indent level <= parent's, we're out of the parent's children
      if (childIndent <= parentIndent) {
        break;
      }
      
      // Update the child's indent level
      _taskIndentLevels[childTaskId] = childIndent + indentChange;
    }
  }

  // Save task indentation levels
  Future<void> _saveTaskIndentation() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert indent levels to a format that can be stored
    final Map<String, dynamic> indentData = {};
    _taskIndentLevels.forEach((taskId, level) {
      indentData[taskId] = level;
    });
    
    await prefs.setString('task_indentation', json.encode(indentData));
  }

  // Load task indentation levels
  Future<void> _loadTaskIndentation() async {
    final prefs = await SharedPreferences.getInstance();
    final String? indentData = prefs.getString('task_indentation');
    
    if (indentData != null) {
      final Map<String, dynamic> decodedData = json.decode(indentData);
      
      setState(() {
        _taskIndentLevels = Map<String, int>.from(
          decodedData.map((key, value) => MapEntry(key, value as int))
        );
      });
    }
  }

  // Add a task-specific event handler for the Enter key
  bool _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter || 
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (_editingIndex != null) {
          _createNewTaskAfter(_editingIndex!);
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Create a filtered task list based on the toggle state
    final List<Task> displayedTasks = _showCompletedTasks 
        ? _tasks 
        : _tasks.where((task) => !task.isCompleted).toList();
    
    return Container(
      width: 350,
      height: WidgetsBinding.instance.window.physicalSize.height / WidgetsBinding.instance.window.devicePixelRatio,
      child: Material(
        type: MaterialType.transparency,
        child: Focus(
          autofocus: true,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.keyZ &&
                  HardwareKeyboard.instance.isMetaPressed) {
                if (HardwareKeyboard.instance.isShiftPressed) {
                  _redo();
                } else {
                  _undo();
                }
                return KeyEventResult.handled;
              }
              // Handle Command+N shortcut to create a new task at the top
              if (event.logicalKey == LogicalKeyboardKey.keyN &&
                  (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
                _createNewTaskAt(0);
                return KeyEventResult.handled;
              }
              
              // Only handle Tab and Shift+Tab here
              if (_editingIndex != null && 
                  event.logicalKey == LogicalKeyboardKey.tab) {
                
                // Check if shift is pressed
                if (HardwareKeyboard.instance.isShiftPressed) {
                  // Shift+Tab - outdent the task
                  _outdentTask(_editingIndex!);
                } else {
                  // Tab - indent the task
                  _indentTask(_editingIndex!);
                }
                return KeyEventResult.handled;
              }
              
              // Remove the Enter key handling from here since we're handling it in the TextField

              // Check for Delete key to delete current task
              if (_editingIndex != null && 
                  (event.logicalKey == LogicalKeyboardKey.delete || 
                  event.logicalKey == LogicalKeyboardKey.backspace) && 
                  _taskController.text.isEmpty) {
                _deleteTask(_editingIndex!);
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
                    
                    // Progress bar and percentage
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
                          
                          // Increased spacing between progress bar and toggle
                          SizedBox(height: 20),
                          
                          // Toggle for completed tasks
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
            Text(
                                "Show completed tasks",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              // Custom-styled switch
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showCompletedTasks = !_showCompletedTasks;
                                    // Reset editing if the task being edited becomes hidden
                                    if (_editingIndex != null && 
                                        _editingIndex! < _tasks.length && 
                                        _tasks[_editingIndex!].isCompleted && 
                                        !_showCompletedTasks) {
                                      _saveCurrentEditing();
                                      _editingIndex = null;
                                      _taskController.clear();
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  width: 36,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _showCompletedTasks ? Colors.black : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                    color: _showCompletedTasks ? Colors.black : Colors.transparent,
                                  ),
                                  child: Stack(
                                    children: [
                                      AnimatedPositioned(
                                        duration: Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        left: _showCompletedTasks ? 18 : 2,
                                        top: 1.5,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _showCompletedTasks ? Colors.white : Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 15),
                    
                    // Todo List Section - Use displayedTasks instead of _tasks
                    Expanded(
                      child: displayedTasks.isEmpty
                          ? GestureDetector(
                              onTap: _createFirstTask,
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Text(
                                  _tasks.isEmpty 
                                      ? "Create your first task" 
                                      : "No tasks to display",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : ReorderableListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              itemCount: displayedTasks.length,
                              buildDefaultDragHandles: false,
                              proxyDecorator: (child, index, animation) {
                                return Material(
                                  elevation: 2,
                                  color: Colors.white,
                                  shadowColor: Colors.black26,
                                  borderRadius: BorderRadius.circular(4),
                                  child: child,
                                );
                              },
                              onReorder: (int oldIndex, int newIndex) {
    setState(() {
      if (_editingIndex != null) {
        _saveCurrentEditing();
      }

      final Task movedTask = displayedTasks[oldIndex];
      final int actualOldIndex = _tasks.indexOf(movedTask);

      // Find all child tasks of the moved task
      final List<Task> groupToMove = [movedTask];
      final int parentIndent = _taskIndentLevels[movedTask.id] ?? 0;

      for (int i = actualOldIndex + 1; i < _tasks.length; i++) {
        final Task t = _tasks[i];
        final int indent = _taskIndentLevels[t.id] ?? 0;
        if (indent > parentIndent) {
          groupToMove.add(t);
        } else {
          break;
        }
      }

      // Remove the entire group from the _tasks list
      _tasks.removeRange(actualOldIndex, actualOldIndex + groupToMove.length);

      // Recalculate newIndex considering the removal
      if (oldIndex < newIndex) {
        newIndex -= groupToMove.length;
      }

      // Determine where to insert in actual _tasks
      int actualNewIndex = newIndex >= displayedTasks.length
          ? _tasks.length
          : _tasks.indexOf(displayedTasks[newIndex]);

      _tasks.insertAll(actualNewIndex, groupToMove);

      // Adjust editing index if needed
      if (_editingIndex != null) {
        final movedIds = groupToMove.map((t) => t.id).toSet();
        if (movedIds.contains(_tasks[_editingIndex!].id)) {
          _editingIndex = actualNewIndex + groupToMove.indexWhere((t) => t.id == _tasks[_editingIndex!].id);
        }
      }
    });

    _saveTasks();
  },
                              itemBuilder: (context, index) {
                                // Check if index is valid
                                if (index < 0 || index >= displayedTasks.length) {
                                  return SizedBox.shrink(key: Key('invalid_index_$index'));
                                }
                                
                                final task = displayedTasks[index];
                                final actualIndex = _tasks.indexOf(task);
                                
                                // Editing existing task
                                if (_editingIndex == actualIndex) {
                                  final int indentLevel = _taskIndentLevels[task.id] ?? 0;
                                  
                                  return Padding(
                                    key: Key('editing_task_${task.id}'),
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      key: ValueKey('editing_row_${task.id}'),
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Add indentation based on level
                                        if (indentLevel > 0) 
                                          SizedBox(width: 20.0 * indentLevel),
                                        
                                        // Checkbox (only show if not a title)
                                        if (!_isTitleTask(task))
                                          GestureDetector(
                                            onTap: () {
                                              if (index >= 0 && index < _tasks.length) {
                                                _toggleTask(index);
                                              }
                                            },
                                            child: Material(
                                              type: MaterialType.transparency,
                                              child: Checkbox(
                                                value: task.isCompleted,
                                                onChanged: (value) {
                                                  if (index >= 0 && index < _tasks.length) {
                                                    _toggleTask(index);
                                                  }
                                                },
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
                                        
                                        // Indicate if task has subtasks
                                        if (task.subtasks.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 4.0),
                                            child: Icon(
                                              Icons.subdirectory_arrow_right,
                                              size: 14,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        
                                        // Text field for editing
                                        Expanded(
                                          child: TextField(
                                            key: ValueKey(task.id),
                                            controller: _taskController,
                                            focusNode: _taskFocusNode,
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
                                              fontWeight: _isTitleTask(task) ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                            cursorColor: Colors.black,
                                            cursorWidth: 1.5,
                                            showCursor: true,
                                            autofocus: true,
                                            keyboardType: TextInputType.text,
                                            textInputAction: TextInputAction.next,
                                            onSubmitted: (value) {
                                              if (_editingIndex != null) {
                                                _createNewTaskAfter(_editingIndex!);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                // Regular task display
                                final int indentLevel = _taskIndentLevels[task.id] ?? 0;
                                
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
                                        onTap: () {
                                          if (index >= 0 && index < _tasks.length) {
                                            _startEditingTask(index);
                                          }
                                        },
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Add indentation based on level
                                            if (indentLevel > 0) 
                                              SizedBox(width: 20.0 * indentLevel),
                                            
                                            // Checkbox
                                            if (!_isTitleTask(task))
                                              GestureDetector(
                                                onTap: () {
                                                  if (index >= 0 && index < _tasks.length) {
                                                    _toggleTask(index);
                                                  }
                                                },
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
                                            // Collapse toggle button with safer handling
                                            if (_tasks[actualIndex].subtasks.isNotEmpty)
                                              GestureDetector(
                                                onTap: () {
                                                  if (index >= 0 && index < _tasks.length) {
                                                    setState(() {
                                                      _tasks[index].isCollapsed = !_tasks[index].isCollapsed;
                                                      _saveTasks(); // Save the collapsed state
                                                    });
                                                  }
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                                  child: Icon(
                                                    _tasks[index].isCollapsed ? Icons.expand_more : Icons.expand_less,
                                                    size: 18,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              ),
                                            SizedBox(width: 4),
                                            
                                            // Indicate if task has subtasks
                                            if (task.subtasks.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 4.0),
                                                child: Icon(
                                                  Icons.subdirectory_arrow_right,
                                                  size: 14,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            
                                            // Task text
                                            Expanded(
                                              child: Text(
                                                task.title,
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: _hasIndentedChild(actualIndex) ? FontWeight.w600 : FontWeight.normal,
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

  void _snapshotTasks() {
    _undoStack.add(_tasks.map((t) => Task(
      title: t.title,
      isCompleted: t.isCompleted,
      isCollapsed: t.isCollapsed,
      id: t.id,
      subtasks: List<Task>.from(t.subtasks),
    )).toList());
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }
  
  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_tasks);
      _tasks = _undoStack.removeLast();
      _editingIndex = null;
      _taskController.clear();
      setState(() {});
      _saveTasks();
    }
  }
  
  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_tasks);
      _tasks = _redoStack.removeLast();
      _editingIndex = null;
      _taskController.clear();
      setState(() {});
      _saveTasks();
    }
  }

  bool _hasIndentedChild(int parentIndex) {
    if (parentIndex < 0 || parentIndex >= _tasks.length - 1) return false;
    final String parentId = _tasks[parentIndex].id;
    final int parentIndent = _taskIndentLevels[parentId] ?? 0;

    for (int i = parentIndex + 1; i < _tasks.length; i++) {
      final int currentIndent = _taskIndentLevels[_tasks[i].id] ?? 0;
      if (currentIndent > parentIndent) return true;
      if (currentIndent <= parentIndent) break;
    }
    return false;
  }
} // End of _MyHomePageState class