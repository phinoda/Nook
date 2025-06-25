class ListInfo {
  final String id;
  String name;

  ListInfo({required this.id, required this.name});
 
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory ListInfo.fromJson(Map<String, dynamic> json) =>
      ListInfo(id: json['id'], name: json['name']);
} 