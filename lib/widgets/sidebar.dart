import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Your list of list titles will go here
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: Text("Untitled"),
                  onTap: () {},
                ),
                // Add more lists here
              ],
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.add, size: 20),
          ),
        ],
      ),
    );
  }
}