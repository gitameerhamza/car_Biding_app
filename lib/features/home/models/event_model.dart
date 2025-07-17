class EventModel {
  final String name, location, date, description, imgURL;

  const EventModel({
    required this.name,
    required this.location,
    required this.date,
    required this.description,
    required this.imgURL,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      name: json["event_name"],
      location: json["event_venue"],
      date: json["event_date"],
      description: json["event_description"],
      imgURL: json["event_img_url"],
    );
  }
}
