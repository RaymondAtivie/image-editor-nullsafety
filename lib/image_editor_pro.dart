import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:signature/signature.dart';

import 'modules/all_emojies.dart';
import 'modules/bottombar_container.dart';
import 'modules/color_filter_generator.dart';
import 'modules/colors_picker.dart'; // import this
import 'modules/emoji.dart';
import 'modules/sliders.dart';
import 'modules/text.dart';
import 'modules/textview.dart';

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

  ImageEditorPro({
    required this.appBarColor,
    required this.bottomBarColor,
    required this.pathSave,
    required this.pixelRatio,
    this.defaultImage,
    this.defaultImagePath,
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
    //  fontsize.clear();
    offsets.clear();
    //  multiwidget.clear();
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
      _image = File(widget.defaultImage!.path);
    });
  }

  double flipValue = 0;
  int rotateValue = 0;
  double blurValue = 0;
  double opacityValue = 0;
  Color colorValue = Colors.transparent;

  double hueValue = 0;
  double brightnessValue = 0;
  double saturationValue = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // brightness: Brightness.dark,
        backgroundColor: widget.appBarColor,
        actions: [
          IconButton(
              icon: Icon(FontAwesomeIcons.boxes),
              onPressed: () {
                showCupertinoDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Select Height Width'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              var mHeight = int.tryParse(heightcontroler.text);
                              var mWidth = int.tryParse(widthcontroler.text);
                              if (mWidth == null || mHeight == null) {
                                Navigator.pop(context);
                                return;
                              }
                              setState(() {
                                height = int.parse(heightcontroler.text);
                                width = int.parse(widthcontroler.text);
                              });
                              heightcontroler.clear();
                              widthcontroler.clear();
                              Navigator.pop(context);
                            },
                            child: Text('Done'),
                          ),
                        ],
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text('Define Height'),
                              const SizedBox(
                                height: 10.0,
                              ),
                              TextField(
                                  controller: heightcontroler,
                                  keyboardType:
                                      TextInputType.numberWithOptions(),
                                  decoration: InputDecoration(
                                      hintText: 'Height',
                                      contentPadding: EdgeInsets.only(left: 10),
                                      border: OutlineInputBorder())),
                              const SizedBox(
                                height: 10.0,
                              ),
                              Text('Define Width'),
                              const SizedBox(
                                height: 10.0,
                              ),
                              TextField(
                                  controller: widthcontroler,
                                  keyboardType:
                                      TextInputType.numberWithOptions(),
                                  decoration: InputDecoration(
                                      hintText: 'Width',
                                      contentPadding: EdgeInsets.only(left: 10),
                                      border: OutlineInputBorder())),
                            ],
                          ),
                        ),
                      );
                    });
              }),
          IconButton(
              onPressed: () {
                _controller.points.clear();
                setState(() {});
              },
              icon: Icon(Icons.clear)),
          IconButton(
              onPressed: () {
                bottomsheets();
              },
              icon: Icon(Icons.camera_alt)),
          TextButton(
            onPressed: () {
              screenshotController
                  .capture(pixelRatio: widget.pixelRatio ?? 1.5)
                  .then((binaryIntList) async {
                //print("Capture Done");

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
          : Container(
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
                    icons: Icons.text_fields,
                    ontap: () async {
                      var value = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TextEditorImage()));
                      if (value == null || value['name'] == null) {
                        print('true');
                      } else {
                        type.add(2);
                        widgetJson.add(value);
                        // fontsize.add(20);
                        offsets.add(Offset.zero);
                        //  colorList.add(value['color']);
                        //    multiwidget.add(value['name']);
                        howmuchwidgetis++;
                      }
                    },
                    title: 'Text',
                  ),
                  BottomBarContainer(
                    colors: widget.bottomBarColor,
                    icons: Icons.flip,
                    ontap: () {
                      setState(() {
                        flipValue = flipValue == 0 ? math.pi : 0;
                      });
                    },
                    title: 'Flip',
                  ),
                  BottomBarContainer(
                    colors: widget.bottomBarColor,
                    icons: Icons.rotate_left,
                    ontap: () {
                      setState(() {
                        rotateValue--;
                      });
                    },
                    title: 'Rotate left',
                  ),
                  BottomBarContainer(
                    colors: widget.bottomBarColor,
                    icons: Icons.rotate_right,
                    ontap: () {
                      setState(() {
                        rotateValue++;
                      });
                    },
                    title: 'Rotate right',
                  ),
                  BottomBarContainer(
                    colors: widget.bottomBarColor,
                    icons: Icons.blur_on,
                    ontap: () {
                      showModalBottomSheet(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            topLeft: Radius.circular(10),
                          ),
                        ),
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setS) {
                              return Container(
                                padding: EdgeInsets.all(20),
                                height: 400,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      topLeft: Radius.circular(10)),
                                ),
                                child: Column(
                                  children: [
                                    Center(
                                      child: Text(
                                        'Slider Filter Color'.toUpperCase(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Divider(

                                        // height: 1,
                                        ),
                                    const SizedBox(
                                      height: 20.0,
                                    ),
                                    Text(
                                      'Slider Color'.toUpperCase(),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: BarColorPicker(
                                              width: 300,
                                              thumbColor: Colors.white,
                                              cornerRadius: 10,
                                              pickMode: PickMode.Color,
                                              colorListener: (int value) {
                                                setS(() {
                                                  setState(() {
                                                    colorValue = Color(value);
                                                  });
                                                });
                                              }),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              setS(() {
                                                colorValue = Colors.transparent;
                                              });
                                            });
                                          },
                                          child: Text(
                                            'Reset',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 5.0,
                                    ),
                                    Text(
                                      'Slider Blur'.toUpperCase(),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(
                                      height: 10.0,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Slider(
                                              activeColor: Colors.white,
                                              inactiveColor: Colors.grey,
                                              value: blurValue,
                                              min: 0.0,
                                              max: 10.0,
                                              onChanged: (v) {
                                                setS(() {
                                                  setState(() {
                                                    blurValue = v;
                                                  });
                                                });
                                              }),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setS(() {
                                              setState(() {
                                                blurValue = 0.0;
                                              });
                                            });
                                          },
                                          child: Text(
                                            'Reset'.toUpperCase(),
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 5.0,
                                    ),
                                    Text(
                                      'Slider Opacity',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(
                                      height: 10.0,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Slider(
                                              activeColor: Colors.white,
                                              inactiveColor: Colors.grey,
                                              value: opacityValue,
                                              min: 0.00,
                                              max: 1.0,
                                              onChanged: (v) {
                                                setS(() {
                                                  setState(() {
                                                    opacityValue = v;
                                                  });
                                                });
                                              }),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setS(() {
                                              setState(() {
                                                opacityValue = 0.0;
                                              });
                                            });
                                          },
                                          child: Text(
                                            'Reset'.toUpperCase(),
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    title: 'Blur',
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
                  BottomBarContainer(
                    colors: widget.bottomBarColor,
                    icons: Icons.photo,
                    ontap: () {
                      showModalBottomSheet(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              topLeft: Radius.circular(10),
                            ),
                          ),
                          context: context,
                          builder: (context) {
                            return Container(
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10),
                                    topLeft: Radius.circular(10)),
                                color: Colors.black87,
                              ),
                              child: StatefulBuilder(
                                builder: (context, setS) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        height: 5.0,
                                      ),
                                      Text(
                                        'Slider Hue'.toUpperCase(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(
                                        height: 10.0,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Slider(
                                                activeColor: Colors.white,
                                                inactiveColor: Colors.grey,
                                                value: hueValue,
                                                min: -10.0,
                                                max: 10.0,
                                                onChanged: (v) {
                                                  setS(() {
                                                    setState(() {
                                                      hueValue = v;
                                                    });
                                                  });
                                                }),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setS(() {
                                                setState(() {
                                                  blurValue = 0.0;
                                                });
                                              });
                                            },
                                            child: Text(
                                              'Reset',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 5.0,
                                      ),
                                      Text(
                                        'Slider Saturation',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(
                                        height: 10.0,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Slider(
                                                activeColor: Colors.white,
                                                inactiveColor: Colors.grey,
                                                value: saturationValue,
                                                min: -10.0,
                                                max: 10.0,
                                                onChanged: (v) {
                                                  setS(() {
                                                    setState(() {
                                                      saturationValue = v;
                                                    });
                                                  });
                                                }),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setS(() {
                                                setState(() {
                                                  saturationValue = 0.0;
                                                });
                                              });
                                            },
                                            child: Text(
                                              'Reset',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 5.0,
                                      ),
                                      Text(
                                        'Slider Brightness',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(
                                        height: 10.0,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Slider(
                                                activeColor: Colors.white,
                                                inactiveColor: Colors.grey,
                                                value: brightnessValue,
                                                min: 0.0,
                                                max: 1.0,
                                                onChanged: (v) {
                                                  setS(() {
                                                    setState(() {
                                                      brightnessValue = v;
                                                    });
                                                  });
                                                }),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setS(() {
                                                setState(() {
                                                  brightnessValue = 0.0;
                                                });
                                              });
                                            },
                                            child: Text(
                                              'Reset',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          });
                    },
                    title: 'Filter',
                  ),
                  BottomBarContainer(
                    colors: widget.bottomBarColor,
                    icons: FontAwesomeIcons.smile,
                    ontap: () {
                      var getemojis = showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return Emojies();
                          });
                      getemojis.then((value) {
                        if (value['name'] != null) {
                          type.add(1);
                          widgetJson.add(value);
                          //    fontsize.add(20);
                          offsets.add(Offset.zero);
                          //  multiwidget.add(value);
                          howmuchwidgetis++;
                        }
                      });
                    },
                    title: 'Emoji',
                  ),
                ],
              ),
            ),
      body: Center(
        child: Screenshot(
          controller: screenshotController,
          child: RotatedBox(
            quarterTurns: rotateValue,
            child: imageFilterLatest(
              hue: hueValue,
              brightness: brightnessValue,
              saturation: saturationValue,
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
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(flipValue),
                              child: ClipRect(
                                // <-- clips to the 200x200 [Container] below

                                child: Container(
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
                                              fit: BoxFit.fitHeight)),

                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: blurValue,
                                      sigmaY: blurValue,
                                    ),
                                    child: Container(
                                      color:
                                          colorValue.withOpacity(opacityValue),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                      Container(
                        padding: EdgeInsets.all(0.0),
                        child: GestureDetector(
                            onPanUpdate: (DragUpdateDetails details) {
                              setState(() {
                                var object =
                                    context.findRenderObject() as RenderBox?;
                                var _localPosition = object
                                    ?.globalToLocal(details.globalPosition);
                                _points = List.from(_points)
                                  ..add(_localPosition);
                              });
                            },
                            onPanEnd: (DragEndDetails details) {
                              _points.add(null);
                            },
                            child: Signat()),
                      ),
                      Stack(
                        children: widgetJson.asMap().entries.map((f) {
                          return type[f.key] == 1
                              ? EmojiView(
                                  left: offsets[f.key].dx,
                                  top: offsets[f.key].dy,
                                  ontap: () {
                                    scaf.currentState
                                        ?.showBottomSheet((context) {
                                      return Sliders(
                                        index: f.key,
                                        mapValue: f.value,
                                      );
                                    });
                                  },
                                  onpanupdate: (details) {
                                    setState(() {
                                      offsets[f.key] = Offset(
                                          offsets[f.key].dx + details.delta.dx,
                                          offsets[f.key].dy + details.delta.dy);
                                    });
                                  },
                                  mapJson: f.value,
                                )
                              : type[f.key] == 2
                                  ? TextView(
                                      left: offsets[f.key].dx,
                                      top: offsets[f.key].dy,
                                      ontap: () {
                                        showModalBottomSheet(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(10),
                                                topLeft: Radius.circular(10),
                                              ),
                                            ),
                                            context: context,
                                            builder: (context) {
                                              return Sliders(
                                                index: f.key,
                                                mapValue: f.value,
                                              );
                                            });
                                      },
                                      onpanupdate: (details) {
                                        setState(() {
                                          offsets[f.key] = Offset(
                                              offsets[f.key].dx +
                                                  details.delta.dx,
                                              offsets[f.key].dy +
                                                  details.delta.dy);
                                        });
                                      },
                                      mapJson: f.value,
                                    )
                                  : Container();
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final picker = ImagePicker();

  void bottomsheets() {
    openbottomsheet = true;
    setState(() {});
    var future = showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(0.0),
          color: Colors.white,
          height: 170,
          child: Column(
            children: [
              Center(
                child: Text('Select Image Options'),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Divider(
                height: 1,
              ),
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        print('Gallery tapped');
                        var image =
                            await picker.pickImage(source: ImageSource.gallery);

                        if (image != null) {
                          var decodedImage = await decodeImageFromList(
                              File(image.path).readAsBytesSync());

                          setState(() {
                            height = decodedImage.height;
                            width = decodedImage.width;
                            _image = File(image.path);
                          });
                          setState(() => _controller.clear());
                          Navigator.pop(context);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library),
                          const SizedBox(
                            height: 10.0,
                          ),
                          Text('Open Gallery'),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 24.0,
                    ),
                    GestureDetector(
                      onTap: () async {
                        var image =
                            await picker.pickImage(source: ImageSource.camera);
                        if (image != null) {
                          var decodedImage = await decodeImageFromList(
                              File(image.path).readAsBytesSync());

                          setState(() {
                            height = decodedImage.height;
                            width = decodedImage.width;
                            _image = File(image.path);
                          });
                          setState(() => _controller.clear());
                          Navigator.pop(context);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt),
                          const SizedBox(
                            width: 10.0,
                          ),
                          Text('Open Camera'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    future.then((void value) => _closeModal(value));
  }

  void _closeModal(void value) {
    openbottomsheet = false;
    setState(() {});
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
            backgroundColor: Colors.transparent),
      ],
    );
  }
}

Widget imageFilterLatest({brightness, saturation, hue, child}) {
  return ColorFiltered(
      colorFilter:
          ColorFilter.matrix(ColorFilterGenerator.brightnessAdjustMatrix(
        value: brightness,
      )),
      child: ColorFiltered(
          colorFilter:
              ColorFilter.matrix(ColorFilterGenerator.saturationAdjustMatrix(
            value: saturation,
          )),
          child: ColorFiltered(
            colorFilter:
                ColorFilter.matrix(ColorFilterGenerator.hueAdjustMatrix(
              value: hue,
            )),
            child: child,
          )));
}
