import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventController extends GetxController {
  final EventService _eventService = EventService();

  // Observable variables
  final RxList<EventModel> allEvents = <EventModel>[].obs;
  final RxList<EventModel> upcomingEvents = <EventModel>[].obs;
  final RxList<EventModel> userAttendingEvents = <EventModel>[].obs;
  final RxList<EventModel> thisWeekEvents = <EventModel>[].obs;
  final RxList<EventModel> thisMonthEvents = <EventModel>[].obs;
  final RxList<EventModel> searchResults = <EventModel>[].obs;
  
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isProcessingAttendance = false.obs;

  // Search and filter
  final TextEditingController searchController = TextEditingController();
  final Rx<EventType?> selectedEventType = Rx<EventType?>(null);
  final RxString selectedLocation = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllEvents();
    loadUpcomingEvents();
    loadUserAttendingEvents();
    loadThisWeekEvents();
    loadThisMonthEvents();
    
    // Listen to search text changes
    searchController.addListener(_onSearchTextChanged);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Load all active events
  void loadAllEvents() {
    try {
      _eventService.getActiveEvents().listen((events) {
        allEvents.assignAll(events);
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load events: ${e.toString()}');
    }
  }

  // Load upcoming events
  void loadUpcomingEvents() {
    try {
      _eventService.getUpcomingEvents().listen((events) {
        upcomingEvents.assignAll(events);
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load upcoming events: ${e.toString()}');
    }
  }

  // Load user attending events
  void loadUserAttendingEvents() {
    try {
      _eventService.getUserAttendingEvents().listen((events) {
        userAttendingEvents.assignAll(events);
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load your events: ${e.toString()}');
    }
  }

  // Load this week events
  void loadThisWeekEvents() {
    try {
      _eventService.getThisWeekEvents().listen((events) {
        thisWeekEvents.assignAll(events);
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load this week events: ${e.toString()}');
    }
  }

  // Load this month events
  void loadThisMonthEvents() {
    try {
      _eventService.getThisMonthEvents().listen((events) {
        thisMonthEvents.assignAll(events);
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load this month events: ${e.toString()}');
    }
  }

  // Handle search text changes
  void _onSearchTextChanged() {
    if (searchController.text.trim().isEmpty) {
      searchResults.clear();
    }
  }

  // Search events
  Future<void> searchEvents([String? query]) async {
    try {
      isSearching.value = true;
      final searchText = query ?? searchController.text.trim();
      
      if (searchText.isEmpty) {
        searchResults.clear();
        return;
      }

      final results = await _eventService.searchEvents(searchText);
      searchResults.assignAll(results);
      
    } catch (e) {
      _showErrorSnackbar('Search failed: ${e.toString()}');
    } finally {
      isSearching.value = false;
    }
  }

  // Filter events by type
  void filterEventsByType(EventType? eventType) {
    selectedEventType.value = eventType;
    
    if (eventType == null) {
      // Show all events
      return;
    }
    
    try {
      _eventService.getEventsByType(eventType).listen((events) {
        searchResults.assignAll(events);
      });
    } catch (e) {
      _showErrorSnackbar('Failed to filter events: ${e.toString()}');
    }
  }

  // Filter events by location
  void filterEventsByLocation(String location) {
    selectedLocation.value = location;
    
    if (location.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    
    try {
      _eventService.getEventsByLocation(location).listen((events) {
        searchResults.assignAll(events);
      });
    } catch (e) {
      _showErrorSnackbar('Failed to filter events by location: ${e.toString()}');
    }
  }

  // Join an event
  Future<void> joinEvent(String eventId) async {
    try {
      isProcessingAttendance.value = true;
      await _eventService.joinEvent(eventId);
      
      _showSuccessSnackbar('Successfully joined the event');
      
      // Refresh events
      loadUserAttendingEvents();
      
    } catch (e) {
      _showErrorSnackbar('Failed to join event: ${e.toString()}');
    } finally {
      isProcessingAttendance.value = false;
    }
  }

  // Leave an event
  Future<void> leaveEvent(String eventId) async {
    try {
      // Show confirmation dialog
      final bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Leave Event'),
          content: const Text('Are you sure you want to leave this event?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Leave'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isProcessingAttendance.value = true;
      await _eventService.leaveEvent(eventId);
      
      _showSuccessSnackbar('Left the event');
      
      // Refresh events
      loadUserAttendingEvents();
      
    } catch (e) {
      _showErrorSnackbar('Failed to leave event: ${e.toString()}');
    } finally {
      isProcessingAttendance.value = false;
    }
  }

  // Check if user is attending an event
  Future<bool> isUserAttending(String eventId) async {
    try {
      return await _eventService.isUserAttending(eventId);
    } catch (e) {
      return false;
    }
  }

  // Get event attendees count
  Future<int> getEventAttendeesCount(String eventId) async {
    try {
      return await _eventService.getEventAttendeesCount(eventId);
    } catch (e) {
      return 0;
    }
  }

  // Get event details
  Future<EventModel?> getEventDetails(String eventId) async {
    try {
      return await _eventService.getEventById(eventId);
    } catch (e) {
      _showErrorSnackbar('Failed to load event details: ${e.toString()}');
      return null;
    }
  }

  // Clear search and filters
  void clearSearchAndFilters() {
    searchController.clear();
    selectedEventType.value = null;
    selectedLocation.value = '';
    searchResults.clear();
  }

  // Get all event types
  List<EventType> getAllEventTypes() {
    return _eventService.getAllEventTypes();
  }

  // Get unique locations from all events
  List<String> getUniqueLocations() {
    final locations = <String>{};
    for (final event in allEvents) {
      if (event.location.isNotEmpty) {
        locations.add(event.location);
      }
    }
    return locations.toList()..sort();
  }

  // Get filtered events list
  List<EventModel> get filteredEventsList {
    if (searchResults.isNotEmpty) {
      return searchResults;
    }
    
    if (selectedEventType.value != null) {
      return allEvents.where((event) => event.eventType == selectedEventType.value).toList();
    }
    
    if (selectedLocation.value.isNotEmpty) {
      return allEvents.where((event) => 
        event.location.toLowerCase().contains(selectedLocation.value.toLowerCase())
      ).toList();
    }
    
    return upcomingEvents;
  }

  // Get events by status
  List<EventModel> getEventsByStatus({required bool upcoming}) {
    final now = DateTime.now();
    return allEvents.where((event) {
      final eventDate = event.eventDate.toDate();
      return upcoming ? eventDate.isAfter(now) : eventDate.isBefore(now);
    }).toList();
  }

  // Format event date
  String formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${_formatTime(date)}';
    } else if (difference.inDays > 0 && difference.inDays <= 7) {
      return '${_getDayName(date.weekday)} ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
    }
  }

  // Format time
  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Get day name
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  // Get event status
  String getEventStatus(EventModel event) {
    final now = DateTime.now();
    final eventDate = event.eventDate.toDate();
    
    if (eventDate.isBefore(now)) {
      return 'Past';
    } else if (eventDate.difference(now).inDays == 0) {
      return 'Today';
    } else if (eventDate.difference(now).inDays == 1) {
      return 'Tomorrow';
    } else if (eventDate.difference(now).inDays <= 7) {
      return 'This Week';
    } else if (eventDate.difference(now).inDays <= 30) {
      return 'This Month';
    } else {
      return 'Upcoming';
    }
  }

  // Helper methods
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}
