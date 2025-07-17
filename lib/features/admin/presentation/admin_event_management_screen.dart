import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/admin_bottom_navigation.dart';
import '../models/admin_data_models.dart';
import '../controllers/admin_auth_controller.dart';

class AdminEventManagementScreen extends StatelessWidget {
  const AdminEventManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEventDialog(controller),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadEvents(refresh: true),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingEvents && controller.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.events.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No events found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadEvents(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.events.length,
            itemBuilder: (context, index) {
              final event = controller.events[index];
              return _buildEventCard(event, controller);
            },
          ),
        );
      }),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildEventCard(AdminEventModel event, AdminDashboardController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          if (event.eventImgUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                event.eventImgUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.eventName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(event.status),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Event Details
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.eventVenue,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      event.eventDate,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Event Description
                Text(
                  event.eventDescription,
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Creator Info
                Text(
                  'Created by: ${event.createdBy}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                
                Text(
                  'Created: ${_formatDate(event.createdAt.toDate())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        onPressed: () => _showEditEventDialog(event, controller),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          event.status == 'published' ? Icons.unpublished : Icons.publish,
                          size: 16,
                        ),
                        label: Text(
                          event.status == 'published' ? 'Unpublish' : 'Publish',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: event.status == 'published' 
                              ? Colors.orange 
                              : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final newStatus = event.status == 'published' 
                              ? 'draft' 
                              : 'published';
                          controller.updateEvent(event.id, {'status': newStatus});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteEventDialog(event, controller),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'published':
        color = Colors.green;
        break;
      case 'draft':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateEventDialog(AdminDashboardController controller) {
    _showEventDialog(controller, null);
  }

  void _showEditEventDialog(AdminEventModel event, AdminDashboardController controller) {
    _showEventDialog(controller, event);
  }

  void _showEventDialog(AdminDashboardController controller, AdminEventModel? existingEvent) {
    final nameController = TextEditingController(text: existingEvent?.eventName ?? '');
    final descriptionController = TextEditingController(text: existingEvent?.eventDescription ?? '');
    final venueController = TextEditingController(text: existingEvent?.eventVenue ?? '');
    final dateController = TextEditingController(text: existingEvent?.eventDate ?? '');
    
    String selectedImageUrl = existingEvent?.eventImgUrl ?? '';
    File? selectedImageFile;
    String selectedStatus = existingEvent?.status ?? 'draft';
    
    final authController = Get.find<AdminAuthController>();
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingEvent == null ? 'Create Event' : 'Edit Event'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: Get.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Event Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Event Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Event Description
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Event Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Event Venue
                    TextField(
                      controller: venueController,
                      decoration: const InputDecoration(
                        labelText: 'Event Venue',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Event Date
                    TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Event Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              dateController.text = '${date.day}/${date.month}/${date.year}';
                            }
                          },
                        ),
                      ),
                      readOnly: true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Status Selection
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'published', child: Text('Published')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Image Selection
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: selectedImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  Image.file(
                                    selectedImageFile!, 
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedImageFile = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : selectedImageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        selectedImageUrl, 
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 64,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedImageUrl = '';
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image, size: 64, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add_photo_alternate),
                                      label: const Text('Select Image'),
                                      onPressed: () async {
                                        final picker = ImagePicker();
                                        final pickedFile = await picker.pickImage(
                                          source: ImageSource.gallery,
                                          maxWidth: 1024,
                                          maxHeight: 1024,
                                          imageQuality: 80,
                                        );
                                        if (pickedFile != null) {
                                          setState(() {
                                            selectedImageFile = File(pickedFile.path);
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                    ),
                    
                    if (selectedImageFile != null || selectedImageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Change Image'),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1024,
                              maxHeight: 1024,
                              imageQuality: 80,
                            );
                            if (pickedFile != null) {
                              setState(() {
                                selectedImageFile = File(pickedFile.path);
                                selectedImageUrl = ''; // Clear existing URL
                              });
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      descriptionController.text.trim().isEmpty ||
                      venueController.text.trim().isEmpty ||
                      dateController.text.trim().isEmpty) {
                    Get.snackbar('Error', 'Please fill in all required fields');
                    return;
                  }

                  // Show loading state
                  // Create a local StatefulBuilder to manage loading state
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (context, setDialogState) {
                          return AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  existingEvent == null 
                                      ? 'Creating event...' 
                                      : 'Updating event...',
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );

                  try {
                    String imageUrl = selectedImageUrl;
                    
                    // Upload image to Firebase Storage if a new image is selected
                    if (selectedImageFile != null) {
                      imageUrl = await _uploadEventImage(selectedImageFile!);
                    }

                    if (existingEvent == null) {
                      // Create new event
                      final event = AdminEventModel(
                        id: '',
                        eventName: nameController.text.trim(),
                        eventDescription: descriptionController.text.trim(),
                        eventVenue: venueController.text.trim(),
                        eventDate: dateController.text.trim(),
                        eventImgUrl: imageUrl,
                        createdBy: authController.currentAdmin?.email ?? '',
                        createdAt: Timestamp.now(),
                        isActive: true,
                        status: selectedStatus,
                      );
                      
                      // Call controller method and wait for completion
                      await controller.createEventSilent(event);
                    } else {
                      // Update existing event
                      await controller.updateEventSilent(existingEvent.id, {
                        'event_name': nameController.text.trim(),
                        'event_description': descriptionController.text.trim(),
                        'event_venue': venueController.text.trim(),
                        'event_date': dateController.text.trim(),
                        'event_img_url': imageUrl,
                        'status': selectedStatus,
                      });
                    }
                    
                    // Close loading dialog
                    Navigator.of(context).pop();
                    
                    // Close form dialog
                    Navigator.of(context).pop();
                    
                    // Show success message
                    Get.snackbar(
                      'Success', 
                      existingEvent == null ? 'Event created successfully' : 'Event updated successfully',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                    );
                  } catch (e) {
                    // Close loading dialog
                    Navigator.of(context).pop();
                    
                    print('Error saving event: $e'); // Debug print
                    
                    Get.snackbar(
                      'Error', 
                      'Failed to save event: ${e.toString()}',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 5),
                    );
                  }
                },
                child: Text(existingEvent == null ? 'Create Event' : 'Update Event'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteEventDialog(AdminEventModel event, AdminDashboardController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.eventName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteEvent(event.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Upload event image to Firebase Storage
  Future<String> _uploadEventImage(File imageFile) async {
    try {
      final authController = Get.find<AdminAuthController>();
      final adminEmail = authController.currentAdmin?.email ?? 'unknown';
      
      final String fileName = 'event_images/${adminEmail}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload event image: $e');
    }
  }
}
