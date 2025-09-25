/// Application constants and configuration
class Constants {
  // Cloud sync endpoint
  static const String cloudEndpoint = 'https://api.offgridsos.com/v1';
  
  // File transfer settings
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int chunkSize = 64 * 1024; // 64KB
  
  // SOS settings
  static const Duration sosBroadcastInterval = Duration(minutes: 2);
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  
  // Network settings
  static const String nearbyServiceId = 'com.offgrid.sos';
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Database settings
  static const String databaseName = 'enhanced_offgrid_db.sqlite';
  static const int maxStoredMessages = 1000;
  
  // App settings
  static const String appName = 'Off-Grid SOS & Nearby Share';
  static const String appVersion = '1.0.0';
  
  // Message types (legacy compatibility)
  static const String textMessage = 'text';
  static const String imageMessage = 'image';
  static const String locationMessage = 'location';
  static const String sosMessage = 'sos';
  
  // Sync states (legacy compatibility)
  static const String syncPending = 'pending';
  static const String syncInProgress = 'in_progress';
  static const String syncComplete = 'complete';
  static const String syncError = 'error';
  
  // Priorities (legacy compatibility)
  static const int highPriority = 0;
  static const int normalPriority = 1;
  static const int lowPriority = 2;
  
  // Emergency contacts (configurable by user)
  static const List<String> emergencyContacts = [
    '112', // EU emergency
    '911', // US emergency
    '999', // UK emergency
  ];
  
  // Supported file extensions
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> supportedVideoTypes = ['mp4', 'avi', 'mov', 'mkv'];
  static const List<String> supportedDocumentTypes = ['pdf', 'doc', 'docx', 'txt', 'zip'];
}