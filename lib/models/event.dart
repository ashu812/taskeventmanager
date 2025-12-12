class EventItem {
  int? id;
  String title;
  String date; // store yyyy-MM-dd
  String time; // store HH:mm

  EventItem({this.id, required this.title, required this.date, required this.time});

  factory EventItem.fromMap(Map<String, dynamic> m) => EventItem(
        id: m['id'] as int?,
        title: m['title'] as String,
        date: m['date'] as String,
        time: m['time'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'date': date,
        'time': time,
      };
}
