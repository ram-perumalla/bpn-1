import 'package:flutter_blue_plus_example/model/attribute.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'model/location.dart';
import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'model/constants.dart';
import 'model/tag.dart';
import 'dart:async';
import 'validation.dart';
import 'package:image/image.dart' as image;
import 'dart:convert';
import 'dart:ui' as ui;
import 'http_session.dart';
import 'package:flutter/services.dart' show rootBundle;
class LocationPanel extends StatefulWidget {
  static const routeName = '/locationPanel';
  Location location;
  LocationPanel({Key? key, required this.location}) : super(key: key)
  {

  }

   @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<LocationPanel> {
  late ui.Image location_image;
  double width_scale = 1.0; // image resize scale
  double height_scale = 1.0; // image resize scale
  List<Offset> points = []; // could be for installed tags or devices
  List<Tag> scannedTags = [];
  bool isImageloaded = false;


  @override
  void initState() {
    super.initState();
    init();
  }
  Future <Null> init() async {

    try {
      _loadImage();
    }
    catch(e)
    {
      print(e);
    }
    _setTimer();
  }
  void _loadImage() async
  {
    if (widget.location.image != null) {
      int index = widget.location.image!.indexOf('base64,');
      if (index > 0) {
        Uint8List base64 = base64Decode(widget.location.image!.substring(index + 7));
        location_image = await loadImage(base64);
      }
    }
    else {
      final ByteData data = await rootBundle.load('assets/images/lake.jpg');
      location_image = await loadImage(new Uint8List.view(data.buffer));
    }
    _loadInstalledDevices(widget.location.id);
  }
  void _setTimer() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        _getScannedLocations(widget.location.id, scannedTags);
      });
    });
  }
  void _loadInstalledDevices(String id)
  {
    HttpSession.instance.get(constants.baseURL + "/api/tags_location/"+id).then((result)
      {
        Iterable l = json.decode(result);
        scannedTags = List<Tag>.from(l.map((model)=> Tag.fromJson(model)));
        if (scannedTags != null)
          {
            for (Tag tag in scannedTags)
              points.add(Offset(tag.x/width_scale, tag.y/height_scale));
          }
        setState(() {
          isImageloaded = true;
        });
      });
  }
  Widget buildContent(BuildContext context)
  {
    if (this.isImageloaded) {
      return _panelContent(context);
    } else {
      return new Center(child: new Text('loading'));
    }
  }
  Future<ui.Image> loadImage(Uint8List img) async {

    image.Image? baseSizeImage = image.decodeImage(img);
    int width = baseSizeImage!.width;
    int height = baseSizeImage!.height;
    width_scale = width/450;
    height_scale = height/330;
    image.Image resizeImage = image.copyResize(baseSizeImage!, height: 330, width: 450);
    ui.Codec codec = await ui.instantiateImageCodec(image.encodePng(resizeImage));
    ui.FrameInfo frameInfo = await codec.getNextFrame();

    return frameInfo.image;
  }
  Widget _panelContent(BuildContext context)
  {
    Widget titleSection = Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            /*1*/
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*2*/
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${widget.location.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(_getAddress(widget.location),
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          /*3*/
          Icon(
            Icons.star,
            color: Colors.red[500],
          ),
          const Text('41'),
        ],
      ),
    );


    return MaterialApp(
      title: 'GAO BPN',
      home: Scaffold(
        appBar: _getAppBar(context),
        body: ListView(
          children: [
            titleSection,
            _getImage(widget.location),
            _getDescription(widget.location),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return buildContent(context);
  }
  Padding _getDescription(Location location) {
    String text = "description";
    if (location.attributes != null) {
      String temp = Tools.findValue(location.attributes!, 'description');
      if (temp.length > 2) // at least 2 chars
        text = temp;
    }
    Padding textSection = Padding(
      padding: EdgeInsets.only(left: 15),
      child: Text(text, softWrap: true,),
    );
    return textSection;
  }
  Container _getImage(Location location)  {
    return Container(
        height: 400,
        decoration: BoxDecoration(color: Colors.white, border: Border.all(
            color: Colors.white,
            width: 0.1,
            style: BorderStyle.solid
        ),),
        child: InteractiveViewer(
          boundaryMargin: EdgeInsets.all(0.0),
          child: CustomPaint(
            painter: LocationPainter(location: location, image: location_image,
                tags: scannedTags, width_scale: width_scale, height_scale: height_scale),
          ),
          maxScale: 10,
          panEnabled: true,
          scaleEnabled: true,
        )
    );
  }
}
class LocationPainter extends CustomPainter {

  static int counter = 0;
  bool locationScanned = false;
  double width_scale = 1.0;
  double height_scale = 1.0;
  LocationPainter({required this.image, required this.location, this.tags,
                   required this.width_scale, required this.height_scale});
  List<Tag>? tags;
  ui.Image image;
  Location location;
  var paintBlue = Paint()
    ..color = Colors.blueAccent
    ..style = PaintingStyle.fill;
  var paintRed = Paint()
    ..color = Colors.redAccent
    ..style = PaintingStyle.fill;
  @override
  void paint(Canvas canvas, Size size) {


    canvas.drawImage(image, new Offset(0.0, 0.0), new Paint());


    if ((tags != null) && (tags!.length > 0)) {
      for (int i= 0; i < tags!.length; i++) {
        if (counter == 1) {
          if (tags![i].scanned == true)
            canvas.drawCircle(Tools.getTagOffset(
                tags![i].x, tags![i].y, width_scale, height_scale), 2, paintRed);
          else
            canvas.drawCircle(Tools.getTagOffset(
              tags![i].x, tags![i].y, width_scale, height_scale), 2, paintBlue);
        }
        else if (counter == 2) {
          if (tags![i].scanned == true)
            canvas.drawCircle(Tools.getTagOffset(
                tags![i].x, tags![i].y, width_scale, height_scale), 3, paintRed);
          else
            canvas.drawCircle(Tools.getTagOffset(
                tags![i].x, tags![i].y, width_scale, height_scale), 3, paintBlue);
        }
        else if (counter == 3) {
          if (tags![i].scanned == true)
            canvas.drawCircle(Tools.getTagOffset(
                tags![i].x, tags![i].y, width_scale, height_scale), 4,
                paintRed);
          else
            canvas.drawCircle(Tools.getTagOffset(
                tags![i].x, tags![i].y, width_scale, height_scale), 4,
                paintBlue);
        }
        else if (counter == 4) {
          if (tags![i].scanned == true)
            canvas.drawCircle(Tools.getTagOffset(
                tags![i].x, tags![i].y, width_scale, height_scale), 5,
                paintRed);
          else
            canvas.drawCircle(Tools.getTagOffset(
                tags![i].x, tags![i].y, width_scale, height_scale), 5,
                paintBlue);
        }
      }
    }
    if (counter == 4)
      counter = 1;
    else
      counter++;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
       return true ;
    }
  }

  void _getScannedLocations(String locationId, List<Tag> scannedTags)
  {
    FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
    flutterBlue.startScan(timeout: Duration(seconds: 2));
    var subscription = flutterBlue.scanResults.listen((results)
    {
       for (ScanResult r in results) {
          _paintActiveTag(r, locationId, scannedTags);
      }
    });
}
  String _getAddress(Location location) {
    String rc = "";
    if (location.attributes != null) {
      rc = Tools.findValue(location.attributes!, 'address');
    }
    return rc;
  }
void _paintActiveTag(ScanResult result, String locationId, List<Tag> scannedTags)
{
  String tagId = result.device.id.id;
  Tag? tag = Tools.findTag(scannedTags, tagId);
  if (tag == null) {
    String url = Uri.encodeFull(constants.baseURL + '/api/tags/' + tagId);
    HttpSession.instance.get(url).then((result) {
      Tag tag = Tag.fromJson(json.decode(result));
      if ((tag != null) && (tag.entityId != null) &&
          (tag.entityId == locationId)) {
              tag.scanned = true;
      }
    });
  }
  else
    {
      if ((tag.entityId != null) && (tag.entityId == locationId))
      {
        tag.scanned = true;
      }
    }

}
  AppBar _getAppBar(BuildContext context) {
    return AppBar(
      title: const Text('GAO BPN'),
      actions: [
        PopupMenuButton(
          // add icon, by default "3 dot" icon
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) {
              return [
                const PopupMenuItem<int>(
                  value: 0,
                  child: Text("BACK"),
                ),
                const PopupMenuItem<int>(
                  value: 1,
                  child: Text("BLE Setting"),
                ),

                const PopupMenuItem<int>(
                  value: 2,
                  child: Text("Contact US"),
                ),

                const PopupMenuItem<int>(
                  value: 3,
                  child: Text("Logout"),
                ),
              ];
            },
            onSelected: (value) {
              if (value == 0) {
                Navigator.pushNamed(context, 'mainPanel');
              }
              else if (value == 1) {
                Navigator.pushNamed(context, 'bluetoothPanel');
              } else if (value == 2) {
                Navigator.pushNamed(context, 'contactPanel');
              } else if (value == 3) {
                Navigator.pushNamed(context, 'logoutPanel');
              }
            }
        ),
      ],
    );
}







