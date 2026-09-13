import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('You', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('A few calm settings for the things you want remembered.'),
      const SizedBox(height: 24),
      Card(
        child: ListTile(
          leading: const Icon(Icons.notifications_none),
          title: const Text('Reminders'),
          subtitle: const Text('Permission, local nudges, and test delivery'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/reminders'),
        ),
      ),
    ],
  );
}
