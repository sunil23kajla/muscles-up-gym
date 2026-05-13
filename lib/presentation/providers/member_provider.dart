import 'package:flutter/material.dart';
import '../../data/models/member_model.dart';
import '../../data/repositories/member_repository.dart';

class MemberProvider extends ChangeNotifier {
  final MemberRepository _memberRepo = MemberRepository();

  List<MemberModel> _members = [];
  List<MemberModel> _expiringSoon = [];
  List<MemberModel> _expiredMembers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MemberModel> get members => _members;
  List<MemberModel> get expiringSoon => _expiringSoon;
  List<MemberModel> get expiredMembers => _expiredMembers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear errors helper
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get active directory index with searching/filtering options
  Future<void> fetchMembers({String? status, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _members = await _memberRepo.getMembers(status: status, search: search);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch expiring and expired members for specific panels
  Future<void> fetchExpiriesAndAlerts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expiringSoon = await _memberRepo.getUpcomingExpiries();
      _expiredMembers = await _memberRepo.getExpiredMembers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get Single Member Details
  Future<MemberModel?> fetchMemberById(String id) async {
    _errorMessage = null;
    try {
      return await _memberRepo.getMemberById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Create new member record
  Future<bool> addMember(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newMember = await _memberRepo.createMember(data);
      _members.insert(0, newMember); // Prepend to list instantly
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update existing member record
  Future<bool> updateMember(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedMember = await _memberRepo.updateMember(id, data);
      
      // Update locally inside directory list
      final idx = _members.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _members[idx] = updatedMember;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete member from system (Admin only)
  Future<bool> deleteMember(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _memberRepo.deleteMember(id);
      _members.removeWhere((m) => m.id == id);
      _expiringSoon.removeWhere((m) => m.id == id);
      _expiredMembers.removeWhere((m) => m.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
