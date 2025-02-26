import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopFiveForm extends StatefulWidget {
  final String userId;
  final VoidCallback onSave;

  const TopFiveForm({
    Key? key,
    required this.userId,
    required this.onSave,
  }) : super(key: key);

  @override
  _TopFiveFormState createState() => _TopFiveFormState();
}

class _TopFiveFormState extends State<TopFiveForm> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Default categories
  final List<String> _defaultCategories = [
    'Movies',
    'Books',
    'Musician / Band',
    'Travel Locations'
  ];

  // Custom categories
  List<String> _customCategories = [];

  // Map to store all category controllers
  Map<String, List<TextEditingController>> _categoryControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for default categories
    for (String category in _defaultCategories) {
      _categoryControllers[category] = List.generate(5, (_) => TextEditingController());
    }
    _loadUserData();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _categoryControllers.forEach((_, controllers) {
      controllers.forEach((controller) => controller.dispose());
    });
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> topFive = userData['topFive'] as Map<String, dynamic>;

        // Load default categories
        for (String category in _defaultCategories) {
          String key = _getCategoryKey(category);
          if (topFive.containsKey(key)) {
            _populateControllers(_categoryControllers[category]!, topFive[key]);
          }
        }

        // Load custom categories
        if (topFive.containsKey('customCategories')) {
          setState(() {
            _customCategories = List<String>.from(topFive['customCategories']);

            // Initialize controllers for custom categories
            for (String category in _customCategories) {
              String key = _getCategoryKey(category);
              _categoryControllers[category] = List.generate(5, (_) => TextEditingController());

              if (topFive.containsKey(key)) {
                _populateControllers(_categoryControllers[category]!, topFive[key]);
              }
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Convert category name to storage key (lowercase, no spaces)
  String _getCategoryKey(String category) {
    return category.toLowerCase().replaceAll(' / ', '_').replaceAll(' ', '_');
  }

  void _populateControllers(List<TextEditingController> controllers, List<dynamic> items) {
    for (int i = 0; i < controllers.length; i++) {
      if (i < items.length) {
        controllers[i].text = items[i];
      } else {
        controllers[i].text = '';
      }
    }
  }

  List<String> _getControllerValues(List<TextEditingController> controllers) {
    return controllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  void _addCustomCategory() {
    if (_customCategories.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can add a maximum of 6 custom categories')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController categoryController = TextEditingController();

        return AlertDialog(
          title: Text('Add Custom Category'),
          content: TextField(
            controller: categoryController,
            decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Video Games, Recipes, etc.'
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () {
                String newCategory = categoryController.text.trim();
                if (newCategory.isNotEmpty) {
                  if (_defaultCategories.contains(newCategory) ||
                      _customCategories.contains(newCategory)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('This category already exists')),
                    );
                  } else {
                    setState(() {
                      _customCategories.add(newCategory);
                      _categoryControllers[newCategory] = List.generate(5, (_) => TextEditingController());
                    });
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _removeCustomCategory(String category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove Category'),
          content: Text('Are you sure you want to remove "$category" and all its items?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Remove'),
              onPressed: () {
                setState(() {
                  _customCategories.remove(category);
                  _categoryControllers[category]!.forEach((controller) => controller.dispose());
                  _categoryControllers.remove(category);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTopFive() async {
    setState(() {
      _isSaving = true;
    });

    try {
      Map<String, dynamic> topFiveData = {};

      // Save default categories
      for (String category in _defaultCategories) {
        topFiveData[_getCategoryKey(category)] = _getControllerValues(_categoryControllers[category]!);
      }

      // Save custom categories
      topFiveData['customCategories'] = _customCategories;
      for (String category in _customCategories) {
        topFiveData[_getCategoryKey(category)] = _getControllerValues(_categoryControllers[category]!);
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'topFive': topFiveData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      widget.onSave();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your Top Five list has been published!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Edit Your Top Five Lists',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 20),

        // Default categories
        ..._defaultCategories.map((category) => Column(
          children: [
            _buildCategoryInputs(category, _categoryControllers[category]!),
            SizedBox(height: 30),
          ],
        )).toList(),

        // Custom categories
        ..._customCategories.map((category) => Column(
          children: [
            _buildCategoryInputs(
              category,
              _categoryControllers[category]!,
              isCustom: true,
              onRemove: () => _removeCustomCategory(category),
            ),
            SizedBox(height: 30),
          ],
        )).toList(),

        // Add custom category button
        if (_customCategories.length < 6)
          OutlinedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Add Custom Category'),
            onPressed: _addCustomCategory,
          ),

        SizedBox(height: 20),

        Text(
          'You can add up to ${6 - _customCategories.length} more custom categories',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
          ),
        ),

        SizedBox(height: 40),

        ElevatedButton.icon(
          icon: Icon(Icons.publish),
          label: Text('Publish'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          onPressed: _isSaving ? null : _saveTopFive,
        ),

        if (_isSaving)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildCategoryInputs(
      String title,
      List<TextEditingController> controllers,
      {bool isCustom = false, VoidCallback? onRemove}
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (isCustom && onRemove != null)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: onRemove,
                tooltip: 'Remove this category',
              ),
          ],
        ),
        SizedBox(height: 16),
        ...List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: controllers[index],
              decoration: InputDecoration(
                labelText: '${index + 1}.',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          );
        }),
      ],
    );
  }
}