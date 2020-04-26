import 'dart:convert';

import 'package:http/http.dart' as http;

class WebServices {
  static const cardsBaseUrl = "https://nico04.github.io/dixit/cards/";

  static Future<List<String>> getCardsNames() async {
    var response = await http.get(
      Uri.encodeFull(cardsBaseUrl + "cards.json")
    );

    var result = _processResponse<List<dynamic>>(response);

    return result.cast();
  }

  static T _processResponse<T>(http.Response response) {
    //Read response body
    var responseBody = response.body;
    T jsonResponse;
    try {
      jsonResponse = json.decode(responseBody);
    } catch (e) {
      //Error is handled bellow
      print('WS.jsonDecode.Error: $e');
    }

    //Process response
    if (isHttpSuccessCode(response.statusCode) && (responseBody?.isNotEmpty != true || jsonResponse != null)) {
      return jsonResponse;
    } else {
      throw HttpResponseException(response, jsonResponse: jsonResponse is Map<String, dynamic> ? jsonResponse : null);
    }
  }

  static bool isHttpSuccessCode (int httpStatusCode) => httpStatusCode >= 200 && httpStatusCode < 300;
}

class HttpResponseException implements Exception {
  final int statusCode;
  final String message;
  final String details;

  HttpResponseException(http.Response httpResponse, {Map<String, dynamic> jsonResponse}) :
      statusCode = httpResponse.statusCode,
      message = (jsonResponse ?? const{})['error'] ?? (jsonResponse ?? const{})['message'] ?? httpResponse.reasonPhrase,
      details = ((jsonResponse ?? const{})['error'] != null ? (jsonResponse ?? const{})['message']  : null)?.toString() ?? '';

  @override
  String toString() => 'Erreur $statusCode : $message';
}