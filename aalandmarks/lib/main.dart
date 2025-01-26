import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;
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

  var position = Position(-96.34266987969741, 30.613339432347736); // Position(24.9458, 60.17180);
  var modelPosition = Position(-96.34266987969741, 30.613339432347736); // Position(24.94457012371287, 60.171958417023674);

  @override
  Widget build(BuildContext context) {
    return MapWidget(
        styleUri: MapboxStyles.OUTDOORS,
        cameraOptions: CameraOptions(
            center: Point(coordinates: position),
            zoom: 18.5,
            bearing: 90,
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
    // PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
    //   geometry: Point(coordinates: modelPosition),
    //   image: imageData,
    //   iconSize: 0.25,
    // );

    // Add the annotation to the map
    // pointAnnotationManager?.create(pointAnnotationOptions);
    // Add more points in a grid pattern
    // for (var i = -3; i <= 3; i++) {
    //   for (var j = -3; j <= 3; j++) {
    //     var offset = Position(
    //       modelPosition.lng + (i * 0.0001), 
    //       modelPosition.lat + (j * 0.0001)
    //     );
    //     pointAnnotationManager?.create(
    //       PointAnnotationOptions(
    //         geometry: Point(coordinates: offset),
    //         image: imageData,
    //         iconSize: 0.25,
    //       )
    //     );
    //   }
    // }
    // Query nearby points of interest from Mapbox Tilequery API
    final response = await http.get(Uri.parse(
      'https://api.mapbox.com/v4/mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2/tilequery/'
      '${modelPosition.lng},${modelPosition.lat}.json'
      '?access_token=${await MapboxOptions.getAccessToken()}'
      '&radius=1000000'
      '&limit=50'
      '&geometry=point'
    ));

    print(response.statusCode);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      for (var feature in data['features']) {
        final coordinates = feature['geometry']['coordinates'];
        pointAnnotationManager?.create(
          PointAnnotationOptions(
          geometry: Point(coordinates: Position(coordinates[0], coordinates[1])),
          image: imageData,
          iconSize: 0.25,
          textField: feature['properties']['type']
          )
        );
      }
    }
    addModelLayer();
  }

  addModelLayer() async {
    var value = Point(coordinates: modelPosition);
    if (mapboxMap == null) {
      throw Exception("MapboxMap is not ready yet");
    }

    final airplaneModelId = "model-airplane-id";
    final airplaneModelUri = "asset://assets/low_poly_plane.gltf";
    await mapboxMap?.style.addStyleModel(airplaneModelId, airplaneModelUri);

    await mapboxMap?.style
        .addSource(GeoJsonSource(id: "sourceId", data: json.encode(value)));

    var modelLayer = ModelLayer(id: "modelLayer-airplane", sourceId: "sourceId");
    modelLayer.modelId = airplaneModelId;
    modelLayer.modelScale = [1.0, 1.0, 1.0];
    modelLayer.modelRotation = [0, 0, 90];
    modelLayer.modelType = ModelType.COMMON_3D;
    await mapboxMap?.style.addLayer(modelLayer);
  }
}