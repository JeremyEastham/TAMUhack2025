import 'package:aalandmarks/helper/helper_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDatabase {
  User? user = FirebaseAuth.instance.currentUser;
  static final Map<String, String> idConnectionsMap = {};

  final int maxRewardValue = 200;
  final int minRewardvalue = 50;

  final CollectionReference coins =
      FirebaseFirestore.instance.collection('coins');

  Future<String> spawnReward(String id, String? message, double latitude, double longitude) async {
    print('spawnRecord got id: $id');
    try {
      await FirebaseFirestore.instance.collection('coins').doc(getSubstringBeforeFirstDash(id)).set({
        'user-email': user!.email,
        'msg': '',
        'value': getRandomInt(minRewardvalue, maxRewardValue),
        'timestamp': Timestamp.now(),
        'latitude': latitude,
        'longitude': longitude,
      });
      // DocumentReference coinRef = await coins.add({
      //   'user-email': user!.email,
      //   'msg': '',
      //   'value': getRandomInt(minRewardvalue, maxRewardValue),
      //   'timestamp': Timestamp.now(),
      //   'latitude': latitude,
      //   'longitude': longitude,
      // });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .update({
        'ownedPosts': FieldValue.arrayUnion([id]),
      });

      print('successfully spawned reward $id');
      return id;
    } catch (e, stacktrace) {
      print('something went wrong spawning reward ${stacktrace}');
      return 'invalid';
    }
  }

  Future<void> claimReward(String coinId) async {
    try {
      print('attempt to claim reward $coinId');
      final firestore = FirebaseFirestore.instance;
      DocumentReference coinDoc =
          firestore.collection('coins').doc(coinId); // get reward

      DocumentSnapshot coinSnapshot = await coinDoc.get();

      if (coinSnapshot.exists) {
        int value = coinSnapshot.get('value');

        DocumentReference userDoc =
            firestore.collection('users').doc(user!.email);

        // add reward to user
        await userDoc.update({
          'rewards': FieldValue.increment(value),
        });

        // remove reward
        await coinDoc.delete();

        print('Reward claimed successfully');
      } else {
        print('Post document with ID $coinId does not exist. ');
      }
    } catch (e, stacktrace) {
      print('something went wrong claiming reward $stacktrace');
    }
  }

  String getAppUserEmail() {
    return user!.email ?? '';

  }

  Stream<QuerySnapshot> getCoinsStream() {
    final coinsStream = FirebaseFirestore.instance
        .collection('coins')
        // .orderBy('timestamp', descending: true)
        .snapshots();

    return coinsStream;
  }


  Future<void> printAllCoinsLocation() async {
    try {
        final CollectionReference coins =
      FirebaseFirestore.instance.collection('coins');
      QuerySnapshot querySnapshot = await coins.get();
      for (var doc in querySnapshot.docs) {
        double latitude = doc.get('latitude');
        double longitude = doc.get('longitude');
        print('Latitude: $latitude, Longitude: $longitude');
      }
    } catch (e, stacktrace) {
      print('something went wrong retrieving coins locations $stacktrace');
    }
  }

}
