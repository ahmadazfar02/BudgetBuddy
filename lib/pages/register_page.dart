import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String error = '';

  Future<void> register() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      final user = credential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'monthlyBudget': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await credential.user?.updateDisplayName(nameController.text.trim());

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message ?? 'Registration failed';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),

              const SizedBox(height: 12),

              if (error.isNotEmpty)
                Text(error, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isLoading ? null : register,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
