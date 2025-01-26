import 'package:aalandmarks/helper/helper_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDatabase {
  User? user = FirebaseAuth.instance.currentUser;

  final int maxRewardValue = 500;
  final int minRewardvalue = 20;

  final CollectionReference coins =
      FirebaseFirestore.instance.collection('coins');

  Future<String> spawnReward(String message) async {
    try {
      DocumentReference coinRef = await coins.add({
        'user-email': user!.email,
        'msg': message,
        'value': getRandomInt(minRewardvalue, maxRewardValue),
        'timestamp': Timestamp.now(),
        'latitude': 0,
        'longitude': 0,
      });

      String coinId = coinRef.id;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .update({
        'ownedPosts': FieldValue.arrayUnion([coinId]),
      });

      print('successfully spawned reward $coinId');
      return coinId;
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

  Stream<QuerySnapshot> getCoinsStream() {
    final coinsStream = FirebaseFirestore.instance
        .collection('coins')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return coinsStream;
  }
}
