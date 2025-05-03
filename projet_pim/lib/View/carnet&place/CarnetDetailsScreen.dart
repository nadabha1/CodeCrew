import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/review.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/carnet&place/Details.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarnetDetailsPage extends StatefulWidget {
  final Carnet carnet;

  const CarnetDetailsPage({super.key, required this.carnet});

  @override
  _CarnetDetailsPageState createState() => _CarnetDetailsPageState();
}

class _CarnetDetailsPageState extends State<CarnetDetailsPage> {
  late String carnetTitle;
  String? userId;
  String? token;
  bool isLoading = true;

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? _userId = prefs.getString("user_id");
    String? _token = prefs.getString("jwt_token");

    if (_userId != null && _token != null) {
      setState(() {
        userId = _userId;
        token = _token;
      });
    } else {
      print("User ID or Token is not available");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateCarnetTitle(String newTitle) async {
    if (newTitle.isEmpty) return;

    try {
      print("🔄 Sending the logbook update...");
      await Provider.of<CarnetProvider>(context, listen: false)
          .updateCarnet(widget.carnet.id, newTitle);

      setState(() {
        carnetTitle = newTitle;
      });

      print("✅ Update successful!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Carnet mis à jour avec succès")),
      );
    } catch (e) {
      print("❌ updateNotebook error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating the notebook")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    carnetTitle = widget.carnet.title;
    _loadUserData(); // Charge les données utilisateur au démarrage
  }

  void _editCarnetTitle() {
    TextEditingController controller = TextEditingController(text: carnetTitle);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change the name of the Notebook",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "New name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              String newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                _updateCarnetTitle(newTitle);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deletePlace(Place place) async {
    try {
      bool shouldDelete = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('DELETE ${place.name}?'),
              content:
                  const Text('Are you sure you want to delete this location?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('DELETE'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldDelete) {
        print(
            "🛠 Attempting to delete place: ${place.name} with ID: ${place.id}");

        // Recharge les carnets pour s'assurer que la liste est à jour
        await Provider.of<CarnetProvider>(context, listen: false)
            .fetchCarnets();

        await Provider.of<CarnetProvider>(context, listen: false)
            .deletePlace(widget.carnet.id, place.id, token!);

        setState(() {
          widget.carnet.places.removeWhere((p) => p.id == place.id);
        });

        print("✅ ${place.name} successfully deleted");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${place.name} successfully deleted')),
        );
      }
    } catch (e, stacktrace) {
      print("❌ Error deleting ${place.name}: $e");
      print(stacktrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(carnetTitle),
        backgroundColor: const Color(0xFFD1C4E9),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCarnetTitle,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD1C4E9), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Places in this Carnet:',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.carnet.places.length,
                  itemBuilder: (context, index) {
                    final place = widget.carnet.places[index];
                    return PlaceCard(
                      place: place,
                      onDelete: () => _deletePlace(place),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final carnetProvider =
              Provider.of<CarnetProvider>(context, listen: false);
          final carnetId = carnetProvider.userCarnet?['carnet']['_id'] ??
              ''; // Safely handle if carnet is null or empty

          if (carnetId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPlaceScreenStep1(
                  carnetId: carnetId,
                ),
              ),
            );
          } else {
            // Handle the case when carnetId is not available
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Carnet ID is missing!")),
            );
          }
        },
        backgroundColor: const Color(0xFFF3C7F9),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onDelete;

  const PlaceCard({super.key, required this.place, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          place.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Unlock Cost: ${place.unlockCost}',
                    style: const TextStyle(fontSize: 14, color: Colors.green)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(),
                ),
              ],
            ),
          ],
        ),
        leading: place.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: Image.network(
                            place.images[0],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    );
                  },
                  child: Image.network(
                    place.images[0],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : const Icon(Icons.place),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Details(place: place),
            ),
          );
        },
      ),
    );
  }
}
