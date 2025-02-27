import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopFiveDisplay extends StatelessWidget {
  final String userId;

  TopFiveDisplay({Key? key, required this.userId}) : super(key: key);

  // Default categories
  final List<String> _defaultCategories = [
    'Movies',
    'Books',
    'Musician / Band',
    'Travel Locations'
  ];

  // Convert category name to storage key (lowercase, no spaces)
  String _getCategoryKey(String category) {
    return category.toLowerCase().replaceAll(' / ', '_').replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('No data found'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final topFive = userData['topFive'] as Map<String, dynamic>;

        // Build widgets for default categories
        List<Widget> categoryWidgets = [];

        // Add default categories
        for (String category in _defaultCategories) {
          String key = _getCategoryKey(category);
          if (topFive.containsKey(key)) {
            categoryWidgets.add(_buildCategory(context, category, topFive[key]));
            categoryWidgets.add(SizedBox(height: 30));
          }
        }

        // Add custom categories if they exist
        if (topFive.containsKey('customCategories')) {
          List<String> customCategories = List<String>.from(topFive['customCategories']);

          for (String category in customCategories) {
            String key = _getCategoryKey(category);
            if (topFive.containsKey(key)) {
              categoryWidgets.add(_buildCategory(context, category, topFive[key]));
              categoryWidgets.add(SizedBox(height: 30));
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: categoryWidgets,
        );
      },
    );
  }

  Widget _buildCategory(BuildContext context, String title, List<dynamic> items) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              item,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          )).toList(),
          if (items.isEmpty)
            Text(
              'No items added yet',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}