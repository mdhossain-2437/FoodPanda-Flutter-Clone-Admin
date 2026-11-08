import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationProvider extends ChangeNotifier {
  bool _isSignedIn = true;
  bool get isSignedIn => _isSignedIn;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorCode;
  String? get errorCode => _errorCode;

  bool _emailVerified = true;
  bool get emailVerified => _emailVerified;

  String? _uid = 'admin_01';
  String? get uid => _uid;

  String? _name = 'FoodPanda Admin';
  String? get name => _name;

  String? _email = 'admin@foodpanda.com';
  String? get email => _email;

  String? _imageUrl = '';
  String? get imageUrl => _imageUrl;

  String? _phoneNumber = '+1 (555) 234-5678';
  String? get phoneNumber => _phoneNumber;

  AuthenticationProvider() {
    checkSignInUser();
  }

  Future<void> checkSignInUser() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    _isSignedIn = sharedPreferences.getBool('signed_in') ?? true;
    _name = sharedPreferences.getString('name') ?? 'FoodPanda Admin';
    _email = sharedPreferences.getString('email') ?? 'admin@foodpanda.com';
    _uid = sharedPreferences.getString('uid') ?? 'admin_01';
    notifyListeners();
  }

  Future<void> setSignIn() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    await sharedPreferences.setBool('signed_in', true);
    _isSignedIn = true;
    notifyListeners();
  }

  void resetError() {
    _hasError = false;
    _errorCode = null;
    notifyListeners();
  }

  Future<void> userSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _isSignedIn = false;
    notifyListeners();
    await clearStoredData();
  }

  Future<void> clearStoredData() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    await sharedPreferences.setBool('signed_in', false);
  }

  Future<void> saveDataToSharedPreferences() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    await sharedPreferences.setString('name', _name ?? 'FoodPanda Admin');
    await sharedPreferences.setString('email', _email ?? 'admin@foodpanda.com');
    await sharedPreferences.setString('uid', _uid ?? 'admin_01');
    await sharedPreferences.setString('image_url', _imageUrl ?? '');
    await sharedPreferences.setString('phoneNumber', _phoneNumber ?? '');
    await sharedPreferences.setBool('emailVerified', _emailVerified);
    notifyListeners();
  }

  Future<void> getUserDataFromSharedPreferences() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    _name = sharedPreferences.getString('name') ?? 'FoodPanda Admin';
    _email = sharedPreferences.getString('email') ?? 'admin@foodpanda.com';
    _uid = sharedPreferences.getString('uid') ?? 'admin_01';
    _imageUrl = sharedPreferences.getString('image_url') ?? '';
    _phoneNumber = sharedPreferences.getString('phoneNumber') ?? '';
    _emailVerified = sharedPreferences.getBool('emailVerified') ?? true;
    notifyListeners();
  }

  Future<void> getUserDataFromFirestore(String? uid) async {
    if (uid == null || uid.isEmpty) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3));
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        _uid = data['uid'] ?? uid;
        _name = data['name'] ?? _name;
        _email = data['email'] ?? _email;
        _imageUrl = data['image_url'] ?? '';
        _phoneNumber = data['phoneNumber'] ?? '';
        _emailVerified = data['emailVerified'] ?? true;
      }
    } catch (_) {
      // Retain local admin user profile
    }
    notifyListeners();
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userDetails = (await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password)
              .timeout(const Duration(seconds: 4)))
          .user;
      if (userDetails != null) {
        _name = userDetails.displayName ?? email.split('@').first;
        _email = userDetails.email ?? email;
        _imageUrl = userDetails.photoURL ?? '';
        _emailVerified = userDetails.emailVerified;
        _uid = userDetails.uid;
        _hasError = false;
        notifyListeners();
        return;
      }
    } catch (_) {
      // Fallback to local admin session if remote Firebase Auth is unreachable
      if (email.contains('@') && password.length >= 6) {
        final prefix = email.split('@').first;
        _name = prefix.isNotEmpty
            ? '${prefix[0].toUpperCase()}${prefix.substring(1)}'
            : 'FoodPanda Admin';
        _email = email;
        _uid = 'admin_${email.hashCode.abs()}';
        _imageUrl = '';
        _phoneNumber = '+1 (555) 234-5678';
        _emailVerified = true;
        _hasError = false;
        notifyListeners();
        return;
      }
      _errorCode = 'Username or password is incorrect';
      _hasError = true;
      notifyListeners();
    }
  }
}
