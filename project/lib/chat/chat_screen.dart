import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'chat_model.dart';
import 'chat_api_service.dart';
import 'chat_service.dart'; // 새로 만든 서비스 임포트

class ChatScreen extends StatefulWidget {
  final int roomId;
  final String roomName;

  const ChatScreen({Key? key, required this.roomId, required this.roomName}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 상태 변수들
  final List<ChatMessage> _messages = [];
  bool _isLoadingHistory = true; // 과거 내역 로딩 상태
  final TextEditingController _textController = TextEditingController();

  // 나의 유저 ID (로그인 정보에서 가져와야 함)
  late String myUserId;

  // 핵심: ChatService 인스턴스
  late final ChatService _chatService;

  @override
  void initState() {
    super.initState();
    // Provider를 통해 로그인된 사용자 정보를 가져와 myUserId에 할당
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    myUserId = authProvider.userProfile?.username ?? '';
    final token = authProvider.token;
    // 1. ChatService 초기화 및 연결 시작
    // 토큰이 있을 경우에만 ChatService를 초기화
    if (token != null) {
      // ✨ Bearer 중복 방지 - token에 이미 Bearer가 포함되어 있을 수 있음
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;
      _chatService = ChatService(roomId: widget.roomId, jwtToken: cleanToken);
      _chatService.connect();
      // ... 스트림 구독 및 과거 내역 불러오기 로직 ...
    } else {
      // 토큰이 없을 경우 (로그인 안 됨) 처리
      print('오류: 토큰이 없어서 채팅 서비스에 연결할 수 없습니다.');
      // TODO: 사용자에게 에러 메시지 보여주기
    }

    // 2. 서비스의 메시지 스트림을 구독하여 새 메시지가 올 때마다 _messages 리스트에 추가
    _chatService.messageStream.listen((newMessage) {
      if (mounted) { // 위젯이 화면에 있을 때만 setState 호출
        setState(() {
          _messages.insert(0, newMessage);
        });
      }
    });

    // 3. 과거 메시지 내역 불러오기
    _fetchChatHistory();
  }

  Future<void> _fetchChatHistory() async {
    try {
      final history = await ChatApiService.getChatHistory(widget.roomId);
      setState(() {
        _messages.addAll(history);
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() { _isLoadingHistory = false; });
      // TODO: 사용자에게 에러 메시지 보여주기 (e.g., SnackBar)
      print('과거 메시지 로딩 실패: $e');
    }
  }

  void _handleSendPressed() {
    final text = _textController.text;
    if (text.isNotEmpty) {
      _chatService.sendMessage(text);
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _chatService.dispose(); // ChatService 정리
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.roomName)),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                // DTO에 sender ID가 있다고 가정하고, 나의 ID와 비교
                final isMe = message.nickname == myUserId;
                // 타입에 따라 다른 위젯을 보여주는 로직 (이전 답변과 동일)
                switch (message.type) {
                  case MessageType.TALK:
                  case MessageType.IMAGE:
                    return _buildTalkBubble(message, isMe: isMe);
                  case MessageType.ENTER:
                  case MessageType.LEAVE:
                    return _buildSystemMessage(message.message);
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
          // 메시지 입력창 UI
          _buildMessageComposer(),
        ],
      ),
    );
  }

  // 메시지 입력 위젯
  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration.collapsed(hintText: '메시지를 입력하세요...'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _handleSendPressed,
          ),
        ],
      ),
    );
  }

  // 아래는 UI를 그리는 위젯들 (이전 답변과 동일, 필요 시 isMe 로직만 추가)
  Widget _buildSystemMessage(String message) {
    // ✨✨✨ 이 부분을 채워넣습니다. ✨✨✨
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
  // 일반 대화 메시지를 위한 말풍선 위젯
  Widget _buildTalkBubble(ChatMessage message, {required bool isMe}) {
    // ✨✨✨ 이 부분을 채워넣습니다. ✨✨✨
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64.0 : 16.0,
        right: isMe ? 16.0 : 64.0,
        top: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe) Text(message.nickname ?? '알수없음', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: message.type == MessageType.IMAGE
                ? Image.network(message.message)
                : Text(message.message),
          ),
        ],
      ),
    );
  }
}