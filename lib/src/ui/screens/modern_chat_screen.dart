import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../providers/enhanced_chat_provider.dart';
import '../../providers/real_device_providers.dart';

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
    final chatState = ref.watch(enhancedChatProvider);
    final nearbyDevices = ref.watch(realNearbyDevicesProvider);

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
              child: chatState.when(
                data: (chatData) => _buildMessagesList(chatData.messages),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00D4FF),
                  ),
                ),
                error: (error, stack) => _buildErrorState(error.toString()),
              ),
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
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Text(
              message.content ?? 'Empty message',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(List<RealNearbyDevice> nearbyDevices) {
    final connectedDevices = nearbyDevices.where((d) => d.status == DeviceConnectionStatus.connected).toList();
    
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
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

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      await ref.read(enhancedChatProvider.notifier).sendMessage(message);
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
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
}