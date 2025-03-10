import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Providers/review_provider.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:provider/provider.dart';

class PlaceDetailsProviderScreen extends StatelessWidget {
  final Place place;

  const PlaceDetailsProviderScreen({required this.place, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReviewProvider>(
      create: (_) => ReviewProvider(),
      child: PlaceDetailsScreen(place: place),
    );
  }
}
