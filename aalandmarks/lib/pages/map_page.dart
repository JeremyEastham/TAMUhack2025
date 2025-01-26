import 'dart:async';
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
import 'package:quickalert/quickalert.dart';
import 'package:aalandmarks/components/invisibility.dart';

class OnAnnotationClick extends OnPointAnnotationClickListener {
  VoidCallback updatePoints;
  PointAnnotationManager? pointAnnotationManager;
  BuildContext context;
  OnAnnotationClick(this.pointAnnotationManager,
      {required this.updatePoints, required this.context});
  final FirestoreDatabase database = FirestoreDatabase();

  @override
  void onPointAnnotationClick(PointAnnotation annotation) async {
    try {
      String message = await database.getMessage(annotation.id);
      if (await database.getCoinEmail(getSubstringBeforeFirstDash(annotation.id)) ==
          database.getAppUserEmail()) {
        print("claimed own reward");
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: "You can't claim your own reward",
          text: "Try being more social",
          textColor: Theme.of(context) == ThemeData.dark()
              ? (Colors.grey[300] ?? Colors.white)
              : (Colors.grey[800] ?? Colors.black),
          confirmBtnText: "Ok",
          onConfirmBtnTap: () {
            Navigator.pop(context);
          },
        );
        return;
      }
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: "You got a reward!",
        text: message == '' ? 'No message' : '"$message"',
        textColor: Theme.of(context) == ThemeData.dark()
            ? (Colors.grey[300] ?? Colors.white)
            : (Colors.grey[800] ?? Colors.black),
        confirmBtnText: "Claim",
        onConfirmBtnTap: () {
          print('claim 1: ${getSubstringBeforeFirstDash(annotation.id)}');
          print(
              'claim 2: ${FirestoreDatabase.idConnectionsMap[annotation.id]}');
          database.claimReward(getSubstringBeforeFirstDash(annotation.id));
          database
              .claimReward(FirestoreDatabase.idConnectionsMap[annotation.id]!);
          FirestoreDatabase.idConnectionsMap.remove(annotation.id);
          updatePoints();
          Navigator.pop(context);
        },
      );
    } catch (e, stacktrace) {
      print('failed to delete annotation ${annotation.id} from database');
    }

    try {
      pointAnnotationManager?.delete(annotation);
    } catch (e, stacktrace) {
      print('error happened trying to delete annotation');
    }
  }
}

// class Timer extends StatefulWidget {
//   const Timer({super.key, required this.width});
//   final double width;

//   @override
//   State<Timer> createState() => _TimerState();
// }

// class _TimerState extends State<Timer> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   final double _cooldown = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 1),
//       vsync: this,
//     )..forward();

