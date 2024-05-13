import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/features/user_auth/presentation/pages/home_page.dart';
import 'package:flutter_firebase/global/common/toast.dart'; // Import your toast utility

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isSigningUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Sign Up"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Sign Up",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _usernameController,
                hintText: "Username",
                isPasswordField: false,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _signUp,
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isSigningUp
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isPasswordField,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPasswordField,
      decoration: InputDecoration(
        hintText: hintText,
      ),
    );
  }

  Future<void> _signUp() async {
    setState(() {
      _isSigningUp = true;
    });

    try {
      final String username = _usernameController.text;
      final String email = _emailController.text;
      final String password = _passwordController.text;

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // Store additional user data in Firestore
        await _firestore.collection("users").doc(user.uid).set({
          "username": username,
          "email": email,
          // Add more fields if needed
        });

        showToast(message: "User successfully created");

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        showToast(message: "Some error occurred");
      }
    } catch (e) {
      print("Error: $e");
      showToast(message: "Error occurred: $e");
    } finally {
      setState(() {
        _isSigningUp = false;
      });
    }
  }
}
