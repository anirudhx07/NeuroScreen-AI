import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String? userName;

  const HomeScreen({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NeuroScreen'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (userName != null)
              Text(
                'Hello, $userName',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 32),
            Text(
              'You have successfully logged in to NeuroScreen',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
