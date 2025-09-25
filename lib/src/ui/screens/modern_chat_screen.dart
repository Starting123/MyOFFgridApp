import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../providers/main_providers.dart';
import '../../models/chat_models.dart';

class ModernChatScreen extends ConsumerStatefulWidget {
  const ModernChatScreen({super.key});

  @override
  ConsumerState<ModernChatScreen> createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends ConsumerState<ModernChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(messagesProvider);
    final nearbyDevices = ref.watch(nearbyDevicesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Secure Chat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: nearbyDevices.isNotEmpty
                  ? const Color(0xFF4CAF50).withOpacity(0.2)
                  : const Color(0xFF757575).withOpacity(0.2),
              border: Border.all(
                color: nearbyDevices.isNotEmpty
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : const Color(0xFF757575).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nearbyDevices.isNotEmpty
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF757575),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${nearbyDevices.length}',
                  style: TextStyle(
                    color: nearbyDevices.isNotEmpty
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF757575),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F0F),
            ],
          ),
        ),
        child: Column(
          children: [
            // Connection Status Bar
            _buildConnectionStatus(nearbyDevices),
            
            // Messages List
            Expanded(
              child: _buildMessagesList(chatState),
            ),
            
            // Message Input
            _buildMessageInput(nearbyDevices.isNotEmpty),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<dynamic> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D4FF).withOpacity(0.2),
                    const Color(0xFF5B86E5).withOpacity(0.1),
                  ],
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: Color(0xFF00D4FF),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with nearby devices',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(dynamic message) {
    final isMe = message.senderId == 'me'; // Adjust based on your message model
    final messageType = message.type ?? 'text';
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(messageType == 'text' ? 16 : 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isMe
                ? [
                    const Color(0xFF00D4FF),
                    const Color(0xFF5B86E5),
                  ]
                : [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1A1A1A),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: (isMe ? const Color(0xFF00D4FF) : Colors.black)
                  .withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Content based on type
            _buildMessageContent(message, messageType),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 8),
                // Status indicator
                _buildStatusIndicator(message.status ?? 'pending'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(List<NearbyDevice> nearbyDevices) {
    final connectedDevices = nearbyDevices.where((d) => d.isConnected).toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: connectedDevices.isNotEmpty 
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : const Color(0xFFFF9800).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: connectedDevices.isNotEmpty 
                ? const Color(0xFF4CAF50).withOpacity(0.3)
                : const Color(0xFFFF9800).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            connectedDevices.isNotEmpty ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: connectedDevices.isNotEmpty 
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFF9800),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              connectedDevices.isNotEmpty 
                  ? 'เชื่อมต่อกับ ${connectedDevices.length} อุปกรณ์'
                  : 'ไม่ได้เชื่อมต่อ - ข้อความจะถูกเก็บไว้ส่งภายหลัง',
              style: TextStyle(
                fontSize: 12,
                color: connectedDevices.isNotEmpty 
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
              ),
            ),
          ),
          if (connectedDevices.isEmpty)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/devices'),
              child: const Text(
                'เชื่อมต่อ',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF00D4FF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool hasConnection) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: const Color(0xFF2A2A2A),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: hasConnection ? 'พิมพ์ข้อความ...' : 'ข้อความจะส่งเมื่อเชื่อมต่อแล้ว...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    suffixIcon: !hasConnection 
                        ? Icon(Icons.schedule, color: Colors.orange.withOpacity(0.6), size: 16)
                        : null,
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF5B86E5)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      // Send message using AppActions
      await AppActions.sendTextMessage(
        ref,
        'broadcast', // conversationId - Send to all connected devices
        message, // content
      );
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📨 Message sent to nearby devices'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Send message error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  Widget _buildMessageContent(dynamic message, String messageType) {
    switch (messageType) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[800],
              ),
              child: message.filePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.filePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.image, size: 60, color: Colors.white54),
                      ),
                    )
                  : const Icon(Icons.image, size: 60, color: Colors.white54),
            ),
            if (message.content?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                message.content!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        );
      
      case 'video':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[800],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.black,
                      child: const Icon(Icons.play_circle_outline, 
                          size: 60, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '📹 Video',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (message.content?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                message.content!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        );
      
      case 'location':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.content ?? 'Location shared',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      
      case 'sos':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.emergency, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.content ?? '🚨 SOS EMERGENCY',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      
      default: // text
        return Text(
          message.content ?? 'Empty message',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        );
    }
  }

  Widget _buildStatusIndicator(String status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case 'sent':
        icon = Icons.check;
        color = Colors.white54;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.white54;
        break;
      case 'read':
        icon = Icons.done_all;
        color = const Color(0xFF00D4FF);
        break;
      case 'synced':
        icon = Icons.cloud_done;
        color = Colors.green;
        break;
      case 'failed':
        icon = Icons.error;
        color = Colors.red;
        break;
      default: // pending
        icon = Icons.schedule;
        color = Colors.orange;
        break;
    }
    
    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }
}
