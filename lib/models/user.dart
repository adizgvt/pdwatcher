// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  String accessToken;
  String userName;
  String userEmail;
  String userPicture;
  String tokenType;
  int storageId;
  int rootParentId;
  int usage;
  String quota;

  User({
    required this.accessToken,
    required this.userName,
    required this.userEmail,
    required this.userPicture,
    required this.tokenType,
    required this.storageId,
    required this.rootParentId,
    required this.usage,
    required this.quota,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    accessToken: json["accessToken"],
    userName: json["user_name"],
    userEmail: json["user_email"],
    userPicture: json["user_picture"],
    tokenType: json["token_type"],
    storageId: json["storageId"],
    rootParentId: json["rootParentId"],
    usage: json["usage"] == false ? 0 : json["usage"],
    quota: json["quota"],
  );

  Map<String, dynamic> toJson() => {
    "accessToken": accessToken,
    "user_name": userName,
    "user_email": userEmail,
    "user_picture": userPicture,
    "token_type": tokenType,
    "storageId": storageId,
    "rootParentId": rootParentId,
    "usage": usage,
    "quota": quota,
  };
}
