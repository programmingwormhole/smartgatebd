import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  static const String _authTokenKey = 'auth_token';

  // Helper method to get cached token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  // Helper to save token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  // Helper to clear token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  void _logRequest(
    String method,
    String url,
    Map<String, String>? headers,
    dynamic body,
  ) {
    log('================= API REQUEST =================');
    log('Method: $method');
    log('URL: $url');
    log('Headers: ${jsonEncode(headers)}');
    if (body != null) {
      log('Body: $body');
    }
    log('=============================================');
  }

  void _logResponse(http.Response response) {
    if (!ApiConstants.showLog) return;

    log('================= API RESPONSE =================');
    log('URL: ${response.request?.url}');
    log('Status Code: ${response.statusCode}');
    try {
      log('Body: ${jsonEncode(jsonDecode(response.body))}');
    } catch (e) {
      log('Body: ${response.body}');
    }
    log('==============================================');
  }

  // Base GET Request
  Future<http.Response> get(String endpoint) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = '${ApiConstants.baseUrl}$endpoint';
    if (!url.contains('unread-count')) _logRequest('GET', url, headers, null);

    final response = await http.get(Uri.parse(url), headers: headers);

    if (ApiConstants.isDev || !url.contains('unread-count')) _logResponse(response);
    return response;
  }

  // Base POST Request
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = '${ApiConstants.baseUrl}$endpoint';
    final bodyStr = jsonEncode(data);
    _logRequest('POST', url, headers, bodyStr);

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: bodyStr,
    );

    if (ApiConstants.isDev) _logResponse(response);
    return response;
  }

  // Base Multipart POST Request
  Future<http.Response> postMultipart(
    String endpoint,
    Map<String, String> fields,
    Map<String, String> files,
  ) async {
    final token = await getToken();
    final url = '${ApiConstants.baseUrl}$endpoint';

    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    request.fields.addAll(fields);

    for (var entry in files.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(entry.key, entry.value),
      );
    }

    _logRequest('POST (Multipart)', url, request.headers, fields);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (ApiConstants.isDev) _logResponse(response);
    return response;
  }

  // Base PUT Request
  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = '${ApiConstants.baseUrl}$endpoint';
    final bodyStr = jsonEncode(data);
    _logRequest('PUT', url, headers, bodyStr);

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: bodyStr,
    );

    if (ApiConstants.isDev) _logResponse(response);
    return response;
  }

  // Base DELETE Request
  Future<http.Response> delete(String endpoint) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = '${ApiConstants.baseUrl}$endpoint';
    _logRequest('DELETE', url, headers, null);

    final response = await http.delete(Uri.parse(url), headers: headers);

    if (ApiConstants.isDev) _logResponse(response);
    return response;
  }
}
