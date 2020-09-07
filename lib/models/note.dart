class Note {
    String id;
    String title;
    String content;
    String date;
    bool important;
    String category;

    Note({
        this.id,
        this.title,
        this.content,
        this.date,
        this.important,
        this.category,
    });

    factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        date: json['date'],
        important: json['important'] == 0 ? false : true,
        category: json['category'],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "content": content,
        "date": date,
        "important": important ? 1 : 0,
        "category": category,
    };
}