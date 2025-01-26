import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken('pk.eyJ1IjoicmFhZmF5NTkiLCJhIjoiY202Y250dG40MGFldjJxcG40cDVrYWh0cSJ9.FoXcn72rQkMAnuueczZUXQ');
  runApp(MaterialApp(home: MapsDemo()));
}

class MapsDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModelLayerExample();
  }
}

abstract interface class Example extends Widget {
  Widget get leading;
  String get title;
  String? get subtitle;
}

class ModelLayerExample extends StatefulWidget implements Example {
  @override
  final Widget leading = const Icon(Icons.view_in_ar);
  @override
  final String title = 'Display a 3D model in a model layer';
  @override
  final String subtitle = 'Showcase the usage of a 3D model layer.';

  @override
  State<StatefulWidget> createState() => _ModelLayerExampleState();
}

class _ModelLayerExampleState extends State<ModelLayerExample> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  var position = Position(24.9458, 60.17180);
  var modelPosition = Position(24.94457012371287, 60.171958417023674);

  @override
  Widget build(BuildContext context) {
    return MapWidget(
        cameraOptions: CameraOptions(
            center: Point(coordinates: modelPosition),
            zoom: 18,
            bearing: 0,
            pitch: 80),
        key: const ValueKey<String>('mapWidget'),
        onMapCreated: _onMapCreated,
        onStyleLoadedListener: _onStyleLoaded);
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
  }

  _onStyleLoaded(StyleLoadedEventData data) async {

    // Load the image from assets
    final ByteData bytes =
        await rootBundle.load('assets/aa_coin.png');
    final Uint8List imageData = bytes.buffer.asUint8List();

    // Create a PointAnnotationOptions
    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(coordinates: modelPosition),
      image: imageData,
      iconSize: 1.0
    );

    // Add the annotation to the map
    // pointAnnotationManager?.create(pointAnnotationOptions);

    addModelLayer();
  }

  addModelLayer() async {
    var value = Point(coordinates: modelPosition);
    if (mapboxMap == null) {
      throw Exception("MapboxMap is not ready yet");
    }

    final airplaneModelId = "model-airplane-id";
    final airplaneModelUri = "asset://assets/airplane.glb";
    await mapboxMap?.style.addStyleModel(airplaneModelId, airplaneModelUri);

    await mapboxMap?.style
        .addSource(GeoJsonSource(id: "sourceId", data: json.encode(value)));

    var modelLayer = ModelLayer(id: "modelLayer-airplane", sourceId: "sourceId");
    modelLayer.modelId = airplaneModelId;
    modelLayer.modelScale = [1.0, 1.0, 1.0];
    modelLayer.modelRotation = [0, 0, 90];
    modelLayer.modelType = ModelType.COMMON_3D;
    mapboxMap?.style.addLayer(modelLayer);
  }
}