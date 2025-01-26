import 'package:aalandmarks/components/reward_button.dart';
import 'package:aalandmarks/database/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final FirestoreDatabase database = FirestoreDatabase();
  String coinId = '';

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  void postReward() async {
    coinId = await database.spawnReward("Hi");
  }

  void claimReward() {
    database.claimReward(coinId);
  }

  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.email)
        .get();
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
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: RewardButton(iconData: Icons.done, onTap: postReward),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: RewardButton(iconData: Icons.error, onTap: claimReward),
              )
            ],
          ),
        ));
  }
}



// FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//         future: getUserDetails(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Text("Error: ${snapshot.error}");
//           } else if (snapshot.hasData) {
//             Map<String, dynamic>? user = snapshot.data!.data();

//             return Center(
//               child: Column(
//                 children: [
//                   Text(user!['email']),
//                   Text(user!['username']),
//                 ],
//               ),
//             );
//           } else {
//             return Text("No data");
//           }
//         },
//       ),