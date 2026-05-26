import 'package:get/get.dart';
import 'package:chat/controllers/auth_controller.dart';
import 'package:chat/controllers/chat_controller.dart';
import 'package:chat/controllers/theme_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: permanentBindingForAuth);
    Get.put<ChatController>(ChatController(), permanent: true);
  }

  // Helper boolean to keep syntax clean
  static const bool permanentBindingForAuth = true;
}
