import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
    int id;
    String email;
    String name;
    String password;
    String role;

    User({
        required this.id,
        required this.email,
        required this.name,
        required this.password,
        required this.role,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        email: json["email"],
        name: json["name"],
        password: json["password"],
        role: json["role"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "email": email,
        "name": name,
        "password": password,
        "role": role,
    };
}
