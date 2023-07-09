import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../utils/timer_util.dart';

class MapWidget extends StatefulWidget {
  final User user;
  final MessageService messageService;

  MapWidget({@required this.user, @required this.messageService});

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    widget.messageService.messageStream.listen((message) {
      if (message.userId == widget.user.id) {
        _addMessageMarker(message);
        TimerUtil.startTimer(duration: Duration(seconds: 10), onDone: () {
          _removeMessageMarker(message.id);
        });
      }
    });
  }

  void _addMessageMarker(Message message) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(message.id),
          position: LatLng(widget.user.latitude, widget.user.longitude),
          infoWindow: InfoWindow(title: message.content),
        ),
      );
    });
  }

  void _removeMessageMarker(String messageId) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == messageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
      },
      markers: _markers,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.user.latitude, widget.user.longitude),
        zoom: 14.4746,
      ),
    );
  }
}