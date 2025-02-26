import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/followService.dart';

class FollowButton extends StatefulWidget {
  final String targetUserId;
  final bool isFollowing;
  final String token;

  FollowButton(
      {required this.targetUserId,
      required this.isFollowing,
      required this.token});

  @override
  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
  }

  void _toggleFollow() async {
    try {
      if (_isFollowing) {
        await FollowService().unfollowUser(widget.targetUserId, widget.token);
      } else {
        await FollowService().followUser(widget.targetUserId, widget.token);
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      print("Erreur: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _toggleFollow,
      child: Text(_isFollowing ? "Unfollow" : "Follow"),
    );
  }
}
