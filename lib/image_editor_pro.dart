import 'dart:async';
import 'dart:io';
// import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:signature/signature.dart';

import 'modules/bottombar_container.dart';

TextEditingController heightcontroler = TextEditingController();
TextEditingController widthcontroler = TextEditingController();
var width = 300;
var height = 300;
List<Map> widgetJson = [];
//List fontsize = [];
//List<Color> colorList = [];
var howmuchwidgetis = 0;
//List multiwidget = [];
Color currentcolors = Colors.white;
var opicity = 0.0;
SignatureController _controller =
    SignatureController(penStrokeWidth: 5, penColor: Colors.green);

class ImageEditorPro extends StatefulWidget {
  final Color appBarColor;
  final Color bottomBarColor;
  final Directory? pathSave;
  final double? pixelRatio;
  final XFile? defaultImage;
  final String? defaultImagePath;
  final bool hideCamera;
  final bool hideClearButton;
  final bool hideSizing;

  ImageEditorPro({
    required this.appBarColor,
    required this.bottomBarColor,
    required this.pathSave,
    required this.pixelRatio,
    this.defaultImage,
    this.defaultImagePath,
    this.hideCamera = false,
    this.hideClearButton = false,
    this.hideSizing = false,
  });

  @override
  _ImageEditorProState createState() => _ImageEditorProState();
}

var slider = 0.0;

class _ImageEditorProState extends State<ImageEditorPro> {
  // create some values
  Color pickerColor = Color(0xff443a49);
  Color currentColor = Color(0xff443a49);

// ValueChanged<Color> callback
  void changeColor(Color color) {
    setState(() => pickerColor = color);
    var points = _controller.points;
    _controller =
        SignatureController(penStrokeWidth: 5, penColor: color, points: points);
  }

  List<Offset> offsets = [];
  Offset offset1 = Offset.zero;
  Offset offset2 = Offset.zero;
  final scaf = GlobalKey<ScaffoldState>();
  var openbottomsheet = false;
  List<Offset?> _points = <Offset>[];
  List type = [];
  List aligment = [];

  final GlobalKey container = GlobalKey();
  final GlobalKey globalKey = GlobalKey();
  File? _image;
  ScreenshotController screenshotController = ScreenshotController();
  late Timer timeprediction;

  void timers() {
    Timer.periodic(Duration(milliseconds: 10), (tim) {
      setState(() {});
      timeprediction = tim;
    });
  }

  @override
  void dispose() {
    timeprediction.cancel();
    _controller.clear();
    widgetJson.clear();
    heightcontroler.clear();
    widthcontroler.clear();
    super.dispose();
  }

  @override
  void initState() {
    timers();
    _controller.clear();
    type.clear();
    offsets.clear();
    howmuchwidgetis = 0;

    setupDefaultImage();

    super.initState();
  }

  Future<void> setupDefaultImage() async {
    if (widget.defaultImage == null && widget.defaultImagePath == null) return;

    var imagePath = widget.defaultImagePath ?? '';
    if (widget.defaultImage != null) {
      imagePath = widget.defaultImage!.path;
    }

    var decodedImage = await decodeImageFromList(
      File(imagePath).readAsBytesSync(),
    );

    setState(() {
      height = decodedImage.height;
      width = decodedImage.width;
      _image = File(imagePath);
    });
  }

  double flipValue = 0;
  int rotateValue = 0;
  double blurValue = 0;
  double opacityValue = 0;
  Color colorValue = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // brightness: Brightness.dark,
        backgroundColor: widget.appBarColor,
        actions: [
          TextButton(
            onPressed: () {
              screenshotController
                  .capture(pixelRatio: widget.pixelRatio ?? 1.5)
                  .then((binaryIntList) async {
                final paths = widget.pathSave ?? await getTemporaryDirectory();

                final file = await File(
                        '${paths.path}/' + DateTime.now().toString() + '.jpg')
                    .create();
                if (binaryIntList != null) {
                  file.writeAsBytesSync(binaryIntList);
                }
                Navigator.pop(context, file);
              }).catchError((onError) {
                print(onError);
              });
            },
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      bottomNavigationBar: openbottomsheet
          ? Container()
          : SafeArea(
              child: Container(
                padding: EdgeInsets.all(0.0),
                height: 70.0,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10.9,
                      color: widget.bottomBarColor,
                    ),
                  ],
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    BottomBarContainer(
                      colors: widget.bottomBarColor,
                      icons: FontAwesomeIcons.brush,
                      ontap: () {
                        // raise the [showDialog] widget
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Pick a color!'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: pickerColor,
                                  onColorChanged: changeColor,
                                  showLabel: true,
                                  pickerAreaHeightPercent: 0.8,
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    setState(() => currentColor = pickerColor);
                                    Navigator.pop(context);
                                  },
                                  child: Text('Got it'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      title: 'Brush',
                    ),
                    BottomBarContainer(
                      colors: widget.bottomBarColor,
                      icons: FontAwesomeIcons.eraser,
                      ontap: () {
                        _controller.clear();
                        //  type.clear();
                        // // fontsize.clear();
                        //  offsets.clear();
                        // // multiwidget.clear();
                        howmuchwidgetis = 0;
                      },
                      title: 'Eraser',
                    ),
                  ],
                ),
              ),
            ),
      body: Center(
        child: Screenshot(
          controller: screenshotController,
          child: Container(
            margin: EdgeInsets.all(20),
            color: Colors.white,
            width: width.toDouble(),
            height: height.toDouble(),
            child: RepaintBoundary(
              key: globalKey,
              child: Stack(
                children: [
                  _image != null
                      ? Container(
                          padding: EdgeInsets.zero,
                          // alignment: Alignment.center,
                          width: width.toDouble(),
                          height: height.toDouble(),

                          decoration: _image == null
                              ? null
                              : BoxDecoration(
                                  image: DecorationImage(
                                      image: FileImage(
                                        File(_image!.path),
                                      ),
                                      fit: BoxFit.fitHeight),
                                ),

                          child: Container(
                            color: colorValue.withOpacity(opacityValue),
                          ),
                        )
                      : Container(),
                  Container(
                    padding: EdgeInsets.all(0.0),
                    child: GestureDetector(
                      onPanUpdate: (DragUpdateDetails details) {
                        setState(() {
                          var object = context.findRenderObject() as RenderBox?;
                          var _localPosition =
                              object?.globalToLocal(details.globalPosition);
                          _points = List.from(_points)..add(_localPosition);
                        });
                      },
                      onPanEnd: (DragEndDetails details) {
                        _points.add(null);
                      },
                      child: Signat(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Signat extends StatefulWidget {
  @override
  _SignatState createState() => _SignatState();
}

class _SignatState extends State<Signat> {
  @override
  void initState() {
    super.initState();
    _controller.addListener(() => print('Value changed'));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Signature(
          controller: _controller,
          height: height.toDouble(),
          width: width.toDouble(),
          backgroundColor: Colors.transparent,
        ),
      ],
    );
  }
}
