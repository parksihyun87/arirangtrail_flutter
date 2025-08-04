// ChatService.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import './chat_model.dart'; // ChatMessage 모델 임포트

class ChatService {
  final int roomId;
  final String jwtToken;
  final String senderId;
  final String senderNickname;

  WebSocketChannel? _channel; // 웹소켓 채널을 저장할 변수
  StreamSubscription? _streamSubscription; // 메시지 수신을 위한 구독

  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  ChatService({required this.roomId, required this.jwtToken,required this.senderId, required this.senderNickname});

  // 1. 연결 및 인증
  void connect() {
    // 배포시
    // final wsUrl = dotenv.env['PROD_WS_FLUTTER_URL'];
    // 로컬시
    final wsUrl = dotenv.env['DEV_WS_FLUTTER_URL'];

    if (wsUrl == null) {
      print("PROD_WS_FLUTTER_URL을 .env 파일에서 찾을 수 없습니다.");
      return;
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      print("✅ 웹소켓 채널 연결 시도...");

      // 연결이 성공하면 STOMP CONNECT 프레임을 보냅니다.
      _sendConnectFrame();

      // 서버로부터 오는 메시지를 수신 대기합니다.
      _streamSubscription = _channel!.stream.listen(_onMessageReceived);

    } catch (e) {
      print("❌ 웹소켓 연결 에러: $e");
    }
  }

  // 2. 메시지 수신 처리
  void _onMessageReceived(dynamic message) {
    print("서버로부터 메시지 수신: $message");

    // CONNECTED 프레임을 받으면, 채팅방을 구독합니다.
    if (message.toString().startsWith('CONNECTED')) {
      print("🎉 STOMP 연결 성공! 채팅방 구독을 시작합니다.");
      _subscribeToChatRoom();
    }
    // MESSAGE 프레임을 받으면, 메시지를 파싱하여 스트림에 추가합니다.
    else if (message.toString().startsWith('MESSAGE')) {
      try {
        // STOMP 프레임에서 JSON 본문만 추출
        final bodyIndex = message.indexOf('\n\n');
        if (bodyIndex != -1) {
          final jsonBody = message.substring(bodyIndex).trim().replaceAll('\x00', '');
          final chatMessage = ChatMessage.fromJson(json.decode(jsonBody));
          _messageController.add(chatMessage);
        }
      } catch (e) {
        print("메시지 파싱 에러: $e");
      }
    }
  }

  // 3. 메시지 전송 (채팅 입력)
  void sendMessage(String messageContent) {
    if (_channel != null) {
      final messagePayload = {
        'type': 'TALK',
        'roomId': roomId,
        'sender': senderId,
        'nickname': senderNickname,
        'message': messageContent,
      };

      // STOMP SEND 프레임 구성
      final sendFrame = 'SEND\n'
          'destination:/api/pub/chat/message\n'
          'content-type:application/json\n\n'
          '${json.encode(messagePayload)}\x00';

      _channel!.sink.add(sendFrame);
      print("메시지 전송: $messageContent");
    }
  }

  // 4. 연결 해제
  void dispose() {
    if (_channel != null) {
      // STOMP DISCONNECT 프레임 전송
      _channel!.sink.add('DISCONNECT\n\n\x00');
    }
    _streamSubscription?.cancel();
    _messageController.close();
    _channel?.sink.close();
    print("ChatService 정리 완료.");
  }

  // --- 내부 헬퍼 메소드들 ---
  void _sendConnectFrame() {
    final cleanToken = jwtToken.startsWith('Bearer ') ? jwtToken : 'Bearer $jwtToken';
    final connectFrame = 'CONNECT\n'
        'Authorization:$cleanToken\n'
        'accept-version:1.0,1.1,2.0\n'
        'heart-beat:10000,10000\n\n\x00';
    _channel!.sink.add(connectFrame);
  }

  void _subscribeToChatRoom() {
    final subscribeFrame = 'SUBSCRIBE\n'
        'id:sub-0\n' // 구독 ID
        'destination:/sub/chat/room/$roomId\n\n\x00';
    _channel!.sink.add(subscribeFrame);
    print("채팅방 구독 프레임 전송: /sub/chat/room/$roomId");
  }
}