import 'package:flutter/material.dart';
import '../../app_config.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoRoomScreen extends StatefulWidget {
  final String channelName;
  final int uid;
  const VideoRoomScreen({super.key, required this.channelName, required this.uid});

  @override
  State<VideoRoomScreen> createState() => _VideoRoomScreenState();
}

class _VideoRoomScreenState extends State<VideoRoomScreen> {
  RtcEngine? _engine;
  bool _joined = false;
  int _localUid = 0;
  int? _remoteUid;

  final String appId = 'f251c48a11e3498dacd358e1fb6e6958';

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final engine = createAgoraRtcEngine();
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          print('[Agora] onUserJoined: remoteUid=$remoteUid');
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          print('[Agora] onUserOffline: remoteUid=$remoteUid, reason=$reason');
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );
    await [Permission.microphone, Permission.camera].request();

    final token = await _fetchToken(widget.channelName, widget.uid);
    await engine.initialize(RtcEngineContext(appId: appId));
    await engine.enableVideo();
    await engine.startPreview();
    await engine.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: widget.uid,
      options: ChannelMediaOptions(),
    );
    setState(() {
      _engine = engine;
      _joined = true;
      _localUid = widget.uid;
    });
  }

  Future<String> _fetchToken(String channel, int uid) async {
  final url = Uri.parse('${AppConfig.apiBase}/video/agora-token?channel=$channel&uid=$uid');
    final res = await http.get(url);
    final data = json.decode(res.body);
    return data['token'];
  }

  @override
  void dispose() {
  _engine?.leaveChannel();
  _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phòng khám video')),
      body: (_joined && _engine != null)
          ? Column(
              children: [
                Expanded(
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: _localUid),
                    ),
                  ),
                ),
                Expanded(
                  child: _remoteUid != null
                      ? AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: _engine!,
                            canvas: VideoCanvas(uid: _remoteUid!),
                            connection: const RtcConnection(),
                          ),
                        )
                      : Center(child: Text('Đang chờ người khác vào phòng...')),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}