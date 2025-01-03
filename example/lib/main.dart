import 'package:flutter/material.dart';
import 'package:flutter_cast_plus/flutter_cast_plus.dart';
import 'package:flutter_cast_plus_example/scan_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Cast Plus Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CastDevice? device;
  final testVideo =
      'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_1MB.mp4';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Cast Plus Example'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Connected Device: ${device?.friendlyName ?? ''}',
              ),
              if (device != null)
                ElevatedButton.icon(
                  onPressed: () {
                    device?.service.loadPlaylist(
                      [
                        CastMedia(
                          contentId: testVideo,
                          title: 'Bib Bug Bunny',
                          autoPlay: true,
                        ),
                      ],
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'Play',
                  ),
                )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<CastDevice?>(
            context: context,
            builder: (_) => const ScanDialog(),
          );
          if (result != null) {
            device = result;
            setState(() {});
          }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
