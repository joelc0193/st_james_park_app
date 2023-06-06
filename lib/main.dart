import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'St James Park App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _number = 0;

  @override
  void initState() {
    super.initState();
    _loadNumber();
  }

  void _loadNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _number = (prefs.getInt('number') ?? 0);
    });
  }

  void _incrementNumber() {
    setState(() {
      _number++;
    });
    _saveNumber();
  }

  void _updateNumber() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminPage()),
    );
    if (result != null) {
      setState(() {
        _number = result;
      });
      _saveNumber();
    }
  }

  void _saveNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('number', _number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('St James Park App'),
      ),
      body: Center(
        child: Text(
          'The number is: $_number',
          style: TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: _incrementNumber,
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _updateNumber,
            tooltip: 'Update',
            child: Icon(Icons.update),
          ),
        ],
      ),
    );
  }
}
