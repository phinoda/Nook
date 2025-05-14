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
  Set<String> _pinnedLists = {'Today'};
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
    final savedPinnedLists = prefs.getStringList('pinned_lists') ?? ['Today'];
    
    if (savedLists != null && savedLists.isNotEmpty) {
      setState(() {
        _lists = savedLists;
        _pinnedLists = savedPinnedLists.toSet();
        // Ensure "Today" is always in the list and pinned
        if (!_lists.contains('Today')) {
          _lists.insert(0, 'Today');
        }
        _pinnedLists.add('Today');
      });
    }
  }
  
  Future<void> _saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('lists', _lists);
    await prefs.setStringList('pinned_lists', _pinnedLists.toList());
  }

  void _togglePin(int index) {
    final listName = _lists[index];
    setState(() {
      if (_pinnedLists.contains(listName)) {
        _pinnedLists.remove(listName);
      } else {
        _pinnedLists.add(listName);
      }
    });
    _saveLists();
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
    // Sort lists to put pinned ones at the top
    final sortedLists = List<String>.from(_lists)
      ..sort((a, b) {
        final aPinned = _pinnedLists.contains(a);
        final bPinned = _pinnedLists.contains(b);
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        return _lists.indexOf(a).compareTo(_lists.indexOf(b));
      });

    return Container(
      width: 200,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                itemCount: sortedLists.length,
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  // Adjust indices for pinned items
                  final oldItem = sortedLists[oldIndex];
                  final newItem = sortedLists[newIndex];
                  
                  // Don't allow reordering if either item is pinned
                  if (_pinnedLists.contains(oldItem) || _pinnedLists.contains(newItem)) {
                    return;
                  }
                  
                  // Calculate actual indices in _lists
                  final actualOldIndex = _lists.indexOf(oldItem);
                  final actualNewIndex = _lists.indexOf(newItem);
                  
                  setState(() {
                    final item = _lists.removeAt(actualOldIndex);
                    _lists.insert(actualNewIndex, item);
                  });
                  _saveLists();
                },
                itemBuilder: (context, index) {
                  final listName = sortedLists[index];
                  final isCurrentList = listName == widget.currentListTitle;
                  final isPinned = _pinnedLists.contains(listName);
                  
                  return ReorderableDragStartListener(
                    key: Key(listName),
                    index: index,
                    child: GestureDetector(
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
                              value: isPinned ? 'unpin' : 'pin',
                              child: Text(
                                isPinned ? 'Unpin' : 'Pin',
                                style: TextStyle(fontSize: 12),
                              ),
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
                              _editingIndex = _lists.indexOf(listName);
                              _editListController.text = listName;
                            });
                          } else if (value == 'pin' || value == 'unpin') {
                            _togglePin(_lists.indexOf(listName));
                          } else if (value == 'delete') {
                            _deleteList(_lists.indexOf(listName));
                          }
                        });
                      },
                      child: ListTile(
                        dense: true,
                        leading: isPinned ? Transform.rotate(
                          angle: 0.785398, // 45 degrees in radians (π/4)
                          child: Icon(Icons.push_pin, size: 16, color: Colors.black),
                        ) : null,
                        contentPadding: EdgeInsets.only(
                          left: isPinned ? 16.0 : 40.0, // Add padding for non-pinned items
                          right: 16.0,
                        ),
                        horizontalTitleGap: 2,
                        title: _editingIndex == _lists.indexOf(listName)
                          ? TextField(
                              controller: _editListController,
                              autofocus: true,
                              onSubmitted: (newName) {
                                final oldName = listName;
                                setState(() {
                                  _lists[_lists.indexOf(listName)] = newName;
                                  _editingIndex = null;
                                });
                                _saveLists();
                                
                                if (widget.onListRenamed != null) {
                                  widget.onListRenamed!(oldName, newName);
                                }
                                
                                if (widget.currentListTitle == oldName) {
                                  widget.onListSelected(newName);
                                }
                              },
                            )
                          : Text(
                              listName,
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
                          widget.onListSelected(listName);
                        },
                      ),
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