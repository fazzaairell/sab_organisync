import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_model.dart';
import '../models/aspiration_model.dart';
import '../models/finance_transaction_model.dart';
import '../models/schedule_model.dart';
import '../models/announcement_model.dart';
import '../models/inventory_model.dart';
import 'auth_service.dart';

class DataService extends ChangeNotifier {
  DataService._privateConstructor();

  static final DataService instance = DataService._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FinanceTransactionModel> _transactions = [];
  List<ScheduleModel> _schedules = [];
  List<ActivityModel> _activities = [];
  List<AspirationModel> _aspirations = [];
  List<AnnouncementModel> _announcements = [];
  List<InventoryModel> _inventories = [];

  StreamSubscription? _transactionsSub;
  StreamSubscription? _schedulesSub;
  StreamSubscription? _activitiesSub;
  StreamSubscription? _aspirationsSub;
  StreamSubscription? _announcementsSub;
  StreamSubscription? _inventoriesSub;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await refreshData();
    _initialized = true;
  }

  Future<void> refreshData() async {
    final orgId = activeOrganizationId;
    _cancelListeners();
    if (orgId == null) {
      _clearData();
      return;
    }
    
    // Initial fetch to make sure synchronous getters have data immediately
    try {
      final transSnap = await _firestore.collection('transactions').where('organizationId', isEqualTo: orgId).get();
      _transactions = transSnap.docs.map((d) => FinanceTransactionModel.fromJson(d.data())).toList();

      final schedSnap = await _firestore.collection('schedules').where('organizationId', isEqualTo: orgId).get();
      _schedules = schedSnap.docs.map((d) => ScheduleModel.fromJson(d.data())).toList();

      final actSnap = await _firestore.collection('activities').where('organizationId', isEqualTo: orgId).get();
      _activities = actSnap.docs.map((d) => ActivityModel.fromJson(d.data())).toList();

      final aspSnap = await _firestore.collection('aspirations').where('organizationId', isEqualTo: orgId).get();
      _aspirations = aspSnap.docs.map((d) => AspirationModel.fromJson(d.data())).toList();

      final annSnap = await _firestore.collection('announcements').where('organizationId', isEqualTo: orgId).get();
      _announcements = annSnap.docs.map((d) => AnnouncementModel.fromJson(d.data())).toList();
      
      final invSnap = await _firestore.collection('inventories').where('organizationId', isEqualTo: orgId).get();
      _inventories = invSnap.docs.map((d) => InventoryModel.fromJson(d.data())).toList();
    } catch (e) {
      print('Initial fetch failed: $e');
    }

    _setupListeners(orgId);
    notifyListeners();
  }
  
  void _clearData() {
    _transactions.clear();
    _schedules.clear();
    _activities.clear();
    _aspirations.clear();
    _announcements.clear();
    _inventories.clear();
    notifyListeners();
  }
  
  void _cancelListeners() {
    _transactionsSub?.cancel();
    _schedulesSub?.cancel();
    _activitiesSub?.cancel();
    _aspirationsSub?.cancel();
    _announcementsSub?.cancel();
    _inventoriesSub?.cancel();
  }

  void _setupListeners(String orgId) {
    _transactionsSub = _firestore.collection('transactions').where('organizationId', isEqualTo: orgId).snapshots().listen((snap) {
      _transactions = snap.docs.map((d) => FinanceTransactionModel.fromJson(d.data())).toList();
      notifyListeners();
    });
    
    _schedulesSub = _firestore.collection('schedules').where('organizationId', isEqualTo: orgId).snapshots().listen((snap) {
      _schedules = snap.docs.map((d) => ScheduleModel.fromJson(d.data())).toList();
      notifyListeners();
    });

    _activitiesSub = _firestore.collection('activities').where('organizationId', isEqualTo: orgId).snapshots().listen((snap) {
      _activities = snap.docs.map((d) => ActivityModel.fromJson(d.data())).toList();
      notifyListeners();
    });

    _aspirationsSub = _firestore.collection('aspirations').where('organizationId', isEqualTo: orgId).snapshots().listen((snap) {
      _aspirations = snap.docs.map((d) => AspirationModel.fromJson(d.data())).toList();
      notifyListeners();
    });

    _announcementsSub = _firestore.collection('announcements').where('organizationId', isEqualTo: orgId).snapshots().listen((snap) {
      _announcements = snap.docs.map((d) => AnnouncementModel.fromJson(d.data())).toList();
      notifyListeners();
    });

    _inventoriesSub = _firestore.collection('inventories').where('organizationId', isEqualTo: orgId).snapshots().listen((snap) {
      _inventories = snap.docs.map((d) => InventoryModel.fromJson(d.data())).toList();
      notifyListeners();
    });
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  String? get activeOrganizationId => AuthService.instance.currentUser?.activeOrganizationId;

  String get _monthlyReportNamespace => activeOrganizationId ?? 'unassigned';

  List<FinanceTransactionModel> getFinanceTransactions() {
      var sorted = List<FinanceTransactionModel>.from(_transactions);
      return sorted;
  }
  
  List<ScheduleModel> getSchedules() {
      return List<ScheduleModel>.from(_schedules);
  }
  
  List<ActivityModel> getActivities() {
      return List<ActivityModel>.from(_activities);
  }
  
  List<AspirationModel> getAspirations() {
      return List<AspirationModel>.from(_aspirations);
  }
  
  List<AnnouncementModel> getAnnouncements() {
      return List<AnnouncementModel>.from(_announcements);
  }
  
  List<InventoryModel> getInventories() {
      return List<InventoryModel>.from(_inventories);
  }

  Future<void> addFinanceTransaction(FinanceTransactionModel entry) async {
    final transaction = entry.copyWith(
      id: _generateId(),
      organizationId: entry.organizationId ?? activeOrganizationId,
    );
    await _firestore.collection('transactions').doc(transaction.id).set(transaction.toJson());
  }

  Future<void> updateFinanceTransaction(FinanceTransactionModel updated) async {
    await _firestore.collection('transactions').doc(updated.id).update(updated.toJson());
  }

  Future<void> deleteFinanceTransaction(String id) async {
    await _firestore.collection('transactions').doc(id).delete();
  }

  Future<void> addSchedule(ScheduleModel entry) async {
    final schedule = entry.copyWith(
      id: _generateId(),
      organizationId: entry.organizationId ?? activeOrganizationId,
    );
    await _firestore.collection('schedules').doc(schedule.id).set(schedule.toJson());
  }

  Future<void> updateSchedule(ScheduleModel updated) async {
    await _firestore.collection('schedules').doc(updated.id).update(updated.toJson());
  }

  Future<void> deleteSchedule(String id) async {
    await _firestore.collection('schedules').doc(id).delete();
  }

  Future<void> addActivity(ActivityModel entry) async {
    final activity = entry.copyWith(
      id: _generateId(),
      organizationId: entry.organizationId ?? activeOrganizationId,
    );
    await _firestore.collection('activities').doc(activity.id).set(activity.toJson());
  }

  Future<void> updateActivity(ActivityModel updated) async {
    await _firestore.collection('activities').doc(updated.id).update(updated.toJson());
  }

  Future<void> deleteActivity(String id) async {
    await _firestore.collection('activities').doc(id).delete();
  }

  Future<void> addAspiration(AspirationModel entry) async {
    final aspiration = entry.copyWith(
      id: _generateId(),
      organizationId: entry.organizationId ?? activeOrganizationId,
    );
    await _firestore.collection('aspirations').doc(aspiration.id).set(aspiration.toJson());
  }

  Future<void> updateAspiration(AspirationModel updated) async {
    await _firestore.collection('aspirations').doc(updated.id).update(updated.toJson());
  }

  Future<void> deleteAspiration(String id) async {
    await _firestore.collection('aspirations').doc(id).delete();
  }

  Map<String, dynamic> getMonthlySummary() {
    final transactions = getFinanceTransactions();
    final schedules = getSchedules();
    final activities = getActivities();
    final aspirations = getAspirations();

    final totalIn = transactions
        .where((entry) => entry.isIncome)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final totalOut = transactions
        .where((entry) => !entry.isIncome)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final balance = totalIn - totalOut;
    final upcomingSchedules = schedules.length;
    final activityCount = activities.length;
    final pendingAspirations =
        aspirations.where((entry) => entry.status == 'Menunggu').length;

    return {
      'totalIncome': totalIn,
      'totalExpense': totalOut,
      'balance': balance,
      'upcomingSchedules': upcomingSchedules,
      'activityCount': activityCount,
      'pendingAspirations': pendingAspirations,
    };
  }

  bool _matchesMonthYear(String rawDate, int month, int year) {
    final parsedDate = _parseIndonesianDate(rawDate);
    return parsedDate != null && parsedDate.month == month && parsedDate.year == year;
  }

  DateTime? _parseIndonesianDate(String rawDate) {
    final cleaned = rawDate.toLowerCase();
    final match = RegExp(r'(\d{1,2})\s+([a-z]+)\s+(\d{4})').firstMatch(cleaned);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final monthName = match.group(2)!;
    final year = int.tryParse(match.group(3)!);
    if (day == null || year == null) return null;
    final month = _monthNames[monthName];
    if (month == null) return null;
    return DateTime(year, month, day);
  }

  static const Map<String, int> _monthNames = {
    'januari': 1,
    'februari': 2,
    'maret': 3,
    'april': 4,
    'mei': 5,
    'juni': 6,
    'juli': 7,
    'agustus': 8,
    'september': 9,
    'oktober': 10,
    'november': 11,
    'desember': 12,
  };

  Map<String, dynamic> getMonthlyReportData(int month, int year) {
    final monthTransactions = getFinanceTransactions().where((item) => _matchesMonthYear(item.date, month, year));
    final monthSchedules = getSchedules().where((item) => _matchesMonthYear(item.date, month, year));
    final monthAspirations = getAspirations().where((item) => _matchesMonthYear(item.date, month, year));

    final totalInMonth = monthTransactions
        .where((entry) => entry.isIncome)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final totalOutMonth = monthTransactions
        .where((entry) => !entry.isIncome)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final balanceMonth = totalInMonth - totalOutMonth;

    return {
      'totalIncome': totalInMonth,
      'totalExpense': totalOutMonth,
      'balance': balanceMonth,
      'activityCount': monthSchedules.length,
      'aspirationTotal': monthAspirations.length,
      'aspirationWaiting': monthAspirations.where((item) => item.status == 'Menunggu').length,
      'aspirationProcessing': monthAspirations.where((item) => item.status == 'Diproses').length,
      'aspirationReplied': monthAspirations.where((item) => item.status == 'Dibalas').length,
    };
  }

  String _monthlyReportKey(int month, int year) =>
      'organisync_monthly_report_closed_${_monthlyReportNamespace}_$year-$month';

  Future<bool> isMonthlyReportClosed(int month, int year) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_monthlyReportKey(month, year)) ?? false;
  }

  Future<void> setMonthlyReportClosed(int month, int year, bool closed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_monthlyReportKey(month, year), closed);
  }

  Future<void> addAnnouncement(AnnouncementModel entry) async {
    final announcement = entry.copyWith(
      id: _generateId(),
      organizationId: entry.organizationId ?? activeOrganizationId,
    );
    await _firestore.collection('announcements').doc(announcement.id).set(announcement.toJson());
  }

  Future<void> updateAnnouncement(AnnouncementModel updated) async {
    await _firestore.collection('announcements').doc(updated.id).update(updated.toJson());
  }

  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
  }

  Future<void> addInventory(InventoryModel entry) async {
    final inventory = entry.copyWith(
      id: _generateId(),
      organizationId: entry.organizationId.isEmpty ? (activeOrganizationId ?? '') : entry.organizationId,
    );
    await _firestore.collection('inventories').doc(inventory.id).set(inventory.toJson());
  }

  Future<void> updateInventory(InventoryModel updated) async {
    await _firestore.collection('inventories').doc(updated.id).update(updated.toJson());
  }

  Future<void> deleteInventory(String id) async {
    await _firestore.collection('inventories').doc(id).delete();
  }
}
