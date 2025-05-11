import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/ViewModel/api_constants.dart';

const String appId = "499528fa940d452ab223f7c886d9ee58";
const String channelName = "nom_du_channel";
const String token = "";

late RtcEngine agoraEngine;

Future<void> setupAgora() async {
  agoraEngine = createAgoraRtcEngine();
  await agoraEngine.initialize(
    const RtcEngineContext(
      appId: appId,
    ),
  );

  agoraEngine.registerEventHandler(
    RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        print("✅ Rejoint le channel: ${connection.channelId}");
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        print("👋 Utilisateur $remoteUid a rejoint !");
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        print("❌ Utilisateur $remoteUid est parti.");
      },
    ),
  );
}

Future<void> joinCall(String channelName) async {
  await agoraEngine.joinChannel(
    token: token,
    channelId: channelName,
    uid: 0,
    options: const ChannelMediaOptions(),
  );
}

Future<void> leaveCall() async {
  await agoraEngine.leaveChannel();
}

class AgoraService {
  Future<List<Map<String, dynamic>>> fetchParticipants(
      String channelName) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}/agora/participants?channelName=$channelName'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      debugPrint('Réponse des participants: $data'); // Ajoute un print ici
      return data
          .map<Map<String, dynamic>>((e) => {
                'uid': e['uid'],
                'name': e['name'],
              })
          .toList();
    } else {
      throw Exception('Failed to load participants');
    }
  }
}
