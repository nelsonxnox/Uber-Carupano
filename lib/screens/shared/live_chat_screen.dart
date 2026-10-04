import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../theme/beach_colors.dart';

/// Chat en vivo efímero pasajero ↔ conductor.
/// Se abre como un bottom sheet modal sobre cualquier pantalla.
/// Los mensajes se guardan en rides/{rideId}/messages y se borran
/// automáticamente cuando el viaje termina (status: completed / cancelled).
class LiveChatSheet extends StatefulWidget {
  final String rideId;
  final String currentUserId; // ID del usuario actual (pasajero o chofer)
  final String currentUserName;
  final bool isDriver;

  const LiveChatSheet({
    super.key,
    required this.rideId,
    required this.currentUserId,
    required this.currentUserName,
    required this.isDriver,
  });

  /// Abre el chat. En web desktop usa dialog (respeta el frame), en móvil usa bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String rideId,
    required String currentUserId,
    required String currentUserName,
    required bool isDriver,
  }) {
    final isDesktopWeb = kIsWeb && MediaQuery.of(context).size.width > 500;

    if (isDesktopWeb) {
      return showDialog(
        context: context,
        builder: (_) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 680),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LiveChatSheet(
                  rideId: rideId,
                  currentUserId: currentUserId,
                  currentUserName: currentUserName,
                  isDriver: isDriver,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Material(
        color: Colors.transparent,
        child: LiveChatSheet(
          rideId: rideId,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          isDriver: isDriver,
        ),
      ),
    );
  }


  @override
  State<LiveChatSheet> createState() => _LiveChatSheetState();
}

