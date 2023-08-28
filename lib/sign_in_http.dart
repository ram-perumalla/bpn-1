// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'google_login_service.dart';
import 'dart:convert';
import 'model/constants.dart';
import 'model/tag.dart';
import 'model/location.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'http_session.dart';

part 'sign_in_http.g.dart';

@JsonSerializable()
class FormData {
  String? email;
  String? password;

  FormData({
    this.email,
    this.password,
  });

  factory FormData.fromJson(Map<String, dynamic> json) =>
      _$FormDataFromJson(json);

  Map<String, dynamic> toJson() => _$FormDataToJson(this);
}

class SignInHttp extends StatefulWidget {
  const SignInHttp({Key? key});

  @override
  State<SignInHttp> createState() => _SignInHttpState();
}

class _SignInHttpState extends State<SignInHttp> {
  FormData formData = FormData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    filled: true,
                    hintText: 'Your email address',
                    labelText: 'Email',
                  ),
                  onChanged: (value) {
                    formData.email = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    filled: true,
                    labelText: 'Password',
                  ),
                  obscureText: true,
                  onChanged: (value) {
                    formData.password = value;
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      child: const Text('Login'),
                      onPressed: () {
                        print('Logging in...');
                        var code = HttpSession.instance
                            .login(formData.email.toString(),
                                formData.password.toString(), context)
                            .then((value) {
                          if (value != 200) {
                            print('Login failed with code: $value');
                            _showDialog('Something went wrong. Please try again.' + value.toString());
                          } else {
                            print('Login successful!');
                          }
                        });
                      },
                    ),
                    TextButton(
                      child: const Text('Login with Google'),
                      onPressed: () {
                        googleSignIn();
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _startBle(),
                  ],
                ),
                // Other form fields and buttons
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  IconButton _startBle() {
    FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
    String bleScanUrl = constants.baseURL + "/api/blescans";
    return IconButton(
      onPressed: () => _startBleScan(),
      icon: StreamBuilder<BluetoothState>(
        stream: flutterBlue.state,
        initialData: BluetoothState.unknown,
        builder: (c, snapshot) {
          final state = snapshot.data;
          if (state == BluetoothState.on) {
            return Icon(Icons.bluetooth_connected);
          }
          return Icon(Icons.bluetooth_disabled);
        },
      ),
    );
  }

  void _startBleScan() async {
    FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
    var session = HttpSession.instance;
    session.getAccessToken().then((accessToken) {
      if (accessToken != null) {
        flutterBlue.startScan(timeout: const Duration(seconds: 4));
        flutterBlue.scanResults.listen((results) async {
          for (ScanResult r in results) {
            await _findLocation(r.device.id.id);
          }
        });
      } else {
        _showDialog('Please log in before starting Bluetooth scan.');
      }
    });
  }

  Future<void> _findLocation(String tagId) async {
    String findLocationUrl = constants.baseURL + "/api/tags/$tagId";
    var session = HttpSession.instance;
    var accessToken = await session.getAccessToken();
    var response = await http.get(
      Uri.parse(findLocationUrl),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      Tag tag = Tag.fromJson(jsonDecode(response.body));
      if (tag.locationId != null) {
        _showCurrentLocation(tag.locationId!);
      }
    } else {
      print('Error finding location: ${response.statusCode}');
    }
  }

  void _showCurrentLocation(String locationId) async {
    String getLocationUrl = constants.baseURL + "/api/locations/$locationId";
    var session = HttpSession.instance;
    var accessToken = await session.getAccessToken();
    var response = await http.get(
      Uri.parse(getLocationUrl),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      Location location = Location.fromJson(jsonDecode(response.body));
      _showLocation(location);
    } else {
      print('Error getting location: ${response.statusCode}');
    }
  }

  void _showLocation(Location location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(location.name),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Address: ${location.address}'),
              Text('Description: ${location.description}'),
              // Other location details
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void googleSignIn() {
    final googleService = GoogleLoginService();
    googleService.signInWithGoogle().then((result) {
      if (result != null) {
        print('Google sign-in successful!');
        // Perform necessary actions after successful sign-in
      } else {
        print('Google sign-in failed.');
        _showDialog('Google sign-in failed. Please try again.');
      }
    });
  }
}
