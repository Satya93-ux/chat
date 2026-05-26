import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/services/firebase_service.dart';
import 'package:chat/services/mock_data_service.dart';
import 'package:chat/views/onboarding/onboarding_screen.dart';
import 'package:chat/views/main/main_layout.dart';

class AuthController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final MockDataService _mockDataService = MockDataService();

  final Rxn<UserModel> _currentUser = Rxn<UserModel>();
  final RxBool _isLoading = false.obs;
  final RxBool _isDemoMode = true.obs;
  final RxnString _errorMessage = RxnString();

  UserModel? get currentUser => _currentUser.value;
  bool get isLoading => _isLoading.value;
  bool get isDemoMode => _isDemoMode.value;
  String? get errorMessage => _errorMessage.value;
  bool get isAuthenticated => _currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _initAuth();
  }

  @override
  void onReady() {
    super.onReady();
    // Watch for login/logout changes and steer dynamically
    ever(_currentUser, _steerUser);
  }

  void _steerUser(UserModel? user) {
    if (user == null) {
      Get.offAll(() => const OnboardingScreen());
    } else {
      Get.offAll(() => const MainLayout());
    }
  }

  Future<void> _saveUserLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(user.toMap()));
      await prefs.setBool('is_demo_mode', isDemoMode);
    } catch (e) {
      print("Error saving user locally: $e");
    }
  }

  Future<void> _clearLocalUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user');
      await prefs.remove('is_demo_mode');
    } catch (e) {
      print("Error clearing local user: $e");
    }
  }

  Future<UserModel?> _loadLocalUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('cached_user');
      if (userStr != null) {
        final savedDemoMode = prefs.getBool('is_demo_mode') ?? true;
        _isDemoMode.value = savedDemoMode;
        return UserModel.fromMap(jsonDecode(userStr));
      }
    } catch (e) {
      print("Error loading local user: $e");
    }
    return null;
  }

  Future<void> _initAuth() async {
    _isLoading.value = true;

    // 1. Instantly retrieve and load user profile data from local storage first
    final cachedUser = await _loadLocalUser();
    if (cachedUser != null) {
      _currentUser.value = cachedUser;
      if (isDemoMode) {
        _mockDataService.currentUser = cachedUser;
        _mockDataService.addMockUser(cachedUser);
      }
      _isLoading.value = false;
      _steerUser(cachedUser);

      // Asynchronously initialize Firebase & update newest profile in background
      _initializeFirebaseInBackground();
      return;
    }

    // 2. If no cache, perform standard initial authentication check
    await _firebaseService.initialize();

    if (_firebaseService.isFirebaseConfigured) {
      _isDemoMode.value = false;
      final fbUser = _firebaseService.currentFirebaseUser;
      if (fbUser != null) {
        final details = await _firebaseService.getUserDetails(fbUser.uid);
        if (details != null) {
          _currentUser.value = details;
          await _saveUserLocally(details);
        } else {
          // Robust defensive fallback
          final fallbackUser = UserModel(
            uid: fbUser.uid,
            name:
                fbUser.displayName ??
                fbUser.email?.split('@')[0].toUpperCase() ??
                'USER',
            email: fbUser.email ?? '',
            photoUrl: fbUser.photoURL ?? '',
            isOnline: true,
            lastSeen: DateTime.now(),
          );
          _currentUser.value = fallbackUser;
          await _saveUserLocally(fallbackUser);
        }
      } else {
        _currentUser.value = null;
      }
    } else {
      _isDemoMode.value = true;
      _currentUser.value = null;
    }

    _isLoading.value = false;

    // Initial bootup steering
    _steerUser(_currentUser.value);
  }

  Future<void> _initializeFirebaseInBackground() async {
    try {
      await _firebaseService.initialize();
      if (_firebaseService.isFirebaseConfigured) {
        _isDemoMode.value = false;
        final fbUser = _firebaseService.currentFirebaseUser;
        if (fbUser != null) {
          final details = await _firebaseService.getUserDetails(fbUser.uid);
          if (details != null) {
            _currentUser.value = details;
            await _saveUserLocally(details);
          }
        }
      }
    } catch (e) {
      print("Background database initialization: $e");
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      if (isDemoMode) {
        await Future.delayed(const Duration(milliseconds: 1500));

        final user = UserModel(
          uid: _mockDataService.currentUser.uid,
          name: email.split('@')[0].toUpperCase(),
          email: email,
          photoUrl: _mockDataService.currentUser.photoUrl,
          bio: _mockDataService.currentUser.bio,
          isOnline: true,
          lastSeen: DateTime.now(),
        );
        _currentUser.value = user;
        _mockDataService.currentUser = user;
        _mockDataService.addMockUser(user);
        await _saveUserLocally(user);

        _isLoading.value = false;
        return true;
      } else {
        final credential = await _firebaseService.signIn(email, password);
        if (credential != null && credential.user != null) {
          final fbUser = credential.user!;
          final details = await _firebaseService.getUserDetails(fbUser.uid);
          UserModel activeUser;
          if (details != null) {
            activeUser = details;
          } else {
            // Robust defensive fallback
            activeUser = UserModel(
              uid: fbUser.uid,
              name:
                  fbUser.displayName ??
                  fbUser.email?.split('@')[0].toUpperCase() ??
                  'USER',
              email: fbUser.email ?? '',
              photoUrl: fbUser.photoURL ?? '',
              isOnline: true,
              lastSeen: DateTime.now(),
            );
          }
          _currentUser.value = activeUser;
          await _saveUserLocally(activeUser);
          _isLoading.value = false;
          return true;
        }
      }
    } catch (e) {
      _errorMessage.value = e.toString().replaceFirst(RegExp(r'\[.*\]\s*'), '');
    }

    _isLoading.value = false;
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? localImagePath,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      if (isDemoMode) {
        await Future.delayed(const Duration(milliseconds: 1500));

        final user = UserModel(
          uid: "demo_user_${DateTime.now().millisecondsSinceEpoch}",
          name: name,
          email: email,
          photoUrl:
              localImagePath ??
              "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
          bio: "Hey there! I am using this premium chat app.",
          isOnline: true,
          lastSeen: DateTime.now(),
        );
        _currentUser.value = user;
        _mockDataService.currentUser = user;
        _mockDataService.addMockUser(user);
        await _saveUserLocally(user);

        // Dynamically add a few starter contacts
        _seedDemoContacts();

        _isLoading.value = false;
        return true;
      } else {
        final credential = await _firebaseService.signUp(email, password, name);
        if (credential != null && credential.user != null) {
          String photoUrl = '';
          if (localImagePath != null && localImagePath.isNotEmpty) {
            final file = File(localImagePath);
            final path = 'profiles/${credential.user!.uid}.jpg';
            try {
              photoUrl = await _firebaseService.uploadImage(file, path);
            } catch (e) {
              print("Register image upload skipped: $e");
            }
          }
          final updatedUser = UserModel(
            uid: credential.user!.uid,
            name: name,
            email: email,
            photoUrl: photoUrl,
            lastSeen: DateTime.now(),
            isOnline: true,
          );
          try {
            await _firebaseService.updateUserProfile(updatedUser);
          } catch (e) {
            print("Register Firestore document write skipped: $e");
          }
          _currentUser.value = updatedUser;
          await _saveUserLocally(updatedUser);
          _isLoading.value = false;
          return true;
        }
      }
    } catch (e) {
      _errorMessage.value = e.toString().replaceFirst(RegExp(r'\[.*\]\s*'), '');
    }

    _isLoading.value = false;
    return false;
  }

  Future<bool> resetPassword(String email) async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      if (isDemoMode) {
        await Future.delayed(const Duration(milliseconds: 1000));
        _isLoading.value = false;
        return true;
      } else {
        await _firebaseService.sendPasswordResetEmail(email);
        _isLoading.value = false;
        return true;
      }
    } catch (e) {
      _errorMessage.value = e.toString().replaceFirst(RegExp(r'\[.*\]\s*'), '');
    }

    _isLoading.value = false;
    return false;
  }

  Future<void> updateBio(String newBio) async {
    if (_currentUser.value == null) return;

    _currentUser.value = _currentUser.value!.copyWith(bio: newBio);
    await _saveUserLocally(_currentUser.value!);

    if (!isDemoMode) {
      await _firebaseService.updateBio(_currentUser.value!.uid, newBio);
    } else {
      _mockDataService.currentUser = _currentUser.value!;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String bio,
    String? localImagePath,
  }) async {
    if (_currentUser.value == null) return false;

    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      String photoUrl = _currentUser.value!.photoUrl;

      if (localImagePath != null && localImagePath.isNotEmpty) {
        if (!isDemoMode) {
          final file = File(localImagePath);
          final path =
              'profiles/${_currentUser.value!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          photoUrl = await _firebaseService.uploadImage(file, path);
        } else {
          photoUrl = localImagePath;
        }
      }

      final updatedUser = _currentUser.value!.copyWith(
        name: name,
        bio: bio,
        photoUrl: photoUrl,
      );

      _currentUser.value = updatedUser;
      await _saveUserLocally(updatedUser);

      if (!isDemoMode) {
        await _firebaseService.updateUserProfile(updatedUser);
      } else {
        _mockDataService.currentUser = updatedUser;
        final idx = _mockDataService.mockUsers.indexWhere(
          (u) => u.uid == updatedUser.uid,
        );
        if (idx != -1) {
          _mockDataService.mockUsers[idx] = updatedUser;
        }
      }

      _isLoading.value = false;
      return true;
    } catch (e) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading.value = true;

    if (!isDemoMode) {
      await _firebaseService.signOut();
    }

    await _clearLocalUser();
    _currentUser.value = null;
    _isLoading.value = false;
  }

  void startDemoMode() {
    _currentUser.value = _mockDataService.currentUser;
    _mockDataService.addMockUser(_mockDataService.currentUser);
    _seedDemoContacts();
  }

  void _seedDemoContacts() {
    _mockDataService.addMockUser(
      UserModel(
        uid: "dynamic_zara",
        name: "Zara Carter",
        email: "zara@example.com",
        photoUrl:
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
        bio: "Designing the future, one screen at a time. 🎨",
        isOnline: true,
        lastSeen: DateTime.now(),
      ),
    );
    _mockDataService.addMockUser(
      UserModel(
        uid: "dynamic_sophia",
        name: "Sophia Vance",
        email: "sophia@example.com",
        photoUrl:
            "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150",
        bio: "Let's explore the world together. ✈️🌍",
        isOnline: true,
        lastSeen: DateTime.now(),
      ),
    );
    _mockDataService.addMockUser(
      UserModel(
        uid: "dynamic_marcus",
        name: "Marcus Chen",
        email: "marcus@example.com",
        photoUrl:
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
        bio: "Build, deploy, repeat. 🚀",
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    );
  }
}
