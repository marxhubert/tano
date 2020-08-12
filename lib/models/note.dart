class Note {
    String id;
    String title;
    String content;
    String date;
    bool important;

    Note({
        this.id,
        this.title,
        this.content,
        this.date,
        this.important,
    });

    factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        date: json['date'],
        important: json['important'] == 0 ? false : true,
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "content": content,
        "date": date,
        "important": important ? 1 : 0,
    };
}