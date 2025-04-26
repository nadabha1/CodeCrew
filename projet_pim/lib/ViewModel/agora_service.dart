import 'package:agora_rtc_engine/agora_rtc_engine.dart';

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
