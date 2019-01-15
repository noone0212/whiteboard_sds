import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_permissions/simple_permissions.dart';

const directoryName = 'Drawer';

void main() {
  runApp(
      MaterialApp(
        home: SignApp(),
        debugShowCheckedModeBanner: false,
      )
  );
}

class SignApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SignAppState();
  }
}

class SignAppState extends State<SignApp>{
  GlobalKey<DrawerState> DrawerKey = GlobalKey();
  var image;
  String _platformVersion = 'Unknown';
  Permission _permission = Permission.WriteExternalStorage;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }
  initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await SimplePermissions.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
    print(_platformVersion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        backgroundColor: Colors.black87,
        leading: new Icon(Icons.airplay,color: Colors.white,),
        title: new Text('My WhiteBoard',style: new TextStyle(color: Colors.white,fontFamily: 'Agency FB',fontSize: 20.0),),
      ),
      body: Drawer(key: DrawerKey),
      persistentFooterButtons: <Widget>[
        new MaterialButton(
          color: Colors.black87,
          child: Icon(Icons.delete_forever,color: Colors.white,size: 40.0,),
          onPressed: () {
            DrawerKey.currentState.clearcoordinates();
          },
        ),
        new MaterialButton(
          color: Colors.black87,
          child: Icon(Icons.save,color: Colors.white,size: 40.0,),
          onPressed: () {
            setState(() {
              image = DrawerKey.currentState.rendered;
            });
            showImage(context);
          },
        ),
      ],
    );
  }

  Future<Null> showImage(BuildContext context) async {
    var pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if(!(await checkPermission())) await requestPermission();
    Directory directory = await getExternalStorageDirectory();
    String path = directory.path;
    print(path);
    await Directory('$path/$directoryName').create(recursive: true);
    File('$path/$directoryName/${formattedDate()}.png')
        .writeAsBytesSync(pngBytes.buffer.asInt8List());
    return showDialog<Null>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Image.memory(Uint8List.view(pngBytes.buffer)),
          );
        }
    );
  }

  String formattedDate() {
    DateTime dateTime = DateTime.now();
    String dateTimeString = 'Drawer_' +
        dateTime.year.toString() +
        dateTime.month.toString() +
        dateTime.day.toString() +
        dateTime.hour.toString() +
        ':' + dateTime.minute.toString() +
        ':' + dateTime.second.toString() +
        ':' + dateTime.millisecond.toString() +
        ':' + dateTime.microsecond.toString();
    return dateTimeString;
  }

  requestPermission() async {
    PermissionStatus result = await SimplePermissions.requestPermission(_permission);
    return result;
  }

  checkPermission() async {
    bool result = await SimplePermissions.checkPermission(_permission);
    return result;
  }

  getPermissionStatus() async {
    final result = await SimplePermissions.getPermissionStatus(_permission);
    print("permission status is " + result.toString());
  }

}

class Drawer extends StatefulWidget {
  Drawer({Key key}): super(key: key);
  @override
  Widget build(BuildContext context){
    return new Scaffold(
      body: new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new Image(
              //color: Colors.white70,
              image: new AssetImage('assets/white_back.jpg')),
        ],
      ),
    );
  }
  @override
  State<StatefulWidget> createState() {
    return DrawerState();
  }
}

class DrawerState extends State<Drawer> {
  List<Offset> _coordinates = <Offset>[];

  ui.Image get rendered {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    DrawerPainter painter = DrawerPainter(coordinates: _coordinates);
    var size = context.size;
    painter.paint(canvas, size);
    return recorder.endRecording()
        .toImage(size.width.floor(), size.height.floor());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: GestureDetector(
          onPanUpdate: (DragUpdateDetails details) {
            setState(() {
              RenderBox _object = context.findRenderObject();
              Offset _locationcoordinates = _object.localToGlobal(details.globalPosition);
              _coordinates = new List.from(_coordinates)..add(_locationcoordinates);
            });
          },
          onPanEnd: (DragEndDetails details) {
            setState(() {
              _coordinates.add(null);
            });
          },
          child: CustomPaint(
            painter: DrawerPainter(coordinates: _coordinates),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
  void clearcoordinates() {
    setState(() {
      _coordinates.clear();
    });
  }
}


class DrawerPainter extends CustomPainter {
  List<Offset> coordinates = <Offset>[];
  Color Text_Color=Colors.black;
  @override
  Widget build(BuildContext context){
    return new Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          new MaterialButton(
            color: Colors.black87,
            onPressed:()=> Text_Color=Colors.red,
            child: new Icon(Icons.colorize,color: Colors.red,size: 40.0,),
          ),
          new MaterialButton(
            color: Colors.black87,
            onPressed: ()=>Text_Color=Colors.blue,
            child: new Icon(Icons.colorize,color: Colors.blue,size: 40.0,),
          ),
          new MaterialButton(
            color: Colors.black87,
            onPressed: ()=>Text_Color=Colors.black,
            child: new Icon(Icons.colorize,color: Colors.black,size: 40.0,),
          ),
        ],
    );
  }
  DrawerPainter({this.coordinates});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Text_Color
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 5.0;

    for(int i=0; i < coordinates.length - 1; i++) {
      if(coordinates[i] != null && coordinates[i+1] != null) {
        canvas.drawLine(coordinates[i], coordinates[i+1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawerPainter oldDelegate) =>oldDelegate.coordinates != coordinates;

}