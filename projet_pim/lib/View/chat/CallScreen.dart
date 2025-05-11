import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String conversationId;
  final String userId;

  const CallScreen({
    Key? key,
    required this.channelName,
    required this.conversationId,
    required this.userId,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static const String appId = '6d5a203e2d024f2c92c9e9f44bc37390';
  late final RtcEngine _engine;
  bool _isJoined = false;
  bool _isCameraOn = false;
  bool _isMicOn = true;
  List<int> _remoteUids = [];

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<String> _fetchToken(String channelName) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/agora/token?channelName=$channelName&uid=0&role=PUBLISHER'),
      );
      if (response.statusCode == 200) {
        final token = response.body;
        debugPrint('🪪 Token retrieved: $token');
        return token;
      } else {
        debugPrint(
            '⚠️ Failed to retrieve token, status: ${response.statusCode}, body: ${response.body}');
        return "";
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching token: $e');
      return "";
    }
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    await _engine.enableVideo();
    await _engine.enableLocalVideo(false);
    await _engine.muteLocalAudioStream(false);

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('✅ [Agora] Joined channel: ${connection.channelId}');
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('👤 [Agora] Remote user joined: $remoteUid');
          setState(() {
            if (!_remoteUids.contains(remoteUid)) {
              _remoteUids.add(remoteUid);
            }
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint('❌ [Agora] User left: $remoteUid');
          setState(() {
            _remoteUids.remove(remoteUid);
          });
        },
      ),
    );

    final token = await _fetchToken(widget.channelName);
    if (token.isEmpty) throw Exception('❌ Failed to retrieve token');

    await _engine.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void toggleCamera() async {
    setState(() {
      _isCameraOn = !_isCameraOn;
    });
    await _engine.enableLocalVideo(_isCameraOn);
    if (_isCameraOn) {
      await _engine.startPreview();
    } else {
      await _engine.stopPreview();
    }
  }

  void toggleMic() async {
    setState(() {
      _isMicOn = !_isMicOn;
    });
    await _engine.muteLocalAudioStream(!_isMicOn);
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  void sendChannelLink() async {
    final message = '📞 Rejoins-moi sur l\'appel : ${widget.channelName}';
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/messages'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "conversationId": widget.conversationId,
        "senderId": widget.userId,
        "content": message,
        "type": "call_invite",
      }),
    );
  }

  Widget _buildVideoGrid() {
    final views = <Widget>[];

    // Vue locale
    views.add(
      _isCameraOn
          ? AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
          : const Center(child: Text("🎥 Caméra locale désactivée")),
    );

    // Vues distantes
    for (final uid in _remoteUids) {
      views.add(
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: widget.channelName),
          ),
        ),
      );
    }

    return GridView.builder(
      itemCount: views.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: views.length <= 2 ? 1 : 2,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, index) => Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
        child: views[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appel vidéo')),
      body: _isJoined
          ? _buildVideoGrid()
          : const Center(child: Text("Connexion à l'appel...")),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'toggleCam',
            onPressed: toggleCamera,
            backgroundColor: _isCameraOn
                ? const Color(0xFFDBD9FE)
                : const Color.fromARGB(146, 219, 217, 254),
            child: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'toggleMic',
            onPressed: toggleMic,
            backgroundColor: _isMicOn
                ? const Color(0xFFD4F98F)
                : const Color.fromARGB(161, 212, 249, 143),
            child: Icon(_isMicOn ? Icons.mic : Icons.mic_off),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'endCall',
            onPressed: () => Navigator.pop(context),
            backgroundColor: const Color.fromARGB(255, 255, 47, 32),
            child: const Icon(Icons.call_end),
          ),
        ],
      ),
    );
  }
}
