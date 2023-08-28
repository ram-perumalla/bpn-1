class Attribute
{
  String name;
  String value;
  Attribute({required this.name, required this.value});
  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
        name: json['name'] ,
        value: (json['value'] != null)? json['value'] : '',
    );
  }
}