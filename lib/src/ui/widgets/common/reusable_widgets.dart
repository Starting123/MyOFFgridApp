import 'package:flutter/material.dart';
import '../../../models/user_role.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;
  final double size;
  final bool showLabel;

  const RoleBadge({
    Key? key,
    required this.role,
    this.size = 48,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: role.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: role.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            role.icon,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            role.displayName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: role.color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class UserCard extends StatelessWidget {
  final String name;
  final String phone;
  final UserRole role;
  final VoidCallback? onChatTap;
  final bool showChatButton;
  final String? lastMessage;
  final DateTime? lastSeen;

  const UserCard({
    Key? key,
    required this.name,
    required this.phone,
    required this.role,
    this.onChatTap,
    this.showChatButton = true,
    this.lastMessage,
    this.lastSeen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            RoleBadge(
              role: role,
              size: 40,
              showLabel: false,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (lastMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      lastMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (lastSeen != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatLastSeen(lastSeen!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChatButton && onChatTap != null)
              IconButton.filledTonal(
                onPressed: onChatTap,
                icon: const Icon(Icons.chat),
                tooltip: 'Start Chat',
              ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

enum MessageStatus {
  pending,
  sent,
  synced,
  failed,
}

extension MessageStatusExtension on MessageStatus {
  IconData get icon {
    switch (this) {
      case MessageStatus.pending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.synced:
        return Icons.cloud_done;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (this) {
      case MessageStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
      case MessageStatus.sent:
        return Colors.green;
      case MessageStatus.synced:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
    }
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final MessageStatus status;
  final DateTime timestamp;
  final String? imageUrl;
  final String? videoUrl;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.status,
    required this.timestamp,
    this.imageUrl,
    this.videoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        color: theme.colorScheme.errorContainer,
                        child: Icon(
                          Icons.broken_image,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (videoUrl != null) ...[
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (message.isNotEmpty)
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isMe
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isMe
                          ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      status.icon,
                      size: 12,
                      color: status.getColor(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}