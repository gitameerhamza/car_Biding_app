import 'package:get/get.dart';

class SearchHistoryService extends GetxService {
  static const int _maxHistoryItems = 10;
  
  final RxList<String> searchHistory = <String>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // For now, start with empty history
    // In a real app, you could load from local storage
  }
  
  // Add search term to history
  void addToHistory(String searchTerm) {
    try {
      if (searchTerm.trim().isEmpty) return;
      
      // Remove if already exists
      searchHistory.remove(searchTerm);
      
      // Add to beginning
      searchHistory.insert(0, searchTerm);
      
      // Keep only recent items
      if (searchHistory.length > _maxHistoryItems) {
        searchHistory.removeRange(_maxHistoryItems, searchHistory.length);
      }
    } catch (e) {
      print('Error adding to search history: $e');
    }
  }
  
  // Clear search history
  void clearHistory() {
    try {
      searchHistory.clear();
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }
  
  // Remove specific item from history
  void removeFromHistory(String searchTerm) {
    try {
      searchHistory.remove(searchTerm);
    } catch (e) {
      print('Error removing from search history: $e');
    }
  }
}
