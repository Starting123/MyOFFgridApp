class Constants {
  // Cloud endpoints
  static const String cloudEndpoint = 'https://your-api-endpoint.com/api';
  
  // Message types
  static const String textMessage = 'text';
  static const String imageMessage = 'image';
  static const String locationMessage = 'location';
  static const String sosMessage = 'sos';
  
  // Sync states
  static const String syncPending = 'pending';
  static const String syncInProgress = 'in_progress';
  static const String syncComplete = 'complete';
  static const String syncError = 'error';
  
  // Priorities
  static const int highPriority = 0;
  static const int normalPriority = 1;
  static const int lowPriority = 2;
}