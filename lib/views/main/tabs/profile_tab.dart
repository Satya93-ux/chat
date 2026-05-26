import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat/controllers/auth_controller.dart';
import 'package:chat/controllers/theme_controller.dart';
import 'package:image_picker/image_picker.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _showEditProfileSheet(BuildContext context, AuthController authController) {
    final bioController = TextEditingController(text: authController.currentUser?.bio);
    final nameController = TextEditingController(text: authController.currentUser?.name);
    final formKey = GlobalKey<FormState>();
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            final theme = Theme.of(context);
            
            Future<void> pickImage() async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (picked != null) {
                  setStateBottomSheet(() {
                    selectedImagePath = picked.path;
                  });
                }
              } catch (e) {
                Get.snackbar("Error", "Could not pick image: $e");
              }
            }

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Edit Profile Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Image Selector
                    Center(
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                                image: selectedImagePath != null
                                    ? DecorationImage(
                                        image: FileImage(File(selectedImagePath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : (authController.currentUser?.photoUrl != null && authController.currentUser!.photoUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(authController.currentUser!.photoUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: selectedImagePath == null && (authController.currentUser?.photoUrl == null || authController.currentUser!.photoUrl.isEmpty)
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 48,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.colorScheme.surface, width: 2),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Name field
                    TextFormField(
                      controller: nameController,
                      validator: (value) => value == null || value.trim().isEmpty ? "Name cannot be empty" : null,
                      decoration: const InputDecoration(
                        labelText: "Display Name",
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Bio field
                    TextFormField(
                      controller: bioController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Status / Bio",
                        prefixIcon: Icon(Icons.info_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Save button
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          // Dismiss the bottom sheet first so context is clean
                          Get.back();
                          
                          // Show standard loading indicator dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                          
                          final success = await authController.updateProfile(
                            name: nameController.text.trim(),
                            bio: bioController.text.trim(),
                            localImagePath: selectedImagePath,
                          );
                          
                          // Pop the loading dialog
                          Get.back();
                          
                          if (success) {
                            Get.snackbar(
                              "Success",
                              "Profile updated successfully! ✨",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              colorText: Colors.white,
                            );
                          } else {
                            Get.snackbar(
                              "Error",
                              authController.errorMessage ?? "Failed to update profile",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Theme.of(context).colorScheme.error,
                              colorText: Colors.white,
                            );
                          }
                        }
                      },
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              
              // Profile Header Card wrapped in Obx
              Obx(() {
                final user = authController.currentUser;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Image
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                          image: user?.photoUrl != null && user!.photoUrl.isNotEmpty
                              ? (user.photoUrl.startsWith('http')
                                  ? DecorationImage(
                                      image: NetworkImage(user.photoUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : DecorationImage(
                                      image: FileImage(File(user.photoUrl)),
                                      fit: BoxFit.cover,
                                    ))
                              : null,
                        ),
                        child: user?.photoUrl == null || user!.photoUrl.isEmpty
                            ? Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // User Name
                      Text(
                        user?.name ?? "Anonymous User",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // User Email
                      Text(
                        user?.email ?? "no-email@example.com",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Bio status box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user?.bio ?? "Hey there! I am using this premium chat app.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 24),
              
              // Settings list options
              Card(
                child: Column(
                  children: [
                    // Edit Profile option
                    ListTile(
                      leading: Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
                      title: const Text("Edit Profile"),
                      subtitle: const Text("Update display name and status bio"),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => _showEditProfileSheet(context, authController),
                    ),
                    const Divider(height: 1, indent: 56),
                    
                    // Dark Mode Toggle wrapped in Obx
                    Obx(() => ListTile(
                      leading: Icon(
                        themeController.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text("Theme Settings"),
                      subtitle: Text(themeController.isDarkMode ? "Dark Theme Active" : "Light Theme Active"),
                      trailing: Switch(
                        value: themeController.isDarkMode,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (value) {
                          themeController.toggleTheme();
                        },
                      ),
                    )),
                    const Divider(height: 1, indent: 56),
                    
                    // Notifications
                    ListTile(
                      leading: Icon(Icons.notifications_active_rounded, color: theme.colorScheme.primary),
                      title: const Text("Notifications"),
                      subtitle: const StringToggleWidget(subtitleOn: "Enabled", subtitleOff: "Disabled"),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Logout button
              Card(
                child: ListTile(
                  leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                  title: Text(
                    "Logout",
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text("Sign out of active session securely"),
                  onTap: () async {
                    // Show standard progress dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                    
                    await authController.logout();
                    
                    // Pop progress dialog
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stateful switch utility for local interactions
class StringToggleWidget extends StatefulWidget {
  final String subtitleOn;
  final String subtitleOff;
  const StringToggleWidget({super.key, required this.subtitleOn, required this.subtitleOff});

  @override
  State<StringToggleWidget> createState() => _StringToggleWidgetState();
}

class _StringToggleWidgetState extends State<StringToggleWidget> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_value ? widget.subtitleOn : widget.subtitleOff),
        Switch(
          value: _value,
          onChanged: (val) {
            setState(() {
              _value = val;
            });
          },
        ),
      ],
    );
  }
}