//     _animation = Tween(begin: 0.0, end: _cooldown)
//         .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   void animateTimer() {
//     _controller.reset();
//     _animation = Tween(begin: 0.0, end: _cooldown)
//         .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
//     _controller.forward();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(animation: _controller, builder: (context, _){
//       return SizedBox(
//         width: widget.width,
//         height: widget.width,
//         child: LinearProgressIndicator(
//           value: _animation.value,
//           backgroundColor: Colors.grey[300],
//           valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[800] ?? Colors.black),
//         ),
//       )
//     });
//   }
// }

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
  late StreamSubscription<QuerySnapshot> databaseSubscrition;
  late Ticker _ticker;
  late ModelLayer modelLayer;
  late PointAnnotationManager pointAnnotationManager;
  late OnAnnotationClick onAnnotationClick;
  bool isLoading = false;
  double secondsRemaining = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  int _remainingRewards = 30;
  double cooldownTime = 5;
  int? userPoints;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPoints();
    _controller = AnimationController(
      duration: Duration(seconds: cooldownTime.toInt()),
      vsync: this,
    )..forward();

    _animation = Tween(begin: cooldownTime, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  void decreaseRewards() {
    setState(() {
      _remainingRewards--;
    });
  }

  void getPoints() {
    database.getAppUserPts().then((value) {
      setState(() {
        userPoints = value;
      });
    });
  }

  void animateGauge() {
    _controller.reset();
    _animation = Tween(begin: cooldownTime, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.forward();
  }

  final Map<String, PointAnnotation> annotationsMap = {};

  @override
  void dispose() {
    stopUpdateListener();
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  void startLoading() {
    setState(() {
      decreaseRewards();
      isLoading = true;
      secondsRemaining = cooldownTime;
      animateGauge();
    });
  }

  // listen to annotation updates real-time in the db
  void startUpdateListener() {
    print('Started listening to database updates');
    final collectionRef = FirebaseFirestore.instance.collection('coins');

    databaseSubscrition = collectionRef.snapshots().listen((querySnapshot) {
      for (var change in querySnapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) {
          print('query data was null');
          return;
        }

        final documentId = change.doc.id;
        final latitude = data['latitude'];
        final longitude = data['longitude'];
        final userEmail = data['user-email'];

        // the current user is the one who updated the information so ignore the change
        if (userEmail == database.getAppUserEmail()) {
          return;
        }

        if (change.type == DocumentChangeType.added) {
          createAnnotationOnMap(longitude, latitude, existingId: documentId);
          print('New document add detected');
        } else if (change.type == DocumentChangeType.modified) {
          print('Document modified. No action needed');
        } else if (change.type == DocumentChangeType.removed) {
          if (annotationsMap[documentId] != null) {
            // the annoation is on the map (as stored in our local map of them)
            pointAnnotationManager.delete(annotationsMap[documentId]!);
            annotationsMap.remove(documentId);
            // database.idConnectionsMap.remove(documentId);
            print('Document remove successfully handled');
          }
        }
      }
    });
  }

  // end listener to annotation updates in db
  void stopUpdateListener() {
    databaseSubscrition.cancel();
    print('Stopped listening to db updates');
  }

  Future<String> createAnnotationOnMap(num longitude, num latitude,
      {String? existingId}) async {
    //load asset
    final ByteData bytes =
        await rootBundle.load('assets/american-airlines.png');
    final Uint8List imageData = bytes.buffer.asUint8List();

    //make a point with the latitude and longitude
    PointAnnotationOptions pao = PointAnnotationOptions(
      geometry: Point(
        coordinates: Position(longitude, latitude),
      ),
      image: imageData,
      iconSize: 0.2,
    );

    // put annotation on the map
    PointAnnotation pa = await pointAnnotationManager.create(pao);
    String annotationsEntry = existingId ?? pa.id;

    if (existingId != null) {
      FirestoreDatabase.idConnectionsMap[pa.id] =
          getSubstringBeforeFirstDash(annotationsEntry);
    }
    print('IDCONNECTIONSMAP: ');
    FirestoreDatabase.idConnectionsMap.forEach((key, value) {
      print('Key: $key, Value: $value');
    });
    print('');

    annotationsMap[getSubstringBeforeFirstDash(annotationsEntry)] =
        pa; // save a reference to the point annotation locally for possible deletion later

    return pa.id;
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    showDialog(
      context: this.context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    //setting up the map
    this.mapboxMap = mapboxMap;
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

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
    onAnnotationClick = OnAnnotationClick(pointAnnotationManager,
        updatePoints: getPoints, context: context);
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

        await createAnnotationOnMap(longitude, latitude, existingId: doc.id);
      }

      // all the annotations are on the map. Start listening to any changes to annotations in the database
      startUpdateListener();

      Navigator.pop(context);
    } catch (e, stacktrace) {
      Navigator.pop(context);
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

  // _onTap(MapContentGestureContext context) {
  //   print("Tapped on the map at ${context.point.coordinates.lat}, "
  //       "${context.point.coordinates.lng}");
  // }

  _onLongTap(MapContentGestureContext mapContext, BuildContext context) async {
    if (isLoading || _remainingRewards == 0) {
      return;
    }
    final ByteData bytes =
        await rootBundle.load('assets/american-airlines.png');
    final Uint8List imageData = bytes.buffer.asUint8List();
    PointAnnotationOptions pao = PointAnnotationOptions(
      geometry: mapContext.point,
      image: imageData,
      iconSize: 0.2,
    );
    String? message;
    QuickAlert.show(
      context: context,
      showCancelBtn: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      width: MediaQuery.of(context).size.width * 0.5,
      type: QuickAlertType.custom,
      barrierDismissible: false,
      confirmBtnText: "Post",
      cancelBtnText: "Cancel",
      widget: TextFormField(
        decoration: InputDecoration(
            hintText: "Enter optional message",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            fillColor: Color.fromARGB(255, 166, 166, 166),
            prefixIcon: Icon(Icons.edit)),
        autocorrect: true,
        onChanged: (value) => message = value,
      ),
      title: "Add a message to your reward",
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        try {
          print('i got here bro');
          PointAnnotation pa = await pointAnnotationManager
              .create(pao); // put annotation on the map
          print("Message is $message");
          //create annoation in database
          String coinId = await database.spawnReward(
              pa.id,
              message,
              mapContext.point.coordinates.lat as double,
              mapContext.point.coordinates.lng as double);

          print('successfully created annotation');
        } catch (e, stacktrace) {
          print(
              'something went wrong creating annotation in database $stacktrace');
        }
        startLoading();
      },
      onCancelBtnTap: () {
        Navigator.pop(context);
        return;
      },
    );

    print("ADDED ANNOTATION on the map at ${mapContext.point.coordinates.lat}, "
        "${mapContext.point.coordinates.lng}");
    // pointanimation jonathan = manager.create(pao(data))
    // manager.update(jonathan)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Stack(
          children: [
            Invisibility(
              visible: isLoading,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Theme.of(context).colorScheme.background,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: CircularProgressIndicator(
                        value: _animation.value / cooldownTime,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[800] ?? Colors.black),
                      ),
                    ),
                    Center(
                      child: Text(
                        _animation.value.toInt().toString(),
                        style: TextStyle(
                          color: Theme.of(context) == ThemeData.dark()
                              ? (Colors.grey[300] ?? Colors.white)
                              : (Colors.grey[800] ?? Colors.black),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Invisibility(
              visible: !isLoading,
              child: Center(
                  child: Text(
                "$_remainingRewards/3",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryFixedVariant,
                  fontSize: 20,
                ),
              )),
            )
          ],
        ),
        title: Text("Your Points: ${userPoints ?? 0}"),
        backgroundColor: Theme.of(context).colorScheme.background,
        actions: [
          IconButton(
            onPressed: logout,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: MapWidget(
        // onTapListener: (context) {
        //   _onTap(context);
        // },
        onLongTapListener: (mapContext) {
          _onLongTap(mapContext, context);
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
