// lib/features/car/presentation/pages/chat_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/car.dart';

// ── Chat list page ─────────────────────────────────────────────
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // In production, fetch real chats from Supabase.
    // Showing UI scaffold with demo conversations.
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
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
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'New message',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Start a chat from any car listing'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
          ),
        ],
      ),
      body: _buildChatList(context),
    );
  }

  Widget _buildChatList(BuildContext context) {
    // Demo chat threads — replace with real Supabase realtime query
    final demoChats = [
      _ChatThread(
        name: 'Rahul Menon',
        carName: 'Maruti Swift VXi',
        lastMsg: 'Is the car still available?',
        time: '10:30 AM',
        unread: 2,
        initial: 'R',
      ),
      _ChatThread(
        name: 'Priya Nair',
        carName: 'Hyundai Creta SX',
        lastMsg: 'Can we schedule a test drive?',
        time: 'Yesterday',
        unread: 0,
        initial: 'P',
      ),
      _ChatThread(
        name: 'Arun Kumar',
        carName: 'Toyota Fortuner',
        lastMsg: 'What is your final price?',
        time: 'Mon',
        unread: 1,
        initial: 'A',
      ),
    ];

    if (demoChats.isEmpty) {
      return Center(
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
              style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Contact Seller" on any car to start chatting',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: demoChats.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 72, color: Colors.grey.shade100),
      itemBuilder: (_, i) => _ChatTile(
        thread: demoChats[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(
              sellerName: demoChats[i].name,
              carName: demoChats[i].carName,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chat room ──────────────────────────────────────────────────
class ChatRoomPage extends StatefulWidget {
  final String sellerName;
  final String carName;
  final Car? car;

  const ChatRoomPage({
    super.key,
    required this.sellerName,
    required this.carName,
    this.car,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];

  @override
  void initState() {
    super.initState();
    // Pre-populate with a greeting
    _messages.add(
      _Msg(
        text:
            'Hi! I\'m interested in the ${widget.carName}. Is it still available?',
        isMe: true,
        time: _now(),
      ),
    );
    _messages.add(
      _Msg(
        text: 'Yes, it is! Feel free to ask any questions.',
        isMe: false,
        time: _now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: text, isMe: true, time: _now()));
      _controller.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    // Simulate a reply after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final replies = [
        'Sure, I can provide more details.',
        'The car is in excellent condition.',
        'You can come for a test drive anytime this week.',
        'The price is negotiable.',
      ];
      final reply = replies[_messages.length % replies.length];
      setState(
        () => _messages.add(_Msg(text: reply, isMe: false, time: _now())),
      );
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
              widget.sellerName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              widget.carName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.phone_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Car info banner
          if (widget.car != null)
            Container(
              color: AppTheme.bgLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.carName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  Text(
                    '₹${_fmtPrice(widget.car!.price)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentGreen,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _BubbleWidget(msg: _messages[i]),
            ),
          ),

          // Input bar
          Container(
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
                    controller: _controller,
                    onSubmitted: (_) => _send(),
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
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _now() {
    final t = DateTime.now();
    final h = t.hour > 12 ? t.hour - 12 : t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  String _fmtPrice(String p) {
    final n = int.tryParse(p.replaceAll(',', '').replaceAll('₹', ''));
    if (n == null) return p;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(2)} L';
    return p;
  }
}

// ── Data models ────────────────────────────────────────────────
class _ChatThread {
  final String name, carName, lastMsg, time, initial;
  final int unread;
  const _ChatThread({
    required this.name,
    required this.carName,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.initial,
  });
}

class _Msg {
  final String text, time;
  final bool isMe;
  const _Msg({required this.text, required this.isMe, required this.time});
}

// ── Chat list tile ─────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final _ChatThread thread;
  final VoidCallback onTap;
  const _ChatTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryBlue,
        radius: 24,
        child: Text(
          thread.initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              thread.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          Text(
            thread.time,
            style: TextStyle(
              color: thread.unread > 0 ? AppTheme.primaryBlue : Colors.grey,
              fontSize: 11,
              fontWeight: thread.unread > 0
                  ? FontWeight.w700
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            thread.carName,
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  thread.lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: thread.unread > 0
                        ? AppTheme.textDark
                        : AppTheme.textGrey,
                    fontSize: 12,
                    fontWeight: thread.unread > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (thread.unread > 0)
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${thread.unread}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────
class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  const _BubbleWidget({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: msg.isMe ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: msg.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe ? Colors.white : AppTheme.textDark,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: TextStyle(
                color: msg.isMe ? Colors.white60 : AppTheme.textGrey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
