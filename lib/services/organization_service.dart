import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/membership_model.dart';
import '../models/organization_model.dart';

class OrganizationService {
  OrganizationService._internal();
  static final OrganizationService instance = OrganizationService._internal();

  static const String _kActiveOrgPrefix = 'organisync_active_organization_';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    // No local lists needed if we fetch from Firestore
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String> _generateUniqueOrganizationCode() async {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    while (true) {
      final code = List.generate(6, (_) => characters[random.nextInt(characters.length)]).join();
      final snapshot = await _firestore.collection('organizations').where('code', isEqualTo: code).get();
      if (snapshot.docs.isEmpty) {
        return code;
      }
    }
  }

  Future<OrganizationModel> createOrganization({
    required String name,
    required String campusName,
    required String description,
    required String ownerId,
    String ownerRole = 'org_manager',
  }) async {
    final code = await _generateUniqueOrganizationCode();
    final organization = OrganizationModel(
      id: _generateId(),
      name: name.trim(),
      campusName: campusName.trim(),
      description: description.trim(),
      ownerId: ownerId,
      code: code,
      createdAt: DateTime.now(),
    );
    
    // Save to Firestore
    await _firestore.collection('organizations').doc(organization.id).set(organization.toJson());
    
    // Create membership
    await createMembership(userId: ownerId, organizationId: organization.id, role: ownerRole);
    return organization;
  }

  Future<void> updateOrganization(OrganizationModel updated) async {
    await _firestore.collection('organizations').doc(updated.id).update(updated.toJson());
  }

  Future<List<OrganizationModel>> getOrganizations() async {
    try {
      final snapshot = await _firestore.collection('organizations').get();
      return snapshot.docs.map((doc) => OrganizationModel.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to get orgs: $e');
      return [];
    }
  }

  Future<OrganizationModel?> getOrganizationByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    try {
      final snapshot = await _firestore.collection('organizations').where('code', isEqualTo: normalized).get();
      if (snapshot.docs.isNotEmpty) {
        return OrganizationModel.fromJson(snapshot.docs.first.data());
      }
    } catch (e) {
      print('Failed to get org by code: $e');
    }
    return null;
  }

  Future<OrganizationModel?> getOrganizationById(String orgId) async {
    try {
      final doc = await _firestore.collection('organizations').doc(orgId).get();
      if (doc.exists && doc.data() != null) {
        return OrganizationModel.fromJson(doc.data()!);
      }
    } catch (e) {
      print('Failed to get org by id: $e');
    }
    return null;
  }

  Future<MembershipModel> createMembership({
    required String userId,
    required String organizationId,
    required String role,
  }) async {
    // Check if membership already exists
    final snapshot = await _firestore.collection('memberships')
        .where('userId', isEqualTo: userId)
        .where('organizationId', isEqualTo: organizationId)
        .get();
        
    if (snapshot.docs.isNotEmpty) {
      return MembershipModel.fromJson(snapshot.docs.first.data());
    }

    final membership = MembershipModel(
      id: _generateId(),
      userId: userId,
      organizationId: organizationId,
      role: role.trim().toLowerCase(),
      joinedAt: DateTime.now(),
    );
    
    await _firestore.collection('memberships').doc(membership.id).set(membership.toJson());
    return membership;
  }

  Future<List<MembershipModel>> getMembershipsByUserId(String userId) async {
    try {
      final snapshot = await _firestore.collection('memberships').where('userId', isEqualTo: userId).get();
      return snapshot.docs.map((doc) => MembershipModel.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to get memberships: $e');
      return [];
    }
  }

  Future<OrganizationModel?> getActiveOrganizationForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kActiveOrgPrefix$userId';
    final orgId = prefs.getString(key);
    
    // Fallback demo active org
    if ((userId == 'admin-1' || userId == 'user-1') && (orgId == null || orgId.isEmpty)) {
        return OrganizationModel(
          id: 'demo_org',
          name: 'BEM Universitas',
          campusName: 'Universitas Negeri Surabaya',
          description: 'Badan Eksekutif Mahasiswa',
          ownerId: 'admin-1',
          code: 'DEMO01',
          createdAt: DateTime.now(),
        );
    }

    if (orgId == null || orgId.isEmpty) {
      return null;
    }
    return await getOrganizationById(orgId);
  }

  Future<void> setActiveOrganizationForUser(String userId, String? organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kActiveOrgPrefix$userId';
    if (organizationId == null || organizationId.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, organizationId);
  }
}
