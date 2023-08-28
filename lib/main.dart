// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';
import 'location_panel.dart';
import 'mainPanel.dart';
import 'map_panel.dart';
import 'sign_in_http.dart';
import 'bluetooth_screens.dart';
import 'http_session.dart';
import 'model/constants.dart';
import 'model/ble_scan_data.dart';

void main() {
  setupWindow();
  runApp(const FormApp());
}

const double windowWidth = 480;
const double windowHeight = 854;

void setupWindow() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    WidgetsFlutterBinding.ensureInitialized();
    setWindowTitle('GAO BPN');
    setWindowMinSize(const Size(windowWidth, windowHeight));
    setWindowMaxSize(const Size(windowWidth, windowHeight));
    getCurrentScreen().then((screen) {
      setWindowFrame(Rect.fromCenter(
        center: screen!.frame.center,
        width: windowWidth,
        height: windowHeight,
      ));
    });
  }
}

class FormApp extends StatelessWidget {
  const FormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        routes: {
          'mainPanel': (context) => MainPanel(),
          'bluetoothPanel': (context) => const FlutterBlueApp2(),
          '/' : (context) =>  const HomePage(),
        });
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GAO BPN'),
      ),
      body: SignInHttp(),
    );
  }
}


