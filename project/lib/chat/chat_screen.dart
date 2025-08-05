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
  int _lastReadSeq = 0;

  // 핵심: ChatService 인스턴스
  late final ChatService _chatService;

  @override
// _ChatScreenState 클래스 안

  @override
  void initState() {
    super.initState(); // 항상 initState의 맨 처음에 super.initState()를 호출해야 합니다.

    // --- 1. 기본 정보 설정 ---
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    myUserId = authProvider.userProfile?.username ?? '';
    final myNickname = authProvider.userProfile?.nickname ?? '알수없음';
    final token = authProvider.token;

    // --- 2. 서비스 초기화 ---
    // 토큰이 있을 경우에만 ChatService를 초기화하고 모든 로직을 실행합니다.
    if (token != null) {
      _chatService = ChatService(
        roomId: widget.roomId,
        jwtToken: token,
        senderId: myUserId,
        senderNickname: myNickname,
      );
      _chatService.connect();

      // --- 3. 실시간 메시지 수신 준비 ---
      // ✨ 바로 여기에 stream.listen 코드가 위치합니다.
      _chatService.messageStream.listen((newMessage) {
        if (mounted) {
          setState(() { _messages.insert(0, newMessage); });
          // ✨ 새 메시지를 받을 때마다 _lastReadSeq를 조용히 업데이트만 합니다.
          if (newMessage.messageSeq != null && newMessage.messageSeq! > _lastReadSeq) {
            _lastReadSeq = newMessage.messageSeq!;
          }
        }
      });

      // --- 4. 과거 데이터 로딩 ---
      _fetchChatHistory();

    } else {
      // 토큰이 없을 경우 (비정상적인 접근)
      print('오류: 토큰이 없어서 채팅 서비스에 연결할 수 없습니다.');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
        // TODO: 사용자에게 "로그인이 필요합니다" 같은 메시지를 보여주고 이전 화면으로 돌려보내는 로직 추가
      }
    }
  }

  Future<void> _fetchChatHistory() async {
    try {
      // 1. 서버로부터 과거 메시지를 받습니다. (순서: [과거, ..., 최신])
      final history = await ChatApiService.getChatHistory(widget.roomId);

      if (mounted) {
        // 2. 읽음 처리: history가 비어있지 않다면, 가장 마지막 요소(가장 최신)의 seq를 사용합니다.
        if (history.isNotEmpty) {
          _lastReadSeq = history.last.messageSeq ?? 0;
        }

        // 3. UI 업데이트: 화면 표시를 위해 리스트를 뒤집어서 _messages에 추가합니다.
        setState(() {
          _messages.addAll(history.reversed); // (순서: [최신, ..., 과거])
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      setState(() { _isLoadingHistory = false; });
      print('과거 메시지 로딩 실패: $e');
    }
  }


  // ✨ 이 함수는 이제 dispose에서만 사용됩니다.
  void _updateReadStatus() {
    if (_lastReadSeq > 0) {
      print(">>>>> 퇴장 시 읽음 처리: Room ${widget.roomId}, Seq $_lastReadSeq");
      ChatApiService.updateLastReadSequence(widget.roomId, myUserId, _lastReadSeq);
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
    _updateReadStatus();
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
                final isMe = message.sender == myUserId;
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