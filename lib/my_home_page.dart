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
      return 'Last Update: ${timeDifference.inMinutes} minutes ago';
    } else if (timeDifference.inHours < 2) {
      return 'Last Update: ${timeDifference.inHours} hours and ${timeDifference.inMinutes % 60} minutes ago';
    } else {
      return 'Last Update: ${timeDifference.inHours} hours ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('St James Park Count'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminPage()),
              );
            },
          ),
        ],
      ),
      body: Column(children: [
        StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getAdminNumbers(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
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
              int sum = 0;
              data.values.forEach((value) {
                value is String ? sum += int.parse(value) : sum = sum;
              });
              Duration timeDifference =
                  calculateTimeDifference(data['Last Update']);
              return Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Text(
                            '$sum',
                            style: TextStyle(
                              fontSize: 75,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
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
                      child: ListView(
                        children: [
                          ...orderedKeys.map((key) {
                            print(key);
                            return ListTile(
                              title: Text(key),
                              trailing: Text('${data[key]}', key: Key(key)),
                            );
                          }).toList(),
                          Center(
                            child: Text(
                              formatTimeDifference(timeDifference),
                              style: TextStyle(fontSize: 17),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Text('No data');
            }
          },
        ),
        StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getNumber(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            return CountWidget(snapshot);
          },
        ),
      ]),
    );
  }
}

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
