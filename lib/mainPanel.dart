// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter_blue_plus_example/model/attribute.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus_example/http_session.dart';
import 'model/location.dart';
import 'model/tag.dart';
import 'bluetooth_screens.dart';
import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'model/constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'location_panel.dart';
import 'validation.dart';
import 'dart:developer';
// Demonstrates how to use autofill hints. The full list of hints is here:
// https://github.com/flutter/engine/blob/master/lib/web_ui/lib/src/engine/text_editing/autofill_hint.dart
class MainPanel extends StatefulWidget {
  MainPanel({super.key});

  @override
  State<MainPanel> createState() => _MainPanelState();


}

class _MainPanelState extends State<MainPanel> {
  final _formKey = GlobalKey<FormState>();
  String message = "Welcome to GAO BPN System";
  List<Location>? locations = [];
  List<Tag> scannedTags = [];
  late Location scannedLocation;
  _MainPanelState()
  {
    getLocations();
  }
  void getLocations()
  {
    HttpSession.instance.get(constants.baseURL + "/api/locations").then((result) {
      setState(() {
        Iterable l = json.decode(result);
        locations = List<Location>.from(l.map((model)=> Location.fromJson(model)));
      });
    });
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('GAO BPN - Main'),
        leading: _startBle(),
        actions: [
          PopupMenuButton(
            // add icon, by default "3 dot" icon
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context){
                return [
                  const  PopupMenuItem<int>(
                    value: 0,
                    child: Text("BLE Setting"),
                  ),

                  const PopupMenuItem<int>(
                    value: 1,
                    child: Text("Contact US"),
                  ),

                  const PopupMenuItem<int>(
                    value: 2,
                    child: Text("Logout"),
                  ),
                ];
              },
              onSelected:(value){
                if(value == 0){
                  Navigator.pushNamed(context,'bluetoothPanel');
                }else if(value == 1){
                  _launchUrl(constants.contactPage);
                }else if(value == 2){
                  Navigator.pushNamed(context,'logoutPanel');
                }
              }
          ),
        ],
      ),
      body:
      ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: locations?.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(message, style:TextStyle(fontWeight: FontWeight.bold,)),
                ListTile(
                leading: const Icon(Icons.star, color: Colors.red,),
                title: Text('${locations?[index].name} ', style: TextStyle(
                  fontWeight: FontWeight.bold,)),
                subtitle: _getAddress(locations?[index]),
                ),
                _getImage(locations?[index]),
                _getButtons(locations?[index]),
                _getDescription(locations?[index])
                ]));

                },
          )
    );
  }
  Column _buildButtonColumnCall(Color color, IconData icon, Location? location) {
    String phone = "1-800-123-5678"; // provide a default
    if ((location != null) && (location.attributes != null)) {
      String temp = Tools.findValue(location.attributes!, 'phone');
      if (temp.length >= 1) // at least has one number
        phone = temp;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: () {_callPhone(phone); },)),
            Text('CALL', style: TextStyle(fontSize: 12,fontWeight: FontWeight.w400, color: color,
              ),)
            ]
          );
  }
  Column _buildButtonColumnDetails(Color color, IconData icon, Location? location) {

    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              margin: const EdgeInsets.only(top: 8),
              child: IconButton(
                icon: Icon(icon, color: color),
                onPressed: () {_showLocation(location); },)),
          Text('GO', style: TextStyle(fontSize: 12,fontWeight: FontWeight.w400, color: color,
          ),)
        ]
    );
  }
  Column _buildButtonColumnWebsite(Color color, IconData icon, Location? location) {
    String website = "http://www.gaorfid.com"; // provide a default
    if ((location != null) && (location.attributes != null)) {
      String temp = Tools.findValue(location.attributes!, 'website');
      if (temp.length > 5 ) // at least 5 chars for a url
        website = temp;
    }
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              margin: const EdgeInsets.only(top: 8),
              child: IconButton(
                icon: Icon(icon, color: color),
                onPressed: () {_launchUrl(website); },)),
          Text('WEBSITE', style: TextStyle(fontSize: 12,fontWeight: FontWeight.w400, color: color,
          ),)
        ]
    );
  }
  Column _buildButtonColumnEmail(Color color, IconData icon, Location? location) {
    String email = "support@gaorfid.com"; // provide a default
    if ((location != null) && (location.attributes != null)) {
      String temp = Tools.findValue(location.attributes!, 'email');
      if (temp.length > 5 ) // at least 5 chars for a url
        email = temp;
    }
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              margin: const EdgeInsets.only(top: 8),
              child: IconButton(
                icon: Icon(icon, color: color),
                onPressed: () {_sendEmail(email); },)),
          Text('EMAIL', style: TextStyle(fontSize: 12,fontWeight: FontWeight.w400, color: color,
          ),)
        ]
    );
  }
  void _callPhone(String phone)
  {
    final Uri phoneUrl = Uri(
      scheme: 'tel',
      path: phone,
    );
    launchUrl(phoneUrl);
  }
  void _sendEmail(String email)
  {
    final Uri emailUrl = Uri(
      scheme: 'mailto',
      path: email,
    );
    launchUrl(emailUrl);
  }
  Widget _getButtons(Location? location) {
    Color color = Theme.of(context).primaryColor;
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButtonColumnCall(color, Icons.call, location),
          _buildButtonColumnEmail(color, Icons.email, location),
          _buildButtonColumnWebsite(color, Icons.web, location),
          _buildButtonColumnDetails(color, Icons.near_me, location),
        ]
    );
  }
  Padding _getDescription(Location? location)
  {
    String text = "";
    if ((location != null) && (location.attributes != null)) {
      text = Tools.findValue(location!.attributes!, 'description');
    }
    Padding textSection = Padding(
      padding: EdgeInsets.all(32),
      child: Text(text , softWrap: true, ),
    );
    return textSection;
  }
  Image _getImage(Location? location) {
    Image img = Image.asset(
        'assets/images/lake.jpg', height: 300);
    if (location != null) {
      if (location.image != null) {
        int index = location.image!.indexOf('base64,');
        if (index > 0) {
          img = Image.memory(
              base64Decode(location.image!.substring(index + 7)), height: 300, fit: BoxFit.cover);
        }
      }
    }
    return img;
  }

  Text _getAddress(Location? location)
  {
    Text rc = Text("");
    if ((location != null) && (location.attributes != null))
      {
        String temp = Tools.findValue(location.attributes!,'address');
        rc = Text(temp);
      }
    return rc;
  }
  void _launchUrl(String url)
  {
        Uri _url = Uri.parse(url);
        launchUrl(_url);
  }

  void _showLocation(Location? location) {
     if (location != null) {
      Navigator.push(
        context,
          MaterialPageRoute(
          builder: (context) => LocationPanel(location: location)),
      );
    }
  }
  void _showMessage(String text)
  {
    log(text);
    this.message =  text;
  }
  void _showCurrentLocation() {
    if (scannedLocation != null)
      _showLocation(scannedLocation);
    else
      _showMessage("no location detected");

  }
  IconButton  _startBle()
  {
    FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
    String bleScanUrl = constants.baseURL + "/api/blescans";
    return IconButton (
        onPressed: () => _showCurrentLocation(),
        icon:  StreamBuilder<BluetoothState>(
            stream: flutterBlue.state,
            initialData: BluetoothState.unknown,
            builder: (c, snapshot)
            {
              final state = snapshot.data;
              if (state == BluetoothState.on)
              {
                flutterBlue.startScan(timeout: Duration(seconds: 4));
                var subscription = flutterBlue.scanResults.listen((results) {
                  // do something with scan results
                  for (ScanResult r in results) {
                    HttpSession.instance.postScanToServer(r);
                    _findLocation(r);
                  }
                });
                return const Icon(Icons.launch, color: Colors.white);

              }
              else {
                return const Icon(Icons.settings_bluetooth, color: Colors.white);
              }
            })
    );
  }
  void _findLocation(ScanResult result)
  {
    String tagId = result.device.id.id;
    String url = Uri.encodeFull(constants.baseURL + '/api/tags/' + tagId);
    Tag? tag = Tools.findTag(scannedTags, tagId);
    if (tag == null) {
      HttpSession.instance.get(url).then((result) {
        Tag tag = Tag.fromJson(json.decode(result));
        if ((tag != null) && (tag.entityId != null)) {
          scannedTags.add(tag);
          url = constants.baseURL + '/api/locations/' + tag.entityId!;
          HttpSession.instance.get(url).then((result) {
            Location location = Location.fromJson(json.decode(result));
            if (location != null)
              scannedLocation = location;
          });
        }
      });
    }
    else
      {
        if (scannedLocation != null)
          {
            if ((tag.entityId != null) && (tag.entityId != scannedLocation.id)) // has detected a new location
              {
              url = constants.baseURL + '/api/locations/' + tag.entityId!;
              HttpSession.instance.get(url).then((result) {
                Location location = Location.fromJson(json.decode(result));
                if (location != null)
                  scannedLocation = location;
              });
            }
          }
        else if (tag.entityId != null) // there is no scanned location before
          {
            url = constants.baseURL + '/api/locations/' + tag.entityId!;
            HttpSession.instance.get(url).then((result) {
              Location location = Location.fromJson(json.decode(result));
              if (location != null)
                scannedLocation = location;
            });
          }
      }
  }
}

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBluePlus.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return const FindDevicesScreen();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}
