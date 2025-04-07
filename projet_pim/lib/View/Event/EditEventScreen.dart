import 'package:flutter/material.dart';
import 'package:projet_pim/Model/event.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;
  final Function(Event) onSave;

  const EditEventScreen({Key? key, required this.event, required this.onSave})
      : super(key: key);

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.event.title);
    descriptionController =
        TextEditingController(text: widget.event.description);
    locationController = TextEditingController(text: widget.event.location);
    selectedDate = widget.event.date;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _saveChanges() {
    Event updatedEvent = Event(
  id: widget.event.id,
  title: titleController.text,
  description: descriptionController.text,
  creatorId: widget.event.creatorId,
  date: selectedDate,
  location: locationController.text,
  participants: widget.event.participants,
  isParticipating: widget.event.isParticipating,
  joinPrice: widget.event.joinPrice,
  conversationId: widget.event.conversationId,
  type: widget.event.type, // 🟢 Ajouter cette ligne
);


    widget.onSave(updatedEvent);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modifier l'événement")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Titre"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: "Lieu"),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Date: ${selectedDate.toLocal()}".split(' ')[0]),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: Text("Enregistrer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
