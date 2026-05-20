import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Register Page Widget
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  // Controllers to get input from text fields
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

// Variable to handle loading state and error message
  bool isLoading = false;
  String error = '';

  // Function to register a new user
  Future<void> register() async {

    // Start loading and clear previous error
    setState(() {
      isLoading = true;
      error = '';
    });

    try {

       // Create new user account using Firebase Authentication
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

   // Get the registered user
      final user = credential.user;

   // Save additional user data into Firestore database
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'monthlyBudget': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

// Update display name in Firebase Authentication
      await credential.user?.updateDisplayName(nameController.text.trim());

// Navigate back if widget is still mounted
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {

      // Display Firebase authentication error message
      setState(() {
        error = e.message ?? 'Registration failed';
      });
    }

// Stop loading after process finishes
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // App bar section
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [

              // Full Name Input Field
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),

              const SizedBox(height: 16),

          // Email Input Field
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              const SizedBox(height: 16),

// Password Input Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),

              const SizedBox(height: 12),

// Display error message if registration fails
              if (error.isNotEmpty)
                Text(error, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 24),

// Sign Up Button
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
