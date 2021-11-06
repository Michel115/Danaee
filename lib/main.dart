import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart' as ion;
import 'package:uuid/uuid.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainHomePage(title: 'Pion/ion Many to Many Conference App'),
    );
  }
}

class MainHomePage extends StatefulWidget {
  MainHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MainHomePageState createState() => _MainHomePageState();
}

class Participant {
  Participant(this.title, this.renderer, this.stream);
  MediaStream? stream;
  String title;
  RTCVideoRenderer renderer;
}

class _MainHomePageState extends State<MainHomePage> {
  List<Participant> plist = <Participant>[];
  // ion.Signal? _signal;
  String ServerURL = '';
  ion.Client? _client;
  ion.LocalStream? _localStream;
  final String _uuid = Uuid().v4();

  @override
  void initState() {
    super.initState();
    initSignal();
    //ServerURL = 'http://147.78.45.13:9090';
  }

  initSignal() {
    if (kIsWeb) {
      //ServerURL = 'http://10.10.4.64:9090';
      ServerURL = 'http://147.78.45.13:9090';
    } else {
      ServerURL = 'http://147.78.45.13:9090';
      //ServerURL = 'http://10.10.4.64:9090';
    }
  }

  late ion.Signal _signal = ion.GRPCWebSignal(ServerURL);

  void pubSub() async {
    log("serverurl " + ServerURL);
    if (_client == null) {
      // create new client
      _client = await ion.Client.create(
          sid: "test room", uid: _uuid, signal: _signal);

      // peer ontrack
      _client?.ontrack = (track, ion.RemoteStream remoteStream) async {
        if (track.kind == 'video') {
          print('ontrack: remote stream: ${remoteStream.stream}');
          var renderer = RTCVideoRenderer();
          await renderer.initialize();
          renderer.srcObject = remoteStream.stream;
          setState(() {
            plist.add(
                Participant('RemoteStream', renderer, remoteStream.stream));
          });
        }
      };

      // create get user camera stream
      _localStream = await ion.LocalStream.getUserMedia(
          constraints: ion.Constraints.defaults..simulcast = false);

      // publish the stream
      await _client?.publish(_localStream!);

      var renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = _localStream?.stream;
      setState(() {
        plist.add(Participant("LocalStream", renderer, _localStream?.stream));
      });
    } else {
      // unPublish and remove stream from video element
      await _localStream?.stream.dispose();
      _localStream = null;
      _client?.close();
      _client = null;
    }
  }

  Widget getItemView(Participant item) {
    log("items: " + item.toString());
    return Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${item.title}:\n${item.stream!.id}',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            Expanded(
              child: RTCVideoView(item.renderer,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitContain),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: plist.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 5.0,
            crossAxisSpacing: 5.0,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (BuildContext context, int index) {
            return getItemView(plist[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pubSub,
        tooltip: 'Increment',
        child: Icon(Icons.video_call),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
