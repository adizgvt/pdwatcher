// To parse this JSON data, do
//
//     final usage = usageFromJson(jsonString);

import 'dart:convert';

Usage usageFromJson(String str) => Usage.fromJson(json.decode(str));

String usageToJson(Usage data) => json.encode(data.toJson());

class Usage {
  int storageId;
  int rootParentId;
  int usage;
  String quota;

  Usage({
    required this.storageId,
    required this.rootParentId,
    required this.usage,
    required this.quota,
  });

  factory Usage.fromJson(Map<String, dynamic> json) => Usage(
    storageId: json["storageId"],
    rootParentId: json["rootParentId"],
    usage: json["usage"] == false ? 0 : json["usage"],
    quota: json["quota"],
  );

  Map<String, dynamic> toJson() => {
    "storageId": storageId,
    "rootParentId": rootParentId,
    "usage": usage,
    "quota": quota,
  };
}
