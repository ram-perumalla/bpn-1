class Tag {

  String id;
  String tagId;
  String? entityId;
  int x;
  int y;
  bool scanned = false;
  String? activationDate;
  String? expirationDate;
  String registrationDate;

  Tag({required this.id, required this.tagId, required this.registrationDate,
         required this.x, required this.y, this.entityId,
         this.activationDate, this.expirationDate});

  factory Tag.fromJson(Map<String, dynamic> json) {

    return Tag(
        id: json['id'] ,
        tagId: json['tagId'] ,
        registrationDate: json['registrationDate'],
        x: json['x'],
        y: json['y'] ,
        entityId: json['entityId'],
        activationDate: json['activationDate'],
        expirationDate: json['expirationDate'],
    );
  }

}
