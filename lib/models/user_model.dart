class UserModel {
  int? id;
  String name;
  String email;
  String password;
  bool isSynced;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.isSynced = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        password: json['password'],
        isSynced: json['isSynced'] == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'isSynced': isSynced ? 1 : 0,
      };
}
