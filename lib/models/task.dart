class Task {
  int? id; // null when not saved yet
  String title;
  String? description;
  int isDone; // 0 or 1 to store boolean

  Task({this.id, required this.title, this.description, this.isDone = 0});

  factory Task.fromMap(Map<String, dynamic> m) => Task(
        id: m['id'] as int?,
        title: m['title'] as String,
        description: m['description'] as String?,
        isDone: (m['isDone'] as int?) ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'isDone': isDone,
      };
}
