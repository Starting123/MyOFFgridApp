// Instructions for connecting real providers to UI screens

// 1. SOS Screen Integration
// Replace in sos_screen_new.dart:
/*
final sosStatusProvider = StateProvider<bool>((ref) => false);

with:

final sosStateProvider = AsyncNotifierProvider<SOSNotifier, SOSAppState>(() {
  return SOSNotifier();
});
*/

// 2. Chat Integration  
// Replace mock chat data with real database queries:
/*
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.watchChatMessages(chatId);
});
*/

// 3. Home Screen Integration
// Connect to real nearby service:
/*
final nearbyDevicesProvider = StreamProvider<List<NearbyDevice>>((ref) {
  return NearbyService.instance.onDeviceFound.map((devices) => devices);
});
*/

// 4. Settings Integration
// Connect to real auth service:
/*
final currentUserProvider = FutureProvider<UserModel?>((ref) {
  return AuthService.instance.getCurrentUser();
});
*/