import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/event_controller.dart';
import '../models/event_model.dart';

class EventViewScreen extends StatelessWidget {
  const EventViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EventController());

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          title: const Text('Car Events'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All Events'),
              Tab(text: 'Upcoming'),
              Tab(text: 'This Week'),
              Tab(text: 'My Events'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(context, controller),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildEventList(controller, controller.allEvents),
            _buildEventList(controller, controller.upcomingEvents),
            _buildEventList(controller, controller.thisWeekEvents),
            _buildEventList(controller, controller.userAttendingEvents),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(EventController controller, RxList<EventModel> events) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (events.isEmpty) {
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
        onRefresh: () async => controller.loadAllEvents(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(event, controller);
          },
        ),
      );
    });
  }

  Widget _buildEventCard(EventModel event, EventController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.event,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEventTypeColor(event.eventType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getEventTypeColor(event.eventType)),
                      ),
                      child: Text(
                        event.eventType.toString().toUpperCase(),
                        style: TextStyle(
                          color: _getEventTypeColor(event.eventType),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (event.description.isNotEmpty)
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(event.eventDate.toDate()),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${event.attendees.length} attendees',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEventDetails(event, controller),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() {
                        final isAttending = controller.userAttendingEvents.any((e) => e.id == event.id);
                        final isEventPast = event.eventDate.toDate().isBefore(DateTime.now());
                        
                        if (isEventPast) {
                          return ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.event_busy),
                            label: const Text('Past Event'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          );
                        }
                        
                        if (isAttending) {
                          return ElevatedButton.icon(
                            onPressed: () => controller.leaveEvent(event.id),
                            icon: const Icon(Icons.exit_to_app),
                            label: const Text('Leave'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          );
                        }
                        
                        return ElevatedButton.icon(
                          onPressed: () => controller.joinEvent(event.id),
                          icon: const Icon(Icons.add),
                          label: const Text('Join'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        );
                      }),
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

  Color _getEventTypeColor(EventType eventType) {
    switch (eventType) {
      case EventType.autoShow:
        return Colors.blue;
      case EventType.carMeet:
        return Colors.green;
      case EventType.auction:
        return Colors.orange;
      case EventType.racing:
        return Colors.red;
      case EventType.exhibition:
        return Colors.purple;
      case EventType.workshop:
        return Colors.teal;
    }
  }

  void _showEventDetails(EventModel event, EventController controller) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (event.imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description.isNotEmpty ? event.description : 'No description available.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Event Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.calendar_today,
                'Date & Time',
                DateFormat('MMM dd, yyyy HH:mm').format(event.eventDate.toDate()),
              ),
              _buildDetailRow(
                Icons.location_on,
                'Location',
                event.location,
              ),
              _buildDetailRow(
                Icons.people,
                'Attendees',
                event.attendees.length.toString(),
              ),
              _buildDetailRow(
                Icons.person,
                'Organizer',
                event.organizer,
              ),
              _buildDetailRow(
                Icons.category,
                'Event Type',
                event.eventType.toString().split('.').last,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final isAttending = controller.userAttendingEvents.any((e) => e.id == event.id);
                  final isEventPast = event.eventDate.toDate().isBefore(DateTime.now());
                  
                  if (isEventPast) {
                    return ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.event_busy),
                      label: const Text('Event Has Ended'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    );
                  }
                  
                  if (isAttending) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        controller.leaveEvent(event.id);
                        Get.back();
                      },
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Leave Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    );
                  }
                  
                  return ElevatedButton.icon(
                    onPressed: () {
                      controller.joinEvent(event.id);
                      Get.back();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Join Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, EventController controller) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search Events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by title, location, or organizer...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) {
                  controller.searchEvents(value);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        controller.searchController.clear();
                        controller.clearSearchAndFilters();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.searchEvents(controller.searchController.text);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Search'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
