import 'package:flutter/material.dart';

class FoodOrderPage extends StatefulWidget {
  const FoodOrderPage({Key? key}) : super(key: key);

  @override
  _FoodOrderPageState createState() => _FoodOrderPageState();
}

class _FoodOrderPageState extends State<FoodOrderPage> {
  // This would be a list of food items available for order.
  // You would likely replace this with a call to a database or API to get the actual items.
  List<String> foodItems = ['Hot Dog', 'Burger', 'Pizza', 'Ice Cream'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Order'),
      ),
      body: ListView.builder(
        itemCount: foodItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(foodItems[index]),
            trailing: ElevatedButton(
              child: const Text('Order'),
              onPressed: () {
                // Handle order button press
                // You would likely navigate to a new page here where the user can finalize their order
              },
            ),
          );
        },
      ),
    );
  }
}
