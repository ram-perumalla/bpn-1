import 'attribute.dart';
class Location
{
  String id;
  String name;
  String createDate;
  String? image;
  String? parentId;
  String? locationType;
  List<Attribute>? attributes;
  Location({required this.id, required this.name, required this.createDate, this.image, this.parentId, this.locationType,  this.attributes});

  factory Location.fromJson(Map<String, dynamic> json) {
    List<Attribute>? temp;
    if (json['attributes'] != null) {
      temp =  List<Attribute>.from(json['attributes'].map((model)=> Attribute.fromJson(model)));
    }
    return Location(
        id: json['id'] ,
        name: json['name'] ,
        createDate: json['createDate'],
        image: json['image'],
        parentId: json['parentId'] ,
        locationType: json['locationType'],
        attributes: temp
    );
  }

}