import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:window_size/window_size.dart';

void main() {
  // if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  //   setWindowTitle('API Stress-Tester');
  //   setWindowMinSize(const Size(990, 700));
  //   setWindowMaxSize(Size.infinite);
  // }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Stress-Tester',
      theme: ThemeData.dark(),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Timer _timer;
  String _url = "";
  late Uri _uri;
  String _body = "";
  String _contentType = "application/json";
  String _userAgent = "APIStressTest/v1.0.0";
  bool _isRunning = false;
  int _time = 200;
  final List<String> _timeType = ['Milliseconds', 'Seconds', 'Minutes'];
  final List<String> _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];
  String _chosenTimeType = 'Milliseconds';
  String _chosenMethod = 'GET';
  int _uuidLength = 10;
  final Uuid _uuid = const Uuid();
  List<String> _results = [];
  int _reqNumber = 0;

  Future<void> _start() async {
    _uri = Uri.parse(_url);
    _results = [];
    _reqNumber = 0;
    setState(() {
      _isRunning = true;
    });
    switch (_chosenTimeType) {
      case 'Milliseconds':
        _timer = Timer.periodic(Duration(milliseconds: _time), (timer) {
          _tick();
        });
        break;
      case 'Seconds':
        _timer = Timer.periodic(Duration(seconds: _time), (timer) {
          _tick();
        });
        break;
      default:
        _timer = Timer.periodic(Duration(minutes: _time), (timer) {
          _tick();
        });
        break;
    }
  }

  Future<void> _tick() async {
    _reqNumber++;
    http.Response res;
    String guid = _uuid.v1().toString();
    guid = guid.replaceAll('-', '');
    guid.substring(0, _uuidLength);
    String body = _body.replaceAll('%UUID%', guid);
    try {
      switch (_chosenMethod) {
        case 'POST':
          res = await http.post(_uri, body: body, headers: {
            "Content-Type": _contentType,
            "User-Agent": _userAgent,
          });
          break;
        case 'PUT':
          res = await http.put(_uri, body: body, headers: {
            "Content-Type": _contentType,
            "User-Agent": _userAgent,
          });
          break;
        case 'PATCH':
          res = await http.patch(_uri, body: body, headers: {
            "Content-Type": _contentType,
            "User-Agent": _userAgent,
          });
          break;
        case 'DELETE':
          res = await http.delete(_uri, body: body, headers: {
            "Content-Type": _contentType,
            "User-Agent": _userAgent,
          });
          break;
        default:
          res = await http.get(_uri, headers: {
            "Content-Type": _contentType,
            "User-Agent": _userAgent,
          });
          break;
      }
      setState(() {
        _results.insert(0, '${res.statusCode.toString()}\n${res.body}');
        if (_results.length > 200) {
          _results.removeLast();
        }
      });
    } catch (e) {
      setState(() {
        _results.insert(0, e.toString());
      });
      _stop();
    }
  }

  void _stop() {
    _timer.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Stress-Tester'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    DropdownButton<String>(
                      value: _chosenMethod,
                      items: _methods
                          .map(
                            (method) => DropdownMenuItem(
                              child: Text(method),
                              value: method,
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _chosenMethod = val!;
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'URL'),
                        onChanged: (val) => _url = val,
                      ),
                    ),
                    IconButton(
                      iconSize: 50,
                      icon: !_isRunning
                          ? const Icon(
                              Icons.play_circle_filled,
                              color: Colors.lightGreenAccent,
                            )
                          : const Icon(
                              Icons.pause_circle_filled,
                              color: Colors.redAccent,
                            ),
                      onPressed: () {
                        _isRunning ? _stop() : _start();
                      },
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Header'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        initialValue: _contentType,
                        decoration:
                            const InputDecoration(labelText: 'Content-Type'),
                        onChanged: (val) => _contentType = val,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextFormField(
                        initialValue: _userAgent,
                        decoration:
                            const InputDecoration(labelText: 'User-Agent'),
                        onChanged: (val) => _userAgent = val,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: const <Widget>[
                Text('Settings'),
                SizedBox(width: 20),
                Tooltip(
                  message: 'Add "%UUID%" for a random generated GUID',
                  textStyle: TextStyle(fontSize: 15, color: Colors.black),
                  child: Icon(Icons.info),
                ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    DropdownButton<String>(
                      value: _chosenTimeType,
                      items: _timeType
                          .map(
                            (method) => DropdownMenuItem(
                              child: Text(method),
                              value: method,
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _chosenTimeType = val!;
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Recurrence'),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        keyboardType: TextInputType.number,
                        initialValue: _time.toString(),
                        onChanged: (val) => _time = int.tryParse(val) ?? 0,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'UUID Length'),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        keyboardType: TextInputType.number,
                        initialValue: _uuidLength.toString(),
                        onChanged: (val) =>
                            _uuidLength = int.tryParse(val) ?? 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Body'),
            SizedBox(
              height: 10 * 20.0,
              child: TextFormField(
                maxLines: 10,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                onChanged: (val) => _body = val,
              ),
            ),
            const SizedBox(height: 10),
            Text('Requests sent: $_reqNumber'),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(_results[index]),
                    trailing: Text(DateTime.now().toString()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
