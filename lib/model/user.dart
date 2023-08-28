class User
{
  String id;
  String name;
  String firstname;
  String lastname;
  String email;
  List<String>? authorities;
  String addTime;
  String? statusMsg;
  String? authStatus;

  User({required this.id, required this.name, required this.firstname, required this.lastname, required this.email, required this.addTime});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      email: json['email'] as String,
      addTime: json['addTime'] as String,
    );
  }
}