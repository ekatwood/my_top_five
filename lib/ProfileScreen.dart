import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AuthService.dart';
import 'TopFiveForm.dart';
import 'TopFiveDisplay.dart';

class ProfileScreen extends StatefulWidget {
  final String profileId;

  const ProfileScreen({Key? key, required this.profileId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUserIdFromProfileId();
  }

  Future<void> _fetchUserIdFromProfileId() async {
    try {
      // Query Firestore to find the user ID that matches this profile ID
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('profileId', isEqualTo: widget.profileId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _userId = querySnapshot.docs.first.id;
        });
      }
    } catch (e) {
      print('Error fetching user ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool isOwner = authService.isProfileOwner(widget.profileId);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Top Five'),
        actions: [
          if (authService.isLoggedIn)
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () => authService.signOut(),
            )
        ],
      ),
      body: _userId == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                'My Top Five',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Show either the form or the display
              if (_isEditing)
                TopFiveForm(
                  userId: _userId!,
                  onSave: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                )
              else
                TopFiveDisplay(userId: _userId!),

              SizedBox(height: 30),

              // Edit button for owner
              if (isOwner && !_isEditing)
                ElevatedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text('Edit Form'),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}