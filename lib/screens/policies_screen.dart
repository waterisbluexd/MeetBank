import 'package:flutter/material.dart';
import 'package:meetbank/screens/create_policies_screen.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Policies"),
      ),
      body: const Center(
        child: Text("Policies will be listed here."),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePolicyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
