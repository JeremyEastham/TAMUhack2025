import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter/scheduler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(
      'sk.eyJ1IjoicmFhZmF5NTkiLCJhIjoiY202Y3JzbnVwMG54ODJ3cHNkdjR6Znd3bSJ9.aTq44U2zhOXaX37txUxbTQ');

  // Run your application, passing your CameraOptions to the MapWidget
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  MapboxMap? mapboxMap;
  Position _userPosition = Position(-96.33909152611203, 30.609);
  late Ticker _ticker;
  late ModelLayer modelLayer;
  Duration lastFrame = Duration.zero;
  double time = 0.0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    mapboxMap.setBounds(CameraBoundsOptions(
      maxZoom: 17,
      minZoom: 16,
    ));
    mapboxMap.gestures.updateSettings(GesturesSettings(scrollEnabled: false));
  }

  _setZoom(double zoom) {
    setState(() {
      mapboxMap!.setCamera(CameraOptions(zoom: zoom));
    });
  }

  _move(Duration deltaTime) {
    setState(() {
      //move the model and camera
      time += deltaTime.inMilliseconds / 1000;
      _userPosition =
          Position(_userPosition.lng + 0.00001 * deltaTime.inMilliseconds / 30, _userPosition.lat + 0.00001 * deltaTime.inMilliseconds / 30);
      mapboxMap!.setCamera(
          CameraOptions(center: Point(coordinates: _userPosition), zoom: 10));
      mapboxMap!.style.setStyleSourceProperty(
          "sourceId", "data", json.encode(Point(coordinates: _userPosition)));
      modelLayer.modelRotation![1] = sin(time) * 15;
      mapboxMap?.style.updateLayer(modelLayer);
    });
  }

  addModelLayer() async {
    var value = Point(coordinates: _userPosition);

    if (mapboxMap == null) {
      throw Exception("MapboxMap is not ready yet");
    }

    final buggyModelId = "model-test-id";
    final buggyModelUri =
        "https://raw.githubusercontent.com/Ysurac/FlightAirMap-3dmodels/master/a320/glTF2/A318.glb";
    await mapboxMap?.style.addStyleModel(buggyModelId, buggyModelUri);
    await mapboxMap?.style
        .addSource(GeoJsonSource(id: "sourceId", data: json.encode(value)));

    modelLayer = ModelLayer(id: "modelLayer-buggy", sourceId: "sourceId");
    modelLayer.modelId = buggyModelId;
    modelLayer.modelScale = [0.15, 0.15, 0.15];
    modelLayer.modelRotation = [0, 0, 225];
    modelLayer.modelTranslation = [0, 0, 50];
    modelLayer.modelType = ModelType.COMMON_3D;
    modelLayer.modelScale = [5, 5, 5];
    modelLayer.modelCastShadows = false;
    mapboxMap?.style.addLayer(modelLayer);
    mapboxMap?.setCamera(CameraOptions(center: value, zoom: 10));
    _ticker = Ticker((Duration elapsed) {
      Duration deltaTime = elapsed - lastFrame;
      lastFrame = elapsed;
      _move(deltaTime);
    });
    _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: MapWidget(
        onMapCreated: _onMapCreated,
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: _userPosition,
          ),
          zoom: 15,
          anchor: ScreenCoordinate(
              x: MediaQuery.of(context).size.width / 2,
              y: MediaQuery.of(context).size.height / 2),
          pitch: 75.0,
        ),
        onStyleLoadedListener: (styleLoadedEventData) async {
          addModelLayer();
        },
      ),
    );
  }
}
