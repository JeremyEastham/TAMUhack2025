import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/scheduler.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  MapboxMap? mapboxMap;
  Position _userPosition = Position(-96.33909152611203, 30.609);
  late Ticker _ticker;
  late ModelLayer modelLayer;

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

  _move() {
    setState(() {
      //move the model and camera
      _userPosition =
          Position(_userPosition.lng + 0.00001, _userPosition.lat + 0.00001);
      mapboxMap!.setCamera(
          CameraOptions(center: Point(coordinates: _userPosition), zoom: 16));
      mapboxMap!.style.setStyleSourceProperty(
          "sourceId", "data", json.encode(Point(coordinates: _userPosition)));
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
    mapboxMap?.style.addLayer(modelLayer);
    mapboxMap?.setCamera(CameraOptions(center: value, zoom: 16));
    _ticker = Ticker((Duration elapsed) {
      _move();
    });
    _ticker.start();
  }

  _onTap(MapContentGestureContext context) {
    print("Tapped on the map at ${context.point.coordinates.lat}, "
        "${context.point.coordinates.lng}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: MapWidget(
        onTapListener: (context) {
          _onTap(context);
        },
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
