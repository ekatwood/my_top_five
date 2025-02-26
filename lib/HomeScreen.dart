import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AuthService.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to My Top Five',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Share your top five favorites in different categories with the world!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              if (!authService.isLoggedIn) ...[
                ElevatedButton.icon(
                  icon: Image.asset('assets/google_logo.png', height: 24),
                  label: Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    await authService.signInWithGoogle();
                    // After login, navigate to their profile page
                    if (authService.profileId != null) {
                      Navigator.pushNamed(context, '/${authService.profileId}');
                    }
                  },
                ),
              ] else ...[
                Text(
                  'You are signed in as ${authService.user?.displayName}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Go to My Page'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/${authService.profileId}');
                  },
                ),
              ],

              // TODO: Add more app description here

              SizedBox(height: 40),
              Text(
                '© 2023 My Top Five',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}