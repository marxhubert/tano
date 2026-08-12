class Note {
  String? id;
  String? title;
  String? content;
  String? date;
  bool? important;
  String? category;

  Note({
    this.id,
    this.title,
    this.content,
    this.date,
    this.important,
    this.category,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String?,
    title: json['title'] as String?,
    content: json['content'] as String?,
    date: json['date'] as String?,
    important: json['important'] == 1,
    category: json['category'] as String?,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "content": content,
    "date": date,
    "important": important == true ? 1 : 0,
    "category": category,
  };
}
