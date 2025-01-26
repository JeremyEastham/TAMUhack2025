import 'dart:convert';
import 'dart:typed_data';

import 'package:aalandmarks/database/firestore.dart';
import 'package:aalandmarks/helper/helper_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class OnAnnotationClick extends OnPointAnnotationClickListener {
  PointAnnotationManager? pointAnnotationManager;
  OnAnnotationClick(this.pointAnnotationManager);
  final FirestoreDatabase database = FirestoreDatabase();

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    try {
      database.claimReward(getSubstringBeforeFirstDash(annotation.id));
    } catch (e, stacktrace) {
      print('failed to delete annotation ${annotation.id} from database');
    }

    pointAnnotationManager?.delete(annotation);
  }
}

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
  final FirestoreDatabase database = FirestoreDatabase();
  late Ticker _ticker;
  late ModelLayer modelLayer;
  late PointAnnotationManager pointAnnotationManager;
  late OnAnnotationClick onAnnotationClick;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    //setting up the map
    this.mapboxMap = mapboxMap;

    /// DEMO ONLY -- REMOVE IN PRODUCTION
    mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
    mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));
    /// DEMO ONLY -- REMOVE IN PRODUCTION


    mapboxMap.setBounds(CameraBoundsOptions(
      maxZoom: 17,
      minZoom: 16,
    ));
    mapboxMap.gestures.updateSettings(GesturesSettings(scrollEnabled: false));
    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    onAnnotationClick = OnAnnotationClick(pointAnnotationManager);
    pointAnnotationManager.addOnPointAnnotationClickListener(onAnnotationClick);

    // populate database annotations on the map
    final ByteData bytes =
        await rootBundle.load('assets/american-airlines.png');
    final Uint8List imageData = bytes.buffer.asUint8List();

    try {
      //get the coins from db
      final CollectionReference coins =
          FirebaseFirestore.instance.collection('coins');
      QuerySnapshot querySnapshot = await coins.get();

      // get the latitude and longitude from each annoatation
      for (var doc in querySnapshot.docs) {
        double latitude = doc.get('latitude');
        double longitude = doc.get('longitude');
        print('Latitude: $latitude, Longitude: $longitude');
        PointAnnotationOptions pao = PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(longitude,
                latitude), //make a point with the latitude and longitude
          ),
          image: imageData,
          iconSize: 0.2,
        );

        await pointAnnotationManager.create(pao); // put the point on the map
      }
    } catch (e, stacktrace) {
      print(
          'something went wrong retrieving coins locations from database $stacktrace');
    }
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
      mapboxMap!
          .setCamera(CameraOptions(center: Point(coordinates: _userPosition)));
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

  _onLongTap(MapContentGestureContext context) async {
    final ByteData bytes =
        await rootBundle.load('assets/american-airlines.png');
    final Uint8List imageData = bytes.buffer.asUint8List();
    PointAnnotationOptions pao = PointAnnotationOptions(
      geometry: context.point,
      image: imageData,
      iconSize: 0.2,
    );

    try {
      PointAnnotation pa =
          await pointAnnotationManager.create(pao); // put annotation on the map

      //create annoation in database
      String coinId = await database.spawnReward(
          pa.id,
          '',
          context.point.coordinates.lat as double,
          context.point.coordinates.lng as double);

      print('successfully created annotation');
    } catch (e, stacktrace) {
      print('something went wrong creating annotation in database $stacktrace');
    }

    print("Long tapped on the map at ${context.point.coordinates.lat}, "
        "${context.point.coordinates.lng}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
        backgroundColor: Colors.deepOrangeAccent,
        actions: [
          IconButton(
            onPressed: logout,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: MapWidget(
        onTapListener: (context) {
          _onTap(context);
        },
        onLongTapListener: (context) {
          _onLongTap(context);
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
