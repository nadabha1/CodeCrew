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
  const CallScreen(
      {Key? key,
      required this.channelName,
      required this.conversationId,
      required this.userId})
      : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static const String appId =
      '6d5a203e2d024f2c92c9e9f44bc37390'; // Replace with your real appId
  late final RtcEngine _engine; // 👈 private instance created here
  int? _remoteUid;
  bool _isJoined = false;

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
        debugPrint('⚠️ Unable to fetch token, status: ${response.statusCode}');
        return "";
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching token: $e');
      return "";
    }
  }

  Future<void> initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId, // your real appId
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    await _engine.enableAudio();

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('✅ [Agora] Successfully joined: ${connection.channelId}');
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('👤 [Agora] Remote user: $remoteUid');
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint('❌ [Agora] User left: $remoteUid');
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    // 👉 NEW: fetch token before joining the channel
    final token = await _fetchToken(widget.channelName);

    await _engine.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void sendChannelLink() async {
    final message = '📞 Join me on the call: ${widget.channelName}';

    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/messages'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "conversationId":
            widget.conversationId, // need to pass the conversationId
        "senderId": widget.userId, // need to pass the userId as well
        "content": message,
        "type": "call_invite",
      }),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  Stream<int?> get remoteUserStream async* {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield _remoteUid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ongoing Call'),
      ),
      body: Center(
        child: !_isJoined
            ? const CircularProgressIndicator()
            : StreamBuilder<int?>(
                stream: remoteUserStream,
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return const Text('Connected. Waiting for another user...');
                  } else {
                    return const Text('User has joined the call! 🎉');
                  }
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.call_end),
      ),
    );
  }
}
