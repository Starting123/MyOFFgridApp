import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the actual SOS provider
import '../../../providers/enhanced_sos_provider.dart';
import '../../../services/service_coordinator.dart';
import '../../../models/chat_models.dart';
import '../../../utils/logger.dart';

// SOS State Provider
final sosProvider = AsyncNotifierProvider<SOSNotifier, SOSAppState>(() {
  return SOSNotifier();
});

// Real rescue devices provider using ServiceCoordinator
final rescueDevicesProvider = StreamProvider<List<NearbyDevice>>((ref) {
  return ServiceCoordinator.instance.deviceStream.map((devices) {
    return devices.where((device) => 
      device.isRescuerActive || 
      device.role == DeviceRole.rescuer
    ).toList();
  });
});

class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sosStateAsync = ref.watch(sosProvider);
    final rescueDevicesAsync = ref.watch(rescueDevicesProvider);

    return sosStateAsync.when(
      data: (sosState) => _buildSOSScreen(context, theme, sosState, rescueDevicesAsync),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('SOS Service Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(sosProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSScreen(BuildContext context, ThemeData theme, SOSAppState sosState, AsyncValue<List<NearbyDevice>> rescueDevicesAsync) {
    final isSOSActive = sosState.isSOSActive;
    
    // Start/stop pulse animation based on SOS status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isSOSActive && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      } else if (!isSOSActive && _pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        centerTitle: true,
        backgroundColor: isSOSActive ? Colors.red : null,
        foregroundColor: isSOSActive ? Colors.white : null,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isSOSActive
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.red.withValues(alpha: 0.1),
                    Colors.red.withValues(alpha: 0.05),
                  ],
                )
              : null,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildSOSButton(context, theme, isSOSActive),
                  const SizedBox(height: 20),
                  _buildStatusText(context, theme, isSOSActive),
                  const SizedBox(height: 20),
                  _buildInstructions(context, theme),
                  const SizedBox(height: 20),
                  _buildEmergencyContacts(context, theme),
                  const SizedBox(height: 40), // Bottom padding for scroll
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context, ThemeData theme, bool isActive) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? _pulseAnimation.value : 1.0,
            child: GestureDetector(
            onTap: _toggleSOS,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.red : Colors.red.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.red,
                  width: 4,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning,
                    size: 60,
                    color: isActive ? Colors.white : Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SOS',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: isActive ? Colors.white : Colors.red,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? 'TAP TO STOP' : 'TAP FOR HELP',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isActive ? Colors.white : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildStatusText(BuildContext context, ThemeData theme, bool isActive) {
    return Card(
      color: isActive ? Colors.red.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.broadcast_on_personal : Icons.broadcast_on_home,
                  color: isActive ? Colors.red : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'SOS ACTIVE' : 'SOS STANDBY',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isActive ? Colors.red : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isActive
                  ? 'Your emergency signal is being broadcast to nearby rescue teams. Help is on the way!'
                  : 'Tap the SOS button above to send an emergency signal to nearby rescue teams.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              ref.watch(rescueDevicesProvider).when(
                data: (rescueDevices) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: rescueDevices.isNotEmpty 
                          ? Colors.green 
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rescueDevices.isEmpty
                          ? 'Searching for rescue teams...'
                          : '${rescueDevices.length} rescue team${rescueDevices.length == 1 ? '' : 's'} nearby',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: rescueDevices.isNotEmpty 
                            ? Colors.green 
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                loading: () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Searching for rescue teams...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                error: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Error finding rescue teams',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Emergency Instructions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInstructionItem(
              context,
              '1.',
              'Stay calm and assess your situation',
              theme,
            ),
            _buildInstructionItem(
              context,
              '2.',
              'Activate SOS to alert nearby rescue teams',
              theme,
            ),
            _buildInstructionItem(
              context,
              '3.',
              'Stay in a visible location if possible',
              theme,
            ),
            _buildInstructionItem(
              context,
              '4.',
              'Conserve phone battery for communication',
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(
    BuildContext context,
    String number,
    String instruction,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Emergency Contacts',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactButton(
                  context,
                  Icons.local_police,
                  'Police',
                  '911',
                  theme,
                ),
                _buildContactButton(
                  context,
                  Icons.local_hospital,
                  'Medical',
                  '911',
                  theme,
                ),
                _buildContactButton(
                  context,
                  Icons.fire_truck,
                  'Fire',
                  '911',
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(
    BuildContext context,
    IconData icon,
    String label,
    String number,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () => _callEmergencyNumber(number),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSOS() async {
    final currentState = await ref.read(sosProvider.future);
    
    if (!currentState.isSOSActive) {
      _startSOSBroadcast();
    } else {
      _stopSOSBroadcast();
    }
  }

  Future<void> _startSOSBroadcast() async {
    try {
      final sosNotifier = ref.read(sosProvider.notifier);
      await sosNotifier.activateVictimMode();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 SOS signal activated! Broadcasting to nearby devices...'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate SOS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopSOSBroadcast() async {
    try {
      final sosNotifier = ref.read(sosProvider.notifier);
      sosNotifier.disableSOSMode();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ SOS signal deactivated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate SOS: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _callEmergencyNumber(String number) async {
    // TODO: Implement phone call functionality
    Logger.warning('Calling emergency number: $number', 'sos');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $number...'),
      ),
    );
  }
}