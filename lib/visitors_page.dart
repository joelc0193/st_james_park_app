import 'package:flutter/material.dart';

class VisitorsPage extends StatelessWidget {
  // Sample data
  static const visitors = [
    {
      'name': 'John Doe',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'Jane Smith',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'Robert Johnson',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'Emily Davis',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'Michael Brown',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'Sarah Miller',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'James Wilson',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'Jessica Moore',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'William Taylor',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'Emma Anderson',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'David Thomas',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
    {
      'name': 'Sophia Jackson',
      'imageUrl':
          'https://firebasestorage.googleapis.com/v0/b/st-james-park-89a2b.appspot.com/o/user_images%2FL1qrAkeLKZQlRI7JW2lV8kVw8GD3.jpg?alt=media&token=838a8397-e2ea-435a-93e7-133248873e95'
    },
  ];

  const VisitorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: visitors.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(visitors[index]['imageUrl']!),
          ),
          title: Text(visitors[index]['name']!),
        );
      },
    );
  }
}
