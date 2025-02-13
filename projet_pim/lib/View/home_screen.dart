import 'package:flutter/material.dart';
import 'package:projet_pim/View/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/add_place_screen.dart';
import 'package:projet_pim/View/carnet_dtetails_screen.dart';
import 'package:provider/provider.dart';
import '../Providers/carnet_provider.dart';

class HomeScreen extends StatefulWidget {
  final String userId; // Ensure userId is passed

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<CarnetProvider>(context, listen: false).checkUserCarnet(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFFF7F4FC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight),
          child: carnetProvider.isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📌 Header Section
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFB19CD9),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.menu, color: Colors.white, size: 28),
                                CircleAvatar(
                                  backgroundImage:
                                      AssetImage('assets/profile.jpg'),
                                  radius: 22,
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Hey User!",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Where's your next trip going to be?",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // 📌 "Near Your Location" Section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text("Near Your Location",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 10),

                      // 📌 Floating Action Button for Adding Carnet/Place
                  FloatingActionButton(
  backgroundColor: Colors.purple,
  child: Icon(Icons.add),
  onPressed: () async {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: false);
    
    // Ensure userId is dynamically retrieved
    await carnetProvider.checkUserCarnet(widget.userId);

    if (carnetProvider.userCarnet == null || !carnetProvider.userCarnet!['hasCarnet']) {
      // Redirect user to create a carnet if they don't have one
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateCarnetScreen(userId: widget.userId),
        ),
      );
    } else {
      // Redirect user to add a place if they already have a carnet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddPlaceScreenStep1(
            carnetId: carnetProvider.userCarnet!['carnet']['_id'],
          ),
        ),
      );
    }
  },
),


                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