class _LiveChatSheetState extends State<LiveChatSheet> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late CollectionReference<Map<String, dynamic>> _messagesRef;
  StreamSubscription? _sub;
  List<_ChatMsg> _messages = [];
  bool _sending = false;
  int _previousCount = 0;
  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .collection('messages');
    _listenMessages();
  }

  void _listenMessages() {
    _sub = _messagesRef
        .orderBy('sentAt', descending: false)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;

      final newMessages = snap.docs.map((d) => _ChatMsg.fromMap(d.data(), d.id)).toList();

      // Notificar solo si hay mensajes nuevos que NO son míos
      if (!_initialLoad && newMessages.length > _previousCount) {
        final latestMsg = newMessages.last;
        if (latestMsg.senderId != widget.currentUserId) {
          _showInAppNotification(latestMsg);
          _showLocalNotification(latestMsg);
        }
      }

      _initialLoad = false;
      _previousCount = newMessages.length;

      setState(() {
        _messages = newMessages;
      });
      _scrollToBottom();
    });
  }

  void _showInAppNotification(_ChatMsg msg) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ChatNotificationBanner(
        senderName: msg.senderName,
        text: msg.text,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _showLocalNotification(_ChatMsg msg) async {
    if (kIsWeb) return; // En la web no se usa flutter_local_notifications plugin
    try {
      final vibrationPattern = Int64List.fromList([0, 200, 100, 200]);
      final androidDetails = AndroidNotificationDetails(
        'chat_messages_channel',
        'Mensajes del Chat',
        channelDescription: 'Notificaciones de mensajes en el chat del viaje',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        playSound: true,
      );
      final details = NotificationDetails(android: androidDetails);
      await FlutterLocalNotificationsPlugin().show(
        msg.senderName.hashCode,
        msg.senderName,
        msg.text,
        details,
      );
    } catch (e) {
      debugPrint('Chat notification error: $e');
    }
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      await _messagesRef.add({
        'senderId': widget.currentUserId,
        'senderName': widget.currentUserName,
        'isDriver': widget.isDriver,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Chat send error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;
    final isDesktopWeb = kIsWeb && MediaQuery.of(context).size.width > 500;

    final double chatH;
    if (isDesktopWeb) {
      chatH = 720;
    } else {
      final screenH = MediaQuery.of(context).size.height;
      chatH = (screenH * 0.72 + keyboardH).clamp(0.0, screenH - 40);
    }

    return Material(
      color: BeachColors.pureWhite,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(isDesktopWeb ? 20 : 22),
        bottom: Radius.circular(isDesktopWeb ? 20 : 0),
      ),
      child: Container(
        height: chatH,
        decoration: BoxDecoration(
          color: BeachColors.pureWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isDesktopWeb ? 20 : 22),
            bottom: Radius.circular(isDesktopWeb ? 20 : 0),
          ),
        ),
        child: Column(
          children: [
            // ── Handle ──────────────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: BeachColors.lagoonBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: BeachColors.lagoonBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: BeachColors.oceanLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        color: BeachColors.oceanPrimary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chat del Viaje',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: BeachColors.textMain,
                        ),
                      ),
                      Text(
                        widget.isDriver ? 'Hablando con el pasajero' : 'Hablando con el conductor',
                        style: const TextStyle(
                            fontSize: 10.5, color: BeachColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: BeachColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Banner Educativo sobre la importancia del Chat ───────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              color: const Color(0xFFEFF6FF),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: BeachColors.oceanPrimary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Usa este chat para acordar punto exacto de encuentro o cambio en efectivo.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Messages ─────────────────────────────────────────────────
            Expanded(

            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined,
                            color: BeachColors.lagoonBorder, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Sin mensajes aún.\nEscribe algo para empezar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: BeachColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg.senderId == widget.currentUserId;
                      return _buildBubble(msg, isMe);
                    },
                  ),
          ),

          // ── Input ────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + keyboardH),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: BeachColors.lagoonBorder)),
              color: BeachColors.pureWhite,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 13.5, color: BeachColors.textMain),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: TextStyle(color: BeachColors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: BeachColors.oceanPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildBubble(_ChatMsg msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: BeachColors.oceanLight,
              child: Icon(
                msg.isDriver ? Icons.two_wheeler : Icons.person,
                color: BeachColors.oceanPrimary,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? BeachColors.oceanPrimary
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      msg.senderName,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.75)
                            : BeachColors.oceanPrimary,
                      ),
                    ),
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: isMe ? Colors.white : BeachColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.timeLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.6)
                          : BeachColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Model ────────────────────────────────────────────────────────────────────

class _ChatMsg {
  final String id;
  final String senderId;
  final String senderName;
  final bool isDriver;
  final String text;
  final DateTime sentAt;

  _ChatMsg({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.isDriver,
    required this.text,
    required this.sentAt,
  });

  String get timeLabel {
    final h = sentAt.hour.toString().padLeft(2, '0');
    final m = sentAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory _ChatMsg.fromMap(Map<String, dynamic> map, String id) {
    DateTime ts = DateTime.now();
    if (map['sentAt'] is Timestamp) {
      ts = (map['sentAt'] as Timestamp).toDate();
    }
    return _ChatMsg(
      id: id,
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? 'Anónimo',
      isDriver: map['isDriver'] == true,
      text: map['text']?.toString() ?? '',
      sentAt: ts,
    );
  }
}

// ── In-App Notification Banner ────────────────────────────────────────────────

class _ChatNotificationBanner extends StatefulWidget {
  final String senderName;
  final String text;
  final VoidCallback onDismiss;

  const _ChatNotificationBanner({
    required this.senderName,
    required this.text,
    required this.onDismiss,
  });

  @override
  State<_ChatNotificationBanner> createState() => _ChatNotificationBannerState();
}

class _ChatNotificationBannerState extends State<_ChatNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: BeachColors.pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BeachColors.oceanPrimary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: BeachColors.oceanPrimary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: BeachColors.oceanLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded,
                          color: BeachColors.oceanPrimary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.senderName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: BeachColors.oceanPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: BeachColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: BeachColors.textMuted, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
