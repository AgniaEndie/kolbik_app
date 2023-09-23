import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: "Home"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        body: TabBarView(
          children: [
            MyCameraPage(),
            InfoPage(),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.camera_alt)),
              Tab(icon: Icon(Icons.info)),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        verticalDirection: VerticalDirection.down,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.accessibility_new, color: Colors.deepOrangeAccent),
                    Container(
                      child: Center(
                        child:Column(
                          children: [
                            Text("KolbikApp" , style: TextStyle(fontSize: 20.0),),
                            Text("Kolbik App - мобильное приложение, созданное для распознавания деталей по фото", style: TextStyle(fontSize: 20.0),textAlign: TextAlign.center, textWidthBasis: TextWidthBasis.parent),
                            Text("FoxStudios - 2023", style: TextStyle(fontSize: 20.0),)
                          ],
                        )
                      ),
                    ),

                  ],
                )

              )
          ),
        ],
      ),
    );
  }
}

class MyCameraPage extends StatefulWidget {
  const MyCameraPage({super.key});

  @override
  State<MyCameraPage> createState() => _MyCameraPageState();
}

class _MyCameraPageState extends State<MyCameraPage> {
  late CameraController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case "CameraAccessDenied":
            break;
          default:
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            child: CameraPreview(_controller),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                    margin: const EdgeInsets.all(20.0),
                    child: MaterialButton(
                      onPressed: () async {
                        if (!_controller.value.isInitialized) {
                          return;
                        }
                        if (_controller.value.isTakingPicture) {
                          return;
                        }

                        try {
                          await _controller.setFlashMode(FlashMode.auto);
                          XFile pic = await _controller.takePicture();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ImagePreview(pic)));
                        } on CameraException {
                          // debugPrintStack("Error occuped while taking picture: $e");
                          return;
                        }
                      },
                      child: const Icon(
                        Icons.panorama_fish_eye,
                        color: Colors.deepOrangeAccent,
                        fill: 1.0,
                      ),
                    )),
              )
            ],
          )
        ],
      ),
    );
  }
}

class ImagePreview extends StatefulWidget {
  ImagePreview(this.file, {super.key});

  XFile file;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  @override
  Widget build(BuildContext context) {
    File picture = File(widget.file.path);
    return Scaffold(
        appBar: AppBar(title: const Text("Предпросмотр изображения")),
        body: Center(
            child: Scaffold(
          body: Image.file(picture),
          floatingActionButton: MaterialButton(
              onPressed: () {
                Future<Data> data = createData(picture);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HttpImage(data)));
              },
              child: const Icon(Icons.navigate_next, color: Colors.deepOrangeAccent,)),
        )));
  }

  Future<Data> createData(File file) async {
    final uri = Uri.parse('http://foxworld.online:25596/main/upload');
    //final uri = Uri.parse('http://127.0.0.1:25585/main/upload');
    var request = MultipartRequest('POST', uri);
    request.files.add(await MultipartFile.fromPath('file', file.path));
    Response response = await Response.fromStream(await request.send());
    return Data.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }
}

class Data {
  String code;
  int weight;
  int height;
  String material;
  String creator;
  String title;
  String image;
  String about;

  Data(
      {required this.code,
      required this.weight,
      required this.height,
      required this.material,
      required this.creator,
      required this.title,
      required this.image,
      required this.about});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      code: json['code'],
      weight: json['weight'],
      height: json['height'],
      material: json['material'],
      creator: json['creator'],
      title: json['title'],
      image: json['image'],
      about: json['about'],
    );
  }
}

class HttpImage extends StatefulWidget {
  HttpImage(this.data, {super.key});

  late Future<Data> data;

  @override
  State<HttpImage> createState() => _HttpImageState();
}

Future<File> getImage(String code) async {
  final uri = Uri.parse('http://foxworld.online:25596/main/getImage/$code');
  final response = await get(uri, headers: {});
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;
  File file = File('$tempPath/$code.png');
  await file.writeAsBytes(response.bodyBytes);
  return file;
}

class _HttpImageState extends State<HttpImage> {
  late Future<Data> dated;
  late Future<File> image;
  late String code;
  late int isModel;

  @override
  void initState() {
    super.initState();
    dated = widget.data;
    code = "";
    dated.then((value) {
      if (value.image != "1") {
        isModel = 1;
      } else {
        isModel = 0;
        code = value.code;
        image = getImage(value.code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("О Детали")),
      body: FutureBuilder<Data>(
        future: dated,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
                body: Column(
              children: [
                Container(
                  child: FutureBuilder<File>(
                      future: image,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && isModel == 1) {
                          return Image.file(File(snapshot.requireData.path),height:300.0, width: 300.0,);
                        } else if (snapshot.hasData && isModel == 0) {
                          return Image.file(File(snapshot.requireData.path),height:300.0, width: 300.0,);
                        } else {
                          return const Text("not");
                        }
                      }),
                ),
                Container(
                    child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    const TableRow(
                        decoration: BoxDecoration(color: Colors.deepOrangeAccent),
                        children: [
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Наименование",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Описание",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        ]),
                    TableRow(
                        decoration: const BoxDecoration(color: Colors.white54),
                        children: [
                          const TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Наименование детали"),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(snapshot.hasData
                                  ? snapshot.requireData.title
                                  : "загрузка"),
                            ),
                          )
                        ]),
                    TableRow(
                        decoration: const BoxDecoration(color: Colors.white54),
                        children: [
                          const TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Краткое описание"),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(snapshot.hasData
                                  ? snapshot.requireData.about
                                  : "загрузка"),
                            ),
                          )
                        ]),
                    TableRow(
                        decoration: const BoxDecoration(color: Colors.white54),
                        children: [
                          const TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Вес"),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(snapshot.hasData
                                  ? snapshot.requireData.weight.toString()
                                  : "загрузка"),
                            ),
                          )
                        ]),
                    TableRow(
                        decoration: const BoxDecoration(color: Colors.white54),
                        children: [
                          const TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Высота"),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(snapshot.hasData
                                  ? snapshot.requireData.height.toString()
                                  : "загрузка"),
                            ),
                          )
                        ]),
                    TableRow(
                        decoration: const BoxDecoration(color: Colors.white54),
                        children: [
                          const TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Материал"),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(snapshot.hasData
                                  ? snapshot.requireData.material
                                  : "загрузка"),
                            ),
                          )
                        ]),
                    TableRow(
                        decoration: const BoxDecoration(color: Colors.white54),
                        children: [
                          const TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Производитель"),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(snapshot.hasData
                                  ? snapshot.requireData.creator
                                  : "загрузка"),
                            ),
                          )
                        ]),
                  ],
                )),
                Container(
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MyHomePage(title: "da")));
                    },
                    backgroundColor: Colors.deepOrangeAccent,
                    label: Text("На главную",
                        style: TextStyle(color: Colors.white)),
                    icon: Icon(Icons.home, color: Colors.white),
                  ),
                )
              ],
            ));
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
