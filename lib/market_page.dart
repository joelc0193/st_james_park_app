import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/listing.dart';

class MarketPage extends StatelessWidget {
  final Function(int, String) onLocationIconClicked;

  const MarketPage({super.key, required this.onLocationIconClicked});

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
      ),
      body: StreamBuilder<List<Listing>>(
        stream: firestoreService.getServicesStream(),
        builder: (BuildContext context, AsyncSnapshot<List<Listing>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Listing service = snapshot.data![index];
                return ListTile(
                  leading: Image.network(service.imageUrl),
                  title: Text(service.type),
                  subtitle: Text(service.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${service.price.toStringAsFixed(2)}'),
                      IconButton(
                        icon: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                        ),
                        onPressed: () {
                          onLocationIconClicked(2, service.userId);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
