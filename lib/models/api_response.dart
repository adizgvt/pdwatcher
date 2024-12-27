import 'dart:convert';

class ApiResponse {
  int? statusCode;
  String? message;
  Errors? errors;
  Object? data;
}

class Errors {

  String? error;
  Map<String, dynamic>? errorMap;
  Errors({this.error, this.errorMap});

  Errors.fromJson(Map<String, dynamic> json) {
    error = '';
    errorMap = json;
    json.forEach((key, value) {
      List<dynamic> detailedErrors = jsonDecode(jsonEncode(value));
      for (var element in detailedErrors) {error = '${error! + element}\n';}
    });

  }
}