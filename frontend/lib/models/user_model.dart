class UserModel {
  final String name;
  final String? email;
  final String mobile;

  UserModel({
    required this.name,
    this.email,
    required this.mobile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'mobile': mobile,
  };
}