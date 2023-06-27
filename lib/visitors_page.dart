import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:provider/provider.dart';

import 'other_user_profile_page.dart';
import 'services/app_bar_manager.dart';

class VisitorsPage extends StatefulWidget {
  final Function(int, String) onLocationIconClicked;

  const VisitorsPage({Key? key, required this.onLocationIconClicked})
      : super(key: key);

  @override
  State<VisitorsPage> createState() => _VisitorsPageState();
}

class _VisitorsPageState extends State<VisitorsPage> {
  late final FirestoreService firestoreService;

  @override
  void initState() {
    super.initState();
    firestoreService = Provider.of<FirestoreService>(context, listen: false);
  }

  List<dynamic> _getVisitors(QuerySnapshot? snapshot) {
    return snapshot?.docs.map((doc) => doc.data()).toList() ?? [];
  }

  void _navigateToProfile(BuildContext context, String userId) {
    final appBarManager = Provider.of<AppBarManager>(context, listen: false);
    appBarManager.show();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => OtherUserProfilePage(userId: userId),
      ),
    )
        .then((_) {
      // Hide the back button when the user navigates back
      appBarManager.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestoreService.getUsersInPark(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final visitors = _getVisitors(snapshot.data);
          return ListView.builder(
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final doc = visitors[index];
              final userId = snapshot.data!.docs[index].id;
              return ListTile(
                onTap: () {
                  _navigateToProfile(context, userId);
                },
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(doc['image_url']),
                ),
                title: Text(doc['name']),
                subtitle: Text(doc['user_message']),
                trailing: IconButton(
                  icon: Icon(
                    Icons.location_on,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    widget.onLocationIconClicked(
                      2,
                      userId,
                    );
                  },
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return CircularProgressIndicator();
      },
    );
  }
}
