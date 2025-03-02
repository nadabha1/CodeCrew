import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/Providers/review_provider.dart';
import 'package:projet_pim/View/EditProfileScreen.dart';
import 'package:projet_pim/View/FavoritesScreen.dart';
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/carnet&place/carnet_dtetails_screen.dart';
import 'package:projet_pim/View/settings/settings_screen.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart'; // Assure-toi d'importer le CarnetService
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/ViewModel/login.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Assure-toi d'importer le modèle Carnet

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String token;

  const UserProfileScreen({required this.userId, required this.token, Key? key})
      : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  List<Carnet> userCarnet = [];
  Map<String, dynamic>? travelerData;

  @override
  void initState() {
    super.initState();
    fetchUser();
    fetchFollowerData();
  }

  Future<void> fetchFollowerData() async {
    try {
      UserService userService = UserService();
      final prefs = await SharedPreferences.getInstance();
      String? _userId = prefs.getString("user_id");

      if (_userId == null) return;

      // Fetch followers and following lists
      List<String> followers = await userService.getFollowers(_userId);
      List<String> following = await userService.getFollowing(_userId);

      // Fetch follower and following counts
      int followersCount = await userService.getFollowersCount(_userId);
      int followingCount = await userService.getFollowingCount(_userId);

      print(
          'Followers count: $followersCount, Following count: $followingCount');

      setState(() {
        // Update userData instead of travelerData
        userData?['followers'] = followers;
        userData?['following'] = following;
        userData?['followersCount'] =
            followersCount.toString(); // Convert to string
        userData?['followingCount'] = followingCount.toString();
      });
    } catch (e) {
      print("❌ Error fetching followers/following: $e");
    }
  }

  Future<void> fetchUser() async {
    try {
      fetchFollowerData();
      // Appel pour récupérer les données utilisateur
      UserService userService = UserService();
      Map<String, dynamic> user =
          await userService.getUserById(widget.userId, widget.token);
      print('sayeeeeeeeee');
      print(user);
      userData = user;

      // Appel pour récupérer le carnet de l'utilisateur
      CarnetService carnetService = CarnetService();
      List<Carnet> carnet = await carnetService.getUserCarnet(widget.userId);
      setState(() {
        userData = user;
        userCarnet = carnet; // Met à jour le carnet de l'utilisateur
        isLoading = false;
      });
      await fetchFollowerData(); // ✅ Fetch follower data after user data
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: AppBar(
            backgroundColor: const Color.fromRGBO(219, 217, 254, 1),
            elevation: 0,
            flexibleSpace: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 20),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: userData?['profilePicture'] != null
                          ? NetworkImage(userData!['profilePicture'])
                          : const AssetImage('assets/default_profile.png')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userData?['name'] ?? 'Nom inconnu',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userData?['bio'] ?? 'bio non spécifié',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.work, // Icône représentant un métier
                        size: 20, // Taille de l'icône
                        color: Colors.black54, // Couleur de l'icône
                      ),
                      const SizedBox(
                          width: 4), // Espace entre l'icône et le texte
                      Text(
                        userData?['job'] ??
                            'Métier non spécifié', // Texte du métier
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.black54,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        userData?['location'] ?? 'Lieu inconnu',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Container pour le fond
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 1), // Ajoute du padding autour du contenu
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                          255, 250, 195, 166), // Couleur de fond orange
                      borderRadius: BorderRadius.circular(
                          8), // Optionnel : arrondir les coins
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '💰', // Emoji de coin
                          style: TextStyle(
                            fontSize: 20, // Taille de l'emoji
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 0.1),
                        // Affichage du nombre de coins
                        Text(
                          '${userData?['coins'] ?? 0}', // Nombre de coins
                          style: const TextStyle(
                            fontSize: 20, // Taille du texte
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4F98F), // Couleur verte des coins
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 280),
                  // Bouton pour consulter les favoris
                  IconButton(
                    icon:
                        const Icon(Icons.favorite_border), // Icône des favoris
                    onPressed: () {
                      // Naviguer vers la page des favoris
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  // Icone des paramètres
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SettingsScreen(userData: userData!)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatItem(
                          count: userData?['followersCount']?.toString() ??
                              '0', // ✅ Use userData
                          label: 'Followers',
                        ),
                        SizedBox(width: 20),
                        _StatItem(
                          count: userData?['followingCount']?.toString() ??
                              '0', // ✅ Use userData
                          label: 'Following',
                        ),
                        SizedBox(width: 20),
                        _StatItem(
                          count: userData?['likes']?.toString() ?? '0',
                          label: 'Likes',
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    const Text(
                      'Carnet d’adresses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 📌 Section Carnet d’Adresses avec les données du carnet
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: userCarnet.isNotEmpty
                            ? userCarnet[0].places.length
                            : 0,
                        itemBuilder: (context, index) {
                          return AddressCard(
                            place: userCarnet[0].places[
                                index], // Passe directement l'objet Place
                          );
                        },
                      ),
                    ),
                    // ✅ Floating Action Button ici
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 32),
                      child: FloatingActionButton(
                        backgroundColor:
                            const Color.fromARGB(255, 248, 214, 253),
                        child: const Icon(Icons.add),
                        onPressed: () async {
                          await carnetProvider.checkUserCarnet(widget.userId);
                          if (carnetProvider.userCarnet == null ||
                              !carnetProvider.userCarnet!['hasCarnet']) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateCarnetScreen(userId: widget.userId),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPlaceScreenStep1(
                                  carnetId: carnetProvider.userCarnet!['carnet']
                                      ['_id'],
                                ),
                              ),
                            ).then((_) {
                              fetchUser(); // Rafraîchit la page après l'ajout de la place
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Text(
                      'Publications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PublicationCard(),
                  ],
                ),
              ),
            ),
    );
  }
}

// 📌 Widget pour afficher les adresses
class AddressCard extends StatelessWidget {
  final Place place; // Utilise un objet Place directement

  const AddressCard({required this.place, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Naviguer vers PlaceDetailsScreen en passant l'objet Place
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (context) => ReviewProvider(),
              child: PlaceDetailsScreen(place: place),
            ),
          ),
        );
      },
      child: SizedBox(
        width: 300,
        height: 300,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: place.images.isNotEmpty
                  ? NetworkImage(place.images.first)
                  : const AssetImage('assets/default_image.jpg')
                      as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(63, 0, 0, 0).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white, size: 16),
                        Text(
                          place.latitude != null && place.longitude != null
                              ? '${place.latitude}, ${place.longitude}'
                              : 'Lieu inconnu',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;

  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _PublicationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDBD9FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.group, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Peer Group Meetup',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Let’s open up to the thing that matters among the people",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE7B32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Join Now'),
          ),
        ],
      ),
    );
  }
}
