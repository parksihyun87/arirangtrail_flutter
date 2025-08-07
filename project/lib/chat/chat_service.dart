
import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import './chat_model.dart';

class ChatService {
  final int roomId;
  final String jwtToken;
  final String senderId;
  final String senderNickname;

  // StompClient 인스턴스를 저장할 변수
  StompClient? _stompClient;
  // 구독 해지를 위한 콜백 함수를 저장
  void Function()? _unsubscribeCallback;

  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  ChatService({
    required this.roomId,
    required this.jwtToken,
    required this.senderId,
    required this.senderNickname,
  });

  void connect() {
    final wsUrl = dotenv.env['PROD_WS_FLUTTER_URL'];
    if (wsUrl == null) {
      print("DEV_WS_FLUTTER_URL을 .env 파일에서 찾을 수 없습니다.");
      return;
    }

    final pureToken = jwtToken.startsWith('Bearer ') ? jwtToken.substring(7) : jwtToken;

    // ✨ StompClient 인스턴스 생성
    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnectCallback, // 연결 성공 시 호출될 함수
        onWebSocketError: (dynamic error) => print("웹소켓 오류: $error"),
        onStompError: (StompFrame frame) => print("STOMP 프로토콜 오류: ${frame.body}"),
        onDisconnect: (StompFrame frame) => print("웹소켓 연결 끊어짐."),

        // ✨✨✨ 가장 중요한 부분: CONNECT 프레임에 인증 헤더 추가 ✨✨✨
        // 서버의 StompHandler가 이 헤더를 검사합니다.
        stompConnectHeaders: {
          'Authorization': 'Bearer $pureToken',
        },
        // 웹소켓 자체의 연결 헤더 (필요 시 사용)
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $pureToken',
        },
      ),
    );

    // 연결 활성화
    print("✅ StompClient 활성화 시도...");
    _stompClient!.activate();
  }

  // 연결 성공 후 실행되는 콜백 함수
  void _onConnectCallback(StompFrame frame) {
    print("🎉 STOMP 연결 성공! 채팅방 구독을 시작합니다.");

    // 채팅방 구독 시작
    _unsubscribeCallback = _stompClient?.subscribe(
      destination: '/sub/chat/room/$roomId',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final chatMessage = ChatMessage.fromJson(json.decode(frame.body!));
            _messageController.add(chatMessage);
          } catch (e) {
            print("메시지 파싱 에러: $e");
          }
        }
      },
    );
  }

  // 메시지 전송
  void sendMessage(String messageContent) {
    if (_stompClient == null || !_stompClient!.connected) {
      print("❌ 메시지 전송 실패: STOMP 클라이언트가 연결되지 않았습니다.");
      return;
    }

    final messagePayload = {
      'type': 'TALK',
      'roomId': roomId,
      'sender': senderId,
      'nickname': senderNickname,
      'message': messageContent,
    };

    // 서버의 @MessageMapping 경로와 일치해야 함 (/api/pub 접두사 포함)
    _stompClient!.send(
      destination: '/api/pub/chat/message',
      body: json.encode(messagePayload),
      headers: {'content-type': 'application/json'},
    );
    print("메시지 전송: $messageContent");
  }

  // 서비스 정리
  void dispose() {
    // 구독 해지
    _unsubscribeCallback?.call();
    // 연결 비활성화
    _stompClient?.deactivate();
    _messageController.close();
    print("ChatService 정리 완료.");
  }
}