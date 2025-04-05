import 'package:flutter/material.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:intl/intl.dart';

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
  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.event.title);
    descriptionController =
        TextEditingController(text: widget.event.description);
    locationController = TextEditingController(text: widget.event.location);
    startDate = widget.event.startDate;
    endDate = widget.event.endDate;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != startDate) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(startDate),
      );

      if (pickedTime != null) {
        setState(() {
          startDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (endDate.isBefore(startDate)) {
            endDate = startDate.add(Duration(hours: 1));
          }
        });
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != endDate) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(endDate),
      );

      if (pickedTime != null) {
        setState(() {
          endDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveChanges() {
    Event updatedEvent = Event(
      id: widget.event.id,
      title: titleController.text,
      description: descriptionController.text,
      creatorId: widget.event.creatorId,
      startDate: startDate,
      endDate: endDate,
      location: locationController.text,
      participants: widget.event.participants,
      isParticipating: widget.event.isParticipating,
      joinPrice: widget.event.joinPrice,
      conversationId: widget.event.conversationId,
      type: widget.event.type,
    );

    widget.onSave(updatedEvent);
    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("Modifier l'événement", style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xFFEDE7F6),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildTextField(titleController, "Titre"),
              SizedBox(height: 16),
              _buildTextField(descriptionController, "Description",
                  maxLines: 3),
              SizedBox(height: 16),
              _buildTextField(locationController, "Lieu"),
              SizedBox(height: 16),
              _buildDateRow("Début", startDate, _selectStartDate),
              SizedBox(height: 16),
              _buildDateRow("Fin", endDate, _selectEndDate),
              SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildDateRow(
      String label, DateTime date, Function(BuildContext) onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today,
                color: Theme.of(context).primaryColor),
            onPressed: () => onTap(context),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _saveChanges,
        child:
            Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
