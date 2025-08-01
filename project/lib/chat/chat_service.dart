import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import './chat_model.dart';

class ChatService {
  late StompClient _stompClient;
  final int roomId;
  final String jwtToken;

  ChatService({required this.roomId, required this.jwtToken});

  // UI가 구독(listen)할 수 있는 메시지 스트림 컨트롤러
  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  void connect() {
    // ✨ 수정 1: WebSocket URL을 정확하게 설정
    final String websocketUrl = 'ws://arirangtrail.duckdns.org/ws-stomp';

    // ✨ Bearer 중복 방지
    final String cleanToken = jwtToken.startsWith('Bearer ') ? jwtToken : 'Bearer $jwtToken';

    print('WebSocket 연결 시도: $websocketUrl');
    print('JWT 토큰: ${cleanToken.substring(0, 20)}...');

    _stompClient = StompClient(
      config: StompConfig(
        url: websocketUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          print('WebSocket 에러: $error');
          // TODO: UI에 에러 상태 전달
        },
        onStompError: (StompFrame frame) {
          print('STOMP 에러: ${frame.body}');
          // TODO: UI에 에러 상태 전달
        },
        onDisconnect: (StompFrame frame) {
          print('STOMP 연결 해제: ${frame.body}');
        },
        // ✨ 수정 2: 헤더 설정 개선
        stompConnectHeaders: {
          'Authorization': cleanToken,
          'heart-beat': '10000,10000',
        },
        webSocketConnectHeaders: {
          'Authorization': cleanToken,
        },
        // ✨ 수정 3: 연결 재시도 및 타임아웃 설정
        reconnectDelay: Duration(seconds: 5),
        heartbeatIncoming: Duration(seconds: 10),
        heartbeatOutgoing: Duration(seconds: 10),
      ),
    );

    _stompClient.activate();
  }

  void _onConnect(StompFrame frame) {
    print('STOMP 연결 성공!');

    // ✨ 수정 4: 구독 경로 확인 및 에러 처리 개선
    final subscriptionDestination = '/sub/chat/room/$roomId';
    print('구독 시작: $subscriptionDestination');

    _stompClient.subscribe(
      destination: subscriptionDestination,
      callback: (frame) {
        print('메시지 수신: ${frame.body}');
        if (frame.body != null) {
          try {
            // 수신된 JSON을 ChatMessage 객체로 변환
            final messageData = json.decode(frame.body!);
            print('파싱된 메시지 데이터: $messageData');

            final newMessage = ChatMessage.fromJson(messageData);
            // 스트림에 새 메시지를 추가하여 UI에 알립니다.
            _messageController.add(newMessage);
            print('메시지 스트림에 추가 완료');
          } catch (e) {
            print('메시지 파싱 에러: $e');
            print('원본 메시지: ${frame.body}');
          }
        }
      },
    );

    print('구독 완료: $subscriptionDestination');
  }

  // 메시지 전송 (쓰기 기능)
  void sendMessage(String messageContent) {
    if (_stompClient.connected) {
      final message = {
        'type': 'TALK',
        'roomId': roomId,
        'message': messageContent,
        // 'sender'와 'nickname'은 서버가 토큰을 보고 채워줄 것이므로 보내지 않음
      };

      print('메시지 전송: $message');

      _stompClient.send(
        destination: '/pub/chat/message',
        body: json.encode(message),
      );
    } else {
      print('STOMP 클라이언트가 연결되지 않았습니다.');
    }
  }

  void dispose() {
    // 서비스가 더 이상 필요 없을 때 연결을 끊고 스트림을 닫습니다.
    print('ChatService 정리 시작...');
    _stompClient.deactivate();
    _messageController.close();
    print('ChatService 정리 완료');
  }
}