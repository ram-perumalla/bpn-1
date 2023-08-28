import 'package:flutter_blue_plus_example/model/session_object.dart';
import 'package:http/http.dart' as http;
import 'model/user.dart';
import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'model/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'model/ble_scan_data.dart';
class HttpSession {
  static final HttpSession _instance = HttpSession._internal();
  Map<String, String> headers = {};
  User? user;
  List<SessionData> sessionObjects = [];

  factory HttpSession() {
    return _instance;
  }
  HttpSession._internal() {
    headers['Content-Type'] = 'application/json; charset=UTF-8';
    headers['Accept'] = 'application/json, text/plain, */*';
  }

  static HttpSession get instance => _instance;

  Future<String> get(String url) async {
    if (timeChecking(url) == true) {
      http.Response response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        updateCookie(response);
        return response.body;
      }
      else
        throw Exception("HTTP Get error: " + response.statusCode.toString());
    }
    else
      {
        return ""; // nothing will happen
      }
  }

  SessionData? getSessionData(String id)
  {
    SessionData? rc = null;
    try {
      rc = sessionObjects.firstWhere((element) => element.id == id);
    }
    catch (e)
    {

    }
    return rc;
  }
  bool timeChecking(String id)
  {
    bool rc = true;
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    SessionData? data = getSessionData(id);
    if (data != null)
      {
        if (timestamp - data.timestamp < 3000) // min 3 seconds
          rc = false;
        else
          data.timestamp = timestamp; // yes, update.
      }
    else {
      SessionData data = SessionData(id: id, timestamp: timestamp);
      sessionObjects.add(data);
    }

    return rc;
  }
    Future<int> login(String email, String password, BuildContext context) async {

    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String credentials = email + ':' + password;
    String encoded = stringToBase64.encode(credentials);
    var response = await http.get(
        Uri.parse(constants.getBaseUrl() + '/user'),
        headers: {
          'Authorization': 'Basic $encoded',
          'Accept': 'application/json, text/plain, */*'
        });
    if (response.statusCode == 200)
    {
      final Map<String, dynamic> parsed = json.decode(response.body);
      user = User.fromJson(parsed);
      user?.authStatus = 'AUTH';
      String? rawCookie = response.headers['set-cookie'];
      if (rawCookie != null) {
        int index = rawCookie.indexOf(';');
        headers['XSRF-TOKEN'] =
        (index == -1) ? rawCookie : rawCookie.substring(0, index);
      }
      rawCookie = response.headers['authorization'];
      if (rawCookie != null)
        headers['Authorization'] = rawCookie;

      headers['X-Requested-With'] = 'XMLHttpRequest';
      showMainPanel(context);
    }
    return response.statusCode;
  }
  void postScanToServer(ScanResult result)
  {
    if (timeChecking(result.device.id.id) == true) {
      String scanUrl = constants.baseURL + "/tagscans";
      BleScanData data = BleScanData(deviceId: result.device.id.id,
          name: result.device.name,
          rssi: result.rssi,
          deviceType: result.device.type.name,
          timestamp: (result.timeStamp.microsecondsSinceEpoch / 1000).floor());
      log(jsonEncode(data.toJson()));
      post(scanUrl, jsonEncode(data.toJson()));
    }
    else
      log('device scanned, but no need to update to the server: ' + result.device.id.id);
  }
  Future<String> post(String url, dynamic data) async {
    http.Response response = await http.post(
        Uri.parse(url), body: data, headers: headers);
    updateCookie(response);
    log('tag scan post status: ${response.statusCode}');
    return response.body;
  }

  void updateCookie(http.Response response) {

  }
  void showMainPanel(BuildContext context)
  {
    Navigator.pushNamed(context, 'mainPanel');
  }
}