import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';

class AuthService {
  static const String _kLoggedUserKey = 'logged_user';
  static const String _webClientId = '821042028276-kqcmc9g468f28gn3u53f91e4e5i5an5j.apps.googleusercontent.com';

  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  SharedPreferences? _preferences;
  UserModel? _currentUser;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    scopes: ['email', 'profile'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    
    // Fallback: check local storage for quick startup
    final storedUser = _preferences?.getString(_kLoggedUserKey);
    if (storedUser != null && storedUser.isNotEmpty) {
      _currentUser = UserModel.fromJson(json.decode(storedUser));
    }
    
    // Listen to Firebase Auth state
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _currentUser = null;
        await _preferences?.remove(_kLoggedUserKey);
      } else {
        // Fetch user from Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          _currentUser = UserModel.fromJson(doc.data()!);
          await _saveCurrentUser();
        }
      }
    });
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  
  void setDummyUserForDevelopment(UserModel user) {
      _currentUser = user;
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? fbUser = userCredential.user;
      
      if (fbUser != null) {
        // Check if user exists in Firestore
        final docRef = _firestore.collection('users').doc(fbUser.uid);
        final doc = await docRef.get();
        
        if (doc.exists && doc.data() != null) {
          _currentUser = UserModel.fromJson(doc.data()!);
        } else {
          // Create new user
          _currentUser = UserModel(
            id: fbUser.uid,
            name: fbUser.displayName ?? 'Google User',
            email: fbUser.email ?? '',
            role: 'member',
            nim: '',
            campusName: '',
          );
          await docRef.set(_currentUser!.toJson());
        }
        await _saveCurrentUser();
        return _currentUser;
      }
    } catch (e) {
      print('Error Google Sign In: $e');
      throw Exception('Error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      // Fallback local dummy accounts for backward compatibility during testing
      if (normalizedEmail == 'admin@organisync.com' && password == 'admin123') {
        _currentUser = UserModel(
          id: 'admin-1',
          name: 'Admin OrganiSync',
          email: normalizedEmail,
          role: 'admin',
          activeOrganizationId: 'demo_org',
        );
        await _saveCurrentUser();
        return true;
      } else if (normalizedEmail == 'mahasiswa@organisync.com' && password == 'user123') {
        _currentUser = UserModel(
          id: 'user-1',
          name: 'Mahasiswa OrganiSync',
          email: normalizedEmail,
          role: 'member',
          activeOrganizationId: 'demo_org',
        );
        await _saveCurrentUser();
        return true;
      }

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final User? fbUser = userCredential.user;
      
      if (fbUser != null) {
        final doc = await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists && doc.data() != null) {
          _currentUser = UserModel.fromJson(doc.data()!);
          await _saveCurrentUser();
          return true;
        }
      }
    } catch (e) {
      print('Error Email Login: $e');
    }
    return false;
  }

  Future<UserModel?> registerUser({
    String? id, // For compatibility
    required String name,
    required String email,
    required String nim,
    required String campusName,
    required String password,
    String? activeOrganizationId,
    String role = 'member',
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final User? fbUser = userCredential.user;
      
      if (fbUser != null) {
        _currentUser = UserModel(
          id: fbUser.uid,
          name: name.trim(),
          email: email.trim().toLowerCase(),
          role: role,
          nim: nim.trim(),
          campusName: campusName.trim(),
          activeOrganizationId: activeOrganizationId,
        );
        await _firestore.collection('users').doc(fbUser.uid).set(_currentUser!.toJson());
        await _saveCurrentUser();
        return _currentUser;
      }
    } catch (e) {
      print('Error Register: $e');
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _currentUser = null;
    await _preferences?.remove(_kLoggedUserKey);
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    if (_currentUser?.id == updatedUser.id) {
      _currentUser = updatedUser;
      await _saveCurrentUser();
    }
    
    // If it's a dummy user, don't attempt to write to Firestore
    if (updatedUser.id == 'admin-1' || updatedUser.id == 'user-1') {
        return;
    }

    try {
      await _firestore.collection('users').doc(updatedUser.id).update(updatedUser.toJson());
    } catch (e) {
      print('Failed to update profile to Firestore: $e');
    }
  }

  Future<void> _saveCurrentUser() async {
    if (_currentUser == null) return;
    final encoded = json.encode(_currentUser!.toJson());
    await _preferences?.setString(_kLoggedUserKey, encoded);
  }

  Future<List<UserModel>> getAllUsersForOrganization(String orgId) async {
    try {
      final snapshot = await _firestore.collection('users').where('activeOrganizationId', isEqualTo: orgId).get();
      return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to get org users: $e');
      return [];
    }
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser == null || _currentUser!.id == 'admin-1' || _currentUser!.id == 'user-1') return;
    try {
      final doc = await _firestore.collection('users').doc(_currentUser!.id).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromJson(doc.data()!);
        await _saveCurrentUser();
      }
    } catch (e) {
      print('Failed to refresh user: $e');
    }
  }
}
