import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/user_data.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  static const routeName = 'other_user_profile_page';

  const OtherUserProfilePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  // Get the data for the other user
  UserData? otherUserData;
  late FirestoreService firestoreService;

  @override
  void initState() {
    super.initState();
    firestoreService = Provider.of<FirestoreService>(context, listen: false);
    getOtherUserData();
  }

  Future getOtherUserData() async {
    otherUserData = await firestoreService.getUserData(widget.userId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (otherUserData == null) {
      return const CircularProgressIndicator();
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${otherUserData!.name}!'),
            ),
            ClipOval(
              child: SizedBox(
                width: 150, // Set width
                height: 150, // Set height
                child: Image.network(
                  otherUserData!.imageUrl,
                  fit: BoxFit
                      .cover, // Use BoxFit.cover to maintain the aspect ratio
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(otherUserData!.message),
            ),
            // Add any other buttons or widgets you need here
          ],
        ),
      );
    }
  }
}
