import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:story_view/story_view.dart';
import 'package:video_player/video_player.dart'; // ⭐ Ajout obligatoire

class ReelStoryView extends StatefulWidget {
  final List<String> reelsUrls;

  const ReelStoryView({super.key, required this.reelsUrls});

  @override
  _ReelStoryViewState createState() => _ReelStoryViewState();
}

class _ReelStoryViewState extends State<ReelStoryView> {
  final StoryController _storyController = StoryController();
  bool isLoading = true;
  List<StoryItem> stories = [];

  @override
  void initState() {
    super.initState();
    _prepareStories();
  }

  Future<void> _prepareStories() async {
    if (widget.reelsUrls.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    List<StoryItem> tempStories = [];

    for (String url in widget.reelsUrls) {
      if (!url.endsWith('.mp4')) continue;

      final fullUrl =
          url.startsWith('http') ? url : '${ApiConstants.baseUrl}/$url';

      final controller = VideoPlayerController.network(fullUrl);
      await controller.initialize(); // ⏳ Important ! Wait until loaded

      tempStories.add(StoryItem.pageVideo(
        url,
        controller: _storyController,
        caption: Text("🎬 Souvenir de l'événement"),
      ));
    }

    setState(() {
      stories = tempStories;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (stories.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'Aucune vidéo disponible',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      body: StoryView(
        storyItems: stories,
        controller: _storyController,
        repeat: false,
        onComplete: () {
          Navigator.pop(context);
        },
        onVerticalSwipeComplete: (direction) {
          if (direction == Direction.down) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
