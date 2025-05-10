import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/review.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/carnet&place/Details.dart';
import 'package:provider/provider.dart';

class CarnetDetailsPage extends StatefulWidget {
  final Carnet carnet;

  const CarnetDetailsPage({super.key, required this.carnet});

  @override
  _CarnetDetailsPageState createState() => _CarnetDetailsPageState();
}

class _CarnetDetailsPageState extends State<CarnetDetailsPage> {
  late String carnetTitle;

  void _updateCarnetTitle(String newTitle) async {
    if (newTitle.isEmpty) return;

    try {
      print("🔄 Envoi de la mise à jour du carnet...");
      await Provider.of<CarnetProvider>(context, listen: false)
          .updateCarnet(widget.carnet.id, newTitle);

      setState(() {
        carnetTitle = newTitle;
      });

      print("✅ Mise à jour réussie !");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Carnet mis à jour avec succès")),
      );
    } catch (e) {
      print("❌ Erreur updateCarnet: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la mise à jour du carnet")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    carnetTitle = widget.carnet.title;
  }

  void _editCarnetTitle() {
    TextEditingController controller = TextEditingController(text: carnetTitle);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le nom du Carnet",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Nouveau nom",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              String newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                _updateCarnetTitle(newTitle);
              }
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
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
              title: Text('Supprimer ${place.name}?'),
              content: const Text('Êtes-vous sûr de vouloir supprimer cet endroit?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldDelete) {
        const jwtToken = 'YOUR_JWT_TOKEN'; // À récupérer dynamiquement
        print("🛠 Suppression de ${place.name} avec ID: ${place.id}");

        await Provider.of<CarnetProvider>(context, listen: false)
            .deletePlace(widget.carnet.id, place.id, jwtToken);

        setState(() {
          widget.carnet.places.removeWhere((p) => p.id == place.id);
        });

        print("✅ ${place.name} supprimé avec succès");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${place.name} supprimé avec succès')),
        );
      }
    } catch (e, stacktrace) {
      print("❌ Erreur lors de la suppression de ${place.name}: $e");
      print(stacktrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(carnetTitle),
        backgroundColor: const Color(0xFFDBD9FE),
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
            colors: [
              Color(0xFFDBD9FE),
              Color.fromARGB(255, 233, 185, 241)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
