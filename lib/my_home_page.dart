import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/admin_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirestoreService _firestoreService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firestoreService = Provider.of<FirestoreService>(context);
  }

  Duration calculateTimeDifference(Timestamp lastUpdated) {
    return DateTime.now().difference(lastUpdated.toDate());
  }

  String formatTimeDifference(Duration timeDifference) {
    if (timeDifference.inMinutes < 60) {
      return '⌚ Updated ${timeDifference.inMinutes} minutes ago';
    } else if (timeDifference.inHours < 2) {
      return '⌚ Updated ${timeDifference.inHours} hours and ${timeDifference.inMinutes % 60} minutes ago';
    } else {
      return '⌚ Updated ${timeDifference.inHours} hours ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(
          title: const Text('St James Park People Counter'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPage()),
                );
              },
            ),
          ],
        ),
        body: Column(children: [
          Container(
            height: 200, // adjust the height as needed
            color: Colors.blue, // adjust the color as needed
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Featured Member',
                    style: TextStyle(color: Colors.white, fontSize: 24)),
                // add the image here
                // Image.network('url_of_the_image')
                Text('Some text about the featured member',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
              child: Column(children: [
            StreamBuilder<DocumentSnapshot>(
              stream: _firestoreService.getAdminNumbers(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  List<String> orderedKeys = [
                    'Basketball Courts',
                    'Tennis Courts',
                    'Soccer Field',
                    'Playground',
                    'Handball Courts',
                    'Other'
                  ];
                  List<String> emojis = ['🏀', '🎾', '⚽', '🛝', '🔵', '🌳'];
                  int sum = 0;
                  for (var key in orderedKeys) {
                    sum += data[key] as int;
                  }
                  return Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Text(
                                '$sum',
                                style: const TextStyle(
                                  fontSize: 75,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                key: const Key('Total'),
                              ),
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: kIsWeb
                              ? Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 600),
                                    child: _buildListView(
                                        orderedKeys, data, emojis),
                                  ),
                                )
                              : _buildListView(orderedKeys, data, emojis),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Text('No data');
                }
              },
            ),
          ]))
        ]));
  }

  Widget _buildListView(
    List<String> orderedKeys,
    Map<String, dynamic> data,
    List<String> emojis,
  ) {
    Duration timeDifference = calculateTimeDifference(data['Updated']);
    return ListView.separated(
      itemCount: orderedKeys.length + 1,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(color: Colors.white),
      itemBuilder: (context, index) {
        if (index < orderedKeys.length) {
          var key = orderedKeys[index];
          var emoji = emojis[index];
          return ListTile(
            title: Text('$emoji $key'),
            trailing: Text(
              '${data[key]}',
              key: Key(key),
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins'),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: Center(
              child: Text(
                formatTimeDifference(timeDifference),
                style: const TextStyle(fontSize: 17),
              ),
            ),
          );
        }
      },
    );
  }
}
