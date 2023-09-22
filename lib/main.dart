import 'dart:convert';
import 'dart:ffi';
import 'dart:io';


import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:http/http.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
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
            Text("dada"),
            MyCameraPage(),
            Icon(Icons.directions_bike),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home)),
              Tab(icon: Icon(Icons.camera_alt)),
              Tab(icon: Icon(Icons.info)),
            ],
          ),
        ),
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ImagePreview(pic)));
                        } on CameraException {
                          // debugPrintStack("Error occuped while taking picture: $e");
                          return;
                        }
                      },
                      child: const Icon(
                        Icons.panorama_fish_eye,
                        color: Colors.deepOrange,
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
        appBar: AppBar(title: const Text("Image Preview")),
        body: Center(
          child: Scaffold(
            body: Image.file(picture),
            floatingActionButton: MaterialButton(onPressed: (){

              Future<Data> data = createData(picture);
              Navigator.push(context, MaterialPageRoute(builder: (context) => HttpImage(data)));
            }
            , child: const Icon(Icons.navigate_next)),
          )
        ));
  }

  Future<Data> createData(File file) async {

    final uri = Uri.parse('http://foxworld.online:25596/main/upload');
    var request = MultipartRequest('POST', uri);
    request.files.add(await MultipartFile.fromPath('file', file.path));
    Response response = await Response.fromStream(await request.send());
    return Data.fromJson(jsonDecode(response.body));
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

  Data({required this.code, required this.weight,required this.height,required this.material,required this.creator,required this.title,required this.image,required this.about});
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


class _HttpImageState extends State<HttpImage> {

  late Future<Data> dated;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    this.dated = widget.data;
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        body: Center(
        child:FutureBuilder<Data>(
          future: dated, builder:(context, snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data!.code);
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          return const CircularProgressIndicator();
        },
      ),
      ));
    }
  }
