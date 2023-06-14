
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CountWidget extends StatelessWidget {
  final snapshot;
  CountWidget(
    AsyncSnapshot<DocumentSnapshot<Object?>> this.snapshot, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return const Text('Something went wrong', key: Key('numberText'));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text("Loading", key: Key('numberText'));
    }
    if (snapshot.connectionState == ConnectionState.active) {
      if (snapshot.data!.exists) {
        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;
        return Text("${data['currentNumber']}", key: Key('numberText'));
      } else {
        return Text('Document does not exist', key: Key('numberText'));
      }
    }
    return Text('$snapshot', key: Key('numberText'));
  }
}
