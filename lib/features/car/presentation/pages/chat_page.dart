// lib/features/car/presentation/pages/chat_page.dart
// Real-time buyer-seller chat using Supabase Realtime.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/car.dart';

final _db = Supabase.instance.client;

// ═══════════════════════════════════════════════════════════════
// CHAT LIST PAGE
// ═══════════════════════════════════════════════════════════════
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = _db.auth.currentUser?.id;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 72,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to view messages',
                style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db
            .from('conversations')
            .stream(primaryKey: ['id'])
            .order('last_msg_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data ?? [];
          final mine = rows
              .where(
                (r) => r['buyer_id'] == uid || r['seller_id'] == uid.toString(),
              )
              .toList();

          if (mine.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 72,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap "Chat with Seller" on any car listing',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: mine.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 76, color: Colors.grey.shade100),
            itemBuilder: (_, i) {
              final c = mine[i];
              final isBuyer = c['buyer_id'] == uid;
              final other = isBuyer
                  ? c['seller_name'] as String? ?? 'Seller'
                  : c['buyer_name'] as String? ?? 'Buyer';
              final unread = isBuyer
                  ? (c['buyer_unread'] as int? ?? 0)
                  : (c['seller_unread'] as int? ?? 0);

              return _ConvTile(
                convId: c['id'] as String,
                otherName: other,
                carName: c['car_name'] as String? ?? '',
                lastMsg: c['last_message'] as String? ?? '',
                lastTime: _fmtTime(c['last_msg_at'] as String?),
                unread: unread,
                car: Car(
                  id: c['car_id'] as String? ?? '',
                  name: c['car_name'] as String? ?? '',
                  brand: '',
                  price: c['car_price'] as String? ?? '',
                  imageUrl: c['car_image'] as String? ?? '',
                ),
                sellerId: c['seller_id'] as String? ?? '',
                sellerName: c['seller_name'] as String? ?? '',
                buyerId: c['buyer_id'] as String? ?? '',
                buyerName: c['buyer_name'] as String? ?? '',
              );
            },
          );
        },
      ),
    );
  }

  static String _fmtTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day) {
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour >= 12 ? "PM" : "AM"}';
    }
    if (now.difference(dt).inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }
}

class _ConvTile extends StatelessWidget {
  final String convId, otherName, carName, lastMsg, lastTime;
  final String sellerId, sellerName, buyerId, buyerName;
  final int unread;
  final Car car;

  const _ConvTile({
    required this.convId,
    required this.otherName,
    required this.carName,
    required this.lastMsg,
    required this.lastTime,
    required this.unread,
    required this.car,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
  });

