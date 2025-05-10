// TravelerProfileScreen complet avec tabs (Infos, Adresses, Avis) et follow dynamique, responsive et animations ✨

import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/review.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:projet_pim/ViewModel/review_service.dart';
import 'package:projet_pim/ViewModel/user_service.dart';

class TravelerProfileScreen extends StatefulWidget {
  final String travelerId;
  final String loggedInUserId;
  final String token;

  const TravelerProfileScreen({super.key, required this.travelerId, required this.loggedInUserId, required this.token});

  @override
  State<TravelerProfileScreen> createState() => _TravelerProfileScreenState();
}

class _TravelerProfileScreenState extends State<TravelerProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? travelerData;
  List<Carnet> travelerCarnets = [];
  List<Review> travelerReviews = [];
  bool isFollowing = false;
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchTravelerProfile();
  }

  Future<void> fetchTravelerProfile() async {
    try {
      final userService = UserService();
      final carnetService = CarnetService();
      final reviewService = ReviewService();

      final user = await userService.getUserById(widget.travelerId, widget.token);
      final carnets = await carnetService.getUserCarnet(widget.travelerId);
      final reviews = await reviewService.getReviewsByUser(widget.travelerId);
      final followers = await userService.getFollowers(widget.travelerId);
      bool alreadyFollowing = followers.contains(widget.loggedInUserId);

      setState(() {
        travelerData = user;
        travelerCarnets = carnets;
        travelerReviews = reviews;
        isFollowing = alreadyFollowing;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleFollow() async {
    try {
      final userService = UserService();
      if (isFollowing) {
        await userService.unfollowUser(widget.loggedInUserId, widget.travelerId);
      } else {
        await userService.followUser(widget.loggedInUserId, widget.travelerId);
      }
      setState(() {
        isFollowing = !isFollowing;
      });
    } catch (e) {
      print('Erreur follow/unfollow: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: const Text('Profil Voyageur', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    indicatorColor: Colors.deepPurple,
                    tabs: const [
                      Tab(text: 'Infos'),
                      Tab(text: 'Adresses'),
                      Tab(text: 'Avis'),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(),
                        _buildAdressesTab(),
                        _buildAvisTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: travelerData?['profileImage'] != null && travelerData!['profileImage'].toString().isNotEmpty
                ? NetworkImage(travelerData!['profileImage'])
                : const AssetImage('assets/default_profile.png') as ImageProvider,
          ),
          const SizedBox(height: 10),
          Text(travelerData?['name'] ?? 'Nom inconnu', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(travelerData?['job'] ?? 'Profession inconnue', style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey : Colors.deepPurple,
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                isFollowing ? 'Unfollow' : 'Follow',
                key: ValueKey<bool>(isFollowing),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Bio: ${travelerData?['bio']?.isNotEmpty == true ? travelerData!['bio'] : "Cet utilisateur n\'a pas encore ajouté de bio."}'),
            const SizedBox(height: 10),
            Text('Localisation: ${travelerData?['location'] ?? "Inconnue"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdressesTab() {
    if (travelerCarnets.isEmpty) {
      return const Center(child: Text("Pas de carnet d'adresses trouvé."));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: travelerCarnets.length,
      itemBuilder: (context, index) {
        final carnet = travelerCarnets[index];
        return Card(
          child: ListTile(
            title: Text(carnet.title),
            subtitle: Text('${carnet.places.length} lieux'),
          ),
        );
      },
    );
  }

  Widget _buildAvisTab() {
    if (travelerReviews.isEmpty) {
      return const Center(child: Text("Aucun avis trouvé."));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: travelerReviews.length,
      itemBuilder: (context, index) {
        final review = travelerReviews[index];
        return Card(
          child: ListTile(
            subtitle: Text(review.comment ?? ''),
            trailing: Text('${review.rating}/5 ⭐'),
          ),
        );
      },
    );
  }
}
