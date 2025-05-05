import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatefulWidget {
  final String currentListTitle;
  final Function(String) onListSelected;
  final Function(String, String)? onListRenamed;
  
  const Sidebar({
    super.key, 
    required this.currentListTitle,
    required this.onListSelected,
    this.onListRenamed,
  });

  @override
  State<Sidebar> createState() => SidebarState();
}

class SidebarState extends State<Sidebar> {
  List<String> _lists = ['Today'];
  int? _editingIndex;
  final TextEditingController _editListController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadLists();
  }
  
  Future<void> _loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLists = prefs.getStringList('lists');
    if (savedLists != null && savedLists.isNotEmpty) {
      setState(() {
        _lists = savedLists;
        // Ensure "Today" is always in the list
        if (!_lists.contains('Today')) {
          _lists.insert(0, 'Today');
        }
      });
    }
  }
  
  Future<void> _saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('lists', _lists);
  }

  void _addNewList() {
    final newListName = 'Untitled ${_lists.length}';
    setState(() {
      _lists.add(newListName);
    });
    _saveLists();
    
    // Select the new list - this will trigger onListSelected with an empty list
    widget.onListSelected(newListName);
  }

  void updateCurrentListTitle(String oldTitle, String newTitle) {
    final index = _lists.indexOf(oldTitle);
    if (index != -1) {
      setState(() {
        _lists[index] = newTitle;
      });
      _saveLists();
    }
  }

  void _deleteList(int index) async {
    final listToDelete = _lists[index];
    
    // Delete the list's tasks from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tasks_$listToDelete');
    
    setState(() {
      _lists.removeAt(index);
    });
    _saveLists();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _lists.length,
                itemBuilder: (context, index) {
                  final isCurrentList = _lists[index] == widget.currentListTitle;
                  return GestureDetector(
                    onSecondaryTapDown: (details) {
                      showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                        ),
                        items: [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('Rename', style: TextStyle(fontSize: 12)),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ).then((value) {
                        if (value == 'rename') {
                          setState(() {
                            _editingIndex = index;
                            _editListController.text = _lists[index];
                          });
                        } else if (value == 'delete') {
                          _deleteList(index);
                        }
                      });
                    },
                    child: ListTile(
                      dense: true,
                      title: _editingIndex == index
                        ? TextField(
                            controller: _editListController,
                            autofocus: true,
                            onSubmitted: (newName) {
                              final oldName = _lists[index];
                              setState(() {
                                _lists[index] = newName;
                                _editingIndex = null;
                              });
                              _saveLists();
                              
                              // Notify the parent about the rename
                              if (widget.onListRenamed != null) {
                                widget.onListRenamed!(oldName, newName);
                              }
                              
                              // If this was the current list, update selection
                              if (widget.currentListTitle == oldName) {
                                widget.onListSelected(newName);
                              }
                            },
                          )
                        : Text(
                            _lists[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrentList ? FontWeight.bold : FontWeight.normal,
                              color: isCurrentList ? Colors.black : Colors.grey.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      selected: isCurrentList,
                      selectedTileColor: Colors.grey.shade200,
                      onTap: () {
                        widget.onListSelected(_lists[index]);
                      },
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1),
            GestureDetector(
              onTap: _addNewList,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.grey.shade700),
                    SizedBox(width: 8),
                    Text(
                      'New List',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}