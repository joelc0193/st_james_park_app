import 'package:flutter/material.dart';

class VisitorsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace this with your actual data fetching logic
    final vendors = ['Vendor 1', 'Vendor 2', 'Vendor 3'];
    final people = ['Person 1', 'Person 2', 'Person 3'];

    return ListView(
      children: [
        ListTile(
          title: Text('Vendors'),
          subtitle: Text(vendors.join(', ')),
        ),
        ListTile(
          title: Text('People'),
          subtitle: Text(people.join(', ')),
        ),
      ],
    );
  }
}
