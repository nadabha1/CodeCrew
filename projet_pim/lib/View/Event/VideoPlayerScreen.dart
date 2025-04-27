import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final fixedUrl =
        widget.videoUrl.replaceFirst("localhost", "${ApiConstants.baseUrl2}");
    _controller = VideoPlayerController.network(fixedUrl);

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller.play();
      }
    }).catchError((e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      print("❌ Erreur init player : $e");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _changeMusic() async {
    await Permission.storage.request();

    if (!await Permission.manageExternalStorage.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⛔ Permission refusée pour accéder aux fichiers")),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final fileName = path.split('/').last;

      try {
        // Étape 1: upload fichier
        final uploadReq = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConstants.baseUrl}/reels/upload-music'),
        );
        uploadReq.files.add(await http.MultipartFile.fromPath('file', path));

        final uploadRes = await uploadReq.send();

        if (uploadRes.statusCode == 200 || uploadRes.statusCode == 201) {
          print("✅ Upload musique réussi");

          // Étape 2: appel add-music
          final eventId = _getEventIdFromUrl(widget.videoUrl);
          final response = await http.post(
            Uri.parse('${ApiConstants.baseUrl}/reels/add-music/$eventId'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"music": fileName}),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Musique modifiée avec succès !")),
            );
          } else {
            print("❌ Erreur serveur: ${response.body}");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("❌ Erreur lors de la modification.")),
            );
          }
        } else {
          print("❌ Erreur upload musique: ${uploadRes.statusCode}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Échec de l'upload du fichier")),
          );
        }
      } catch (e) {
        print("❌ Exception: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Erreur interne.")),
        );
      }
    } else {
      print("❌ Aucune musique sélectionnée");
    }
  }

  String _getEventIdFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments.last.split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Souvenir vidéo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note),
            tooltip: "Modifier la musique",
            onPressed: _changeMusic,
          )
        ],
      ),
      body: Center(
        child: _hasError
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      "❌ Erreur de lecture :\n$_errorMessage",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              )
            : _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(),
      ),
      floatingActionButton: !_hasError
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
