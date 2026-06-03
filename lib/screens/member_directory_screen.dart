import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/mobile_app_wrapper.dart';
import '../widgets/section_title.dart';

class MemberDirectoryScreen extends StatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  List<UserModel> _allMembers = [];
  List<UserModel> _filteredMembers = [];
  String _searchQuery = '';
  String _selectedRole = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final orgId = DataService.instance.activeOrganizationId;
    if (orgId == null) return;
    
    final list = await AuthService.instance.getAllUsersForOrganization(orgId);
    if (!mounted) return;
    setState(() {
      _allMembers = list;
      _filterMembers();
    });
  }

  void _filterMembers() {
    List<UserModel> result = _allMembers;

    // Search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((user) {
        final nameMatch = user.name.toLowerCase().contains(query);
        final nimMatch = user.nim != null && user.nim!.contains(query);
        return nameMatch || nimMatch;
      }).toList();
    }

    // Role filter
    if (_selectedRole != 'Semua') {
      result = result.where((user) {
        final role = user.role.toLowerCase();
        if (_selectedRole == 'Admin') {
          return role == 'admin' || role == 'super_admin';
        } else if (_selectedRole == 'Pengurus') {
          return role == 'organization_manager' || role == 'org_manager' || role == 'organization_owner';
        } else if (_selectedRole == 'Anggota') {
          return role == 'member' || role == 'user';
        }
        return true;
      }).toList();
    }

    setState(() {
      _filteredMembers = result;
    });
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'super_admin':
        return 'Admin Aplikasi';
      case 'organization_owner':
        return 'Ketua Organisasi';
      case 'organization_manager':
      case 'org_manager':
        return 'Pengurus Organisasi';
      case 'member':
      case 'user':
      default:
        return 'Anggota';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'super_admin':
        return Colors.red;
      case 'organization_owner':
        return Colors.orange;
      case 'organization_manager':
      case 'org_manager':
        return Colors.blue;
      case 'member':
      case 'user':
      default:
        return const Color(0xFF6C3CBC);
    }
  }

  void _showMemberDetailBottomSheet(UserModel member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF6C3CBC).withOpacity(0.1),
              backgroundImage: member.profileImagePath != null && member.profileImagePath!.isNotEmpty
                  ? (member.profileImagePath!.startsWith('http')
                      ? NetworkImage(member.profileImagePath!)
                      : FileImage(File(member.profileImagePath!)) as ImageProvider)
                  : null,
              child: member.profileImagePath == null || member.profileImagePath!.isEmpty
                  ? Text(
                      member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6C3CBC),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              member.name,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _getRoleColor(member.role).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getRoleLabel(member.role).toUpperCase(),
                style: GoogleFonts.poppins(
                  color: _getRoleColor(member.role),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 32),
            _buildDetailTile(Icons.badge_outlined, 'NIM / ID Anggota', member.nim ?? '-'),
            const SizedBox(height: 12),
            _buildDetailTile(Icons.school_outlined, 'Universitas / Kampus', member.campusName ?? '-'),
            const SizedBox(height: 12),
            _buildDetailTile(Icons.email_outlined, 'Alamat Email', member.email),
            const SizedBox(height: 24),
            Builder(
              builder: (context) {
                final currentUserRole = AuthService.instance.currentUser?.role ?? '';
                final isCurrentUserOwner = currentUserRole == 'organization_owner';
                final isCurrentUserManager = currentUserRole == 'organization_manager' || currentUserRole == 'org_manager';
                
                final isTargetOwner = member.role == 'organization_owner';
                final isTargetManager = member.role == 'organization_manager' || member.role == 'org_manager';
                
                bool canEditRole = false;
                if (member.id != AuthService.instance.currentUser?.id) {
                  if (isCurrentUserOwner) {
                    canEditRole = true;
                  } else if (isCurrentUserManager) {
                    if (!isTargetOwner && !isTargetManager) {
                      canEditRole = true;
                    }
                  }
                }

                if (!canEditRole) return const SizedBox.shrink();

                List<DropdownMenuItem<String>> roleItems = [
                  const DropdownMenuItem(value: 'organization_member', child: Text('Anggota')),
                  const DropdownMenuItem(value: 'organization_manager', child: Text('Pengurus')),
                ];
                if (isCurrentUserOwner) {
                  roleItems.add(const DropdownMenuItem(value: 'organization_owner', child: Text('Ketua Organisasi')));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 32),
                    Text(
                      'Atur Peran Anggota',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['organization_member', 'organization_manager', 'organization_owner', 'org_manager'].contains(member.role)
                          ? (member.role == 'org_manager' ? 'organization_manager' : member.role)
                          : 'organization_member',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: roleItems,
                      onChanged: (newRole) async {
                        if (newRole != null && newRole != member.role) {
                          final updatedMember = member.copyWith(role: newRole);
                          await AuthService.instance.updateProfile(updatedMember);
                          if (context.mounted) {
                            Navigator.pop(context);
                            _loadMembers();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Peran berhasil diubah', style: GoogleFonts.poppins())),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String val) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C3CBC), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                val,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: MobileAppWrapper(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C3CBC), Color(0xFF9B59B6)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Direktori Anggota',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Text(
                      'Daftar dan informasi seluruh anggota organisasi',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _filterMembers();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIM anggota...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6C3CBC)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Semua', 'Admin', 'Pengurus', 'Anggota'].map((role) {
                  final isSelected = _selectedRole == role;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(role),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedRole = role;
                            _filterMembers();
                          });
                        }
                      },
                      selectedColor: const Color(0xFF6C3CBC),
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            const SectionTitle(title: 'Daftar Anggota'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Anggota tidak ditemukan.',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredMembers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          final roleLabel = _getRoleLabel(member.role);
                          final roleColor = _getRoleColor(member.role);

                          return InkWell(
                            onTap: () => _showMemberDetailBottomSheet(member),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF6C3CBC).withOpacity(0.1),
                                    backgroundImage: member.profileImagePath != null && member.profileImagePath!.isNotEmpty
                                        ? (member.profileImagePath!.startsWith('http')
                                            ? NetworkImage(member.profileImagePath!)
                                            : FileImage(File(member.profileImagePath!)) as ImageProvider)
                                        : null,
                                    child: member.profileImagePath == null || member.profileImagePath!.isEmpty
                                        ? Text(
                                            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF6C3CBC),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.name,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          member.nim ?? 'Tanpa NIM',
                                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: roleColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      roleLabel,
                                      style: GoogleFonts.poppins(
                                        color: roleColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
