import 'package:flutter/material.dart';
import '../../data/models/inquiry_model.dart';
import '../../data/repositories/website_repository.dart';

class WebsiteProvider extends ChangeNotifier {
  final WebsiteRepository _repo = WebsiteRepository();

  Map<String, dynamic> _stats = {
    'membersTrained': '1,000+',
    'certifiedTrainers': '5+',
    'yearsExp': '4+',
  };

  Map<String, dynamic> _announcement = {
    'show': true,
    'text': '',
  };

  List<String> _gallery = [];
  List<String> _videos = [];
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic> _contact = {
    'address': '',
    'phone': '',
    'email': '',
  };

  List<InquiryModel> _inquiries = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get stats => _stats;
  Map<String, dynamic> get announcement => _announcement;
  List<String> get gallery => _gallery;
  List<String> get videos => _videos;
  List<Map<String, dynamic>> get plans => _plans;
  Map<String, dynamic> get contact => _contact;
  List<InquiryModel> get inquiries => _inquiries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 1. Fetch live website settings
  Future<void> fetchWebsiteConfig() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final config = await _repo.getWebsiteConfig();
      if (config['stats'] != null) {
        _stats = Map<String, dynamic>.from(config['stats']);
      }
      if (config['announcement'] != null) {
        _announcement = Map<String, dynamic>.from(config['announcement']);
      }
      if (config['gallery'] != null) {
        _gallery = List<String>.from(config['gallery']);
      }
      if (config['videos'] != null) {
        _videos = List<String>.from(config['videos']);
      }
      if (config['plans'] != null) {
        _plans = List<Map<String, dynamic>>.from(
          (config['plans'] as List).map((p) => Map<String, dynamic>.from(p))
        );
      }
      if (config['contact'] != null) {
        _contact = Map<String, dynamic>.from(config['contact']);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 1f. Update contact details
  Future<bool> updateContact({
    required String address,
    required String phone,
    required String email,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final newContact = {
        'address': address,
        'phone': phone,
        'email': email,
      };
      await _repo.updateWebsiteSetting('contact', newContact);
      _contact = newContact;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 1g. Add dynamic membership pricing plan
  Future<bool> addPlan(Map<String, dynamic> newPlan) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedPlans = List<Map<String, dynamic>>.from(_plans)..add(newPlan);
      await _repo.updateWebsiteSetting('plans', updatedPlans);
      _plans = updatedPlans;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 1i. Edit dynamic membership pricing plan
  Future<bool> editPlan(int index, Map<String, dynamic> updatedPlan) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedPlans = List<Map<String, dynamic>>.from(_plans);
      updatedPlans[index] = updatedPlan;
      await _repo.updateWebsiteSetting('plans', updatedPlans);
      _plans = updatedPlans;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 1h. Remove membership pricing plan
  Future<bool> removePlan(int index) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedPlans = List<Map<String, dynamic>>.from(_plans)..removeAt(index);
      await _repo.updateWebsiteSetting('plans', updatedPlans);
      _plans = updatedPlans;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 1b. Upload / Add a dynamic Base64 photo to the gallery
  Future<bool> addGalleryImage(String base64Image) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedGallery = List<String>.from(_gallery)..add(base64Image);
      await _repo.updateWebsiteSetting('gallery', updatedGallery);
      _gallery = updatedGallery;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 1c. Remove a dynamic photo from the gallery
  Future<bool> removeGalleryImage(int idx) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedGallery = List<String>.from(_gallery)..removeAt(idx);
      await _repo.updateWebsiteSetting('gallery', updatedGallery);
      _gallery = updatedGallery;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 1d. Add a dynamic YouTube / video clip link
  Future<bool> addVideoLink(String videoLink) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedVideos = List<String>.from(_videos)..add(videoLink);
      await _repo.updateWebsiteSetting('videos', updatedVideos);
      _videos = updatedVideos;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 1e. Remove a dynamic video link
  Future<bool> removeVideoLink(int idx) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedVideos = List<String>.from(_videos)..removeAt(idx);
      await _repo.updateWebsiteSetting('videos', updatedVideos);
      _videos = updatedVideos;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 2. Update website statistics metrics
  Future<bool> updateStats({
    required String membersTrained,
    required String certifiedTrainers,
    required String yearsExp,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final newStats = {
        'membersTrained': membersTrained,
        'certifiedTrainers': certifiedTrainers,
        'yearsExp': yearsExp,
      };
      await _repo.updateWebsiteSetting('stats', newStats);
      _stats = newStats;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 3. Update announcement banner text and visibility
  Future<bool> updateAnnouncement({
    required bool show,
    required String text,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final newAnnouncement = {
        'show': show,
        'text': text,
      };
      await _repo.updateWebsiteSetting('announcement', newAnnouncement);
      _announcement = newAnnouncement;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 4. Fetch website inquiries
  Future<void> fetchInquiries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _inquiries = await _repo.getInquiries();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 5. Update inquiry reviewed status
  Future<bool> changeInquiryStatus(String id, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.updateInquiryStatus(id, status);
      final idx = _inquiries.indexWhere((i) => i.id == id);
      if (idx != -1) {
        final updated = InquiryModel(
          id: _inquiries[idx].id,
          name: _inquiries[idx].name,
          phone: _inquiries[idx].phone,
          packageName: _inquiries[idx].packageName,
          message: _inquiries[idx].message,
          status: status,
          createdAt: _inquiries[idx].createdAt,
        );
        _inquiries[idx] = updated;
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

  // 6. Delete an inquiry from server logs
  Future<bool> removeInquiry(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.deleteInquiry(id);
      _inquiries.removeWhere((i) => i.id == id);
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