  @override
  Widget build(BuildContext context) {
    final initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            conversationId: convId,
            otherName: otherName,
            car: car,
            sellerId: sellerId,
            sellerName: sellerName,
            buyerId: buyerId,
            buyerName: buyerName,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            radius: 26,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherName,
              style: TextStyle(
                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            lastTime,
            style: TextStyle(
              color: unread > 0 ? AppTheme.primaryBlue : Colors.grey,
              fontSize: 11,
              fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            carName,
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lastMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unread > 0 ? AppTheme.textDark : AppTheme.textGrey,
              fontSize: 12,
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHAT ROOM PAGE — real-time messaging
// ═══════════════════════════════════════════════════════════════
class ChatRoomPage extends StatefulWidget {
  final String? conversationId;
  final String otherName;
  final Car car;
  final String sellerId, sellerName, buyerId, buyerName;

  const ChatRoomPage({
    super.key,
    this.conversationId,
    required this.otherName,
    required this.car,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _uid = _db.auth.currentUser?.id ?? '';
  final _userName =
      _db.auth.currentUser?.userMetadata?['name'] as String? ??
      _db.auth.currentUser?.email?.split('@').first ??
      'User';

  String? _convId;
  bool _isSending = false;
  bool _isCreating = false;
  StreamSubscription? _sub;
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _convId = widget.conversationId;
    if (_convId != null) {
      _loadMessages();
      _markRead();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _loadMessages() {
    if (_convId == null) return;
    _db
        .from('messages')
        .select()
        .eq('conversation_id', _convId!)
        .order('created_at', ascending: true)
        .then((rows) {
          if (!mounted) return;
          setState(() {
            _messages.clear();
            _messages.addAll((rows as List).cast());
          });
          _scrollToBottom();
        });

    _sub = _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', _convId!)
        .order('created_at', ascending: true)
        .listen((rows) {
          if (!mounted) return;
          setState(() {
            _messages.clear();
            _messages.addAll(rows.cast());
          });
          _scrollToBottom();
          _markRead();
        });
  }

  Future<String?> _ensureConversation() async {
    if (_convId != null) return _convId;
    setState(() => _isCreating = true);
    try {
      final ex = await _db
          .from('conversations')
          .select('id')
          .eq('car_id', widget.car.id)
          .eq('buyer_id', _uid)
          .eq('seller_id', widget.sellerId)
          .maybeSingle();

      if (ex != null) {
        _convId = ex['id'] as String;
      } else {
        final r = await _db
            .from('conversations')
            .insert({
              'car_id': widget.car.id,
              'car_name': widget.car.name,
              'car_price': widget.car.price,
              'car_image': widget.car.imageUrl,
              'buyer_id': _uid,
              'buyer_name': _userName,
              'seller_id': widget.sellerId,
              'seller_name': widget.sellerName,
              'last_message': '',
              'buyer_unread': 0,
              'seller_unread': 0,
            })
            .select('id')
            .single();
        _convId = r['id'] as String;
      }
      _loadMessages();
      return _convId;
    } catch (e) {
      if (mounted) _snack('Could not start chat: $e', error: true);
      return null;
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    _msgCtrl.clear();
    setState(() => _isSending = true);
    try {
      final convId = await _ensureConversation();
      if (convId == null) return;
      await _db.from('messages').insert({
        'conversation_id': convId,
        'sender_id': _uid,
        'sender_name': _userName,
        'content': text,
        'is_read': false,
      });
    } catch (e) {
      _snack('Send failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _markRead() async {
    if (_convId == null) return;
    try {
      final isBuyer = _uid == widget.buyerId;
      await _db
          .from('conversations')
          .update(isBuyer ? {'buyer_unread': 0} : {'seller_unread': 0})
          .eq('id', _convId!);
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Text(
              'tap here for info',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () => _snack('Call feature coming soon'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _moreOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Car banner
          _CarBanner(car: widget.car),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Send your first message to ${widget.otherName}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _Bubble(
                      msg: _messages[i],
                      isMe: _messages[i]['sender_id'] == _uid,
                      showDate:
                          i == 0 ||
                          _diffDay(
                            _messages[i - 1]['created_at'] as String?,
                            _messages[i]['created_at'] as String?,
                          ),
                    ),
                  ),
          ),

          // Input
          _InputBar(
            controller: _msgCtrl,
            isSending: _isSending || _isCreating,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  bool _diffDay(String? a, String? b) {
    final da = a != null ? DateTime.tryParse(a)?.toLocal() : null;
    final db = b != null ? DateTime.tryParse(b)?.toLocal() : null;
    if (da == null || db == null) return true;
    return da.day != db.day || da.month != db.month;
  }

  void _moreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Delete conversation',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              if (_convId == null) return;
              await _db.from('conversations').delete().eq('id', _convId!);
              if (mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final bool showDate;
  const _Bubble({
    required this.msg,
    required this.isMe,
    required this.showDate,
  });

  @override
  Widget build(BuildContext context) {
    final text = msg['content'] as String? ?? '';
    final isRead = msg['is_read'] as bool? ?? false;
    final time = _fmt(msg['created_at'] as String?);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDate)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _date(msg['created_at'] as String?),
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              bottom: 4,
              left: isMe ? 64 : 0,
              right: isMe ? 0 : 64,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryBlue : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      msg['sender_name'] as String? ?? '',
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppTheme.textDark,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: isMe ? Colors.white60 : AppTheme.textGrey,
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 12,
                        color: isRead ? Colors.lightBlueAccent : Colors.white60,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return '$h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? "PM" : "AM"}';
  }

  String _date(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day) return 'Today';
    if (now.difference(dt).inDays == 1) return 'Yesterday';
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${m[dt.month - 1]}';
  }
}

// ── Input bar ──────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSending ? Colors.grey.shade300 : AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Car info banner ────────────────────────────────────────────
class _CarBanner extends StatelessWidget {
  final Car car;
  const _CarBanner({required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: car.imageUrl.isNotEmpty
                ? Image.network(
                    car.imageUrl,
                    width: 48,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _icon(),
                  )
                : _icon(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.primaryBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (car.price.isNotEmpty)
                  Text(
                    '₹${_fmt(car.price)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentGreen,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon() => Container(
    width: 48,
    height: 36,
    color: Colors.grey.shade200,
    child: const Icon(
      Icons.directions_car_outlined,
      color: Colors.grey,
      size: 20,
    ),
  );

  String _fmt(String p) {
    final n = int.tryParse(p.replaceAll(',', '').replaceAll('₹', ''));
    if (n == null) return p;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(2)} L';
    return p;
  }
}
