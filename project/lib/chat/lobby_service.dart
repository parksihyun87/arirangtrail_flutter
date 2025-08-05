// lobby_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LobbyService {
  WebSocketChannel? _channel;
  StreamSubscription? _streamSubscription; // ✨ 스트림 구독 관리를 위해 추가
  final Function onLobbyUpdate;

  LobbyService({required this.onLobbyUpdate});

  void connectAndSubscribe(String token) {
    final wsUrl = dotenv.env['PROD_WS_FLUTTER_URL'];
    if (wsUrl == null) {
      print("LobbyService: .env 파일에서 DEV_WS_FLUTTER_URL을 찾을 수 없습니다.");
      return;
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      print("✅ [LobbyService] 웹소켓 채널 연결 시도...");

      // ✨ stream.listen을 변수에 저장하여 나중에 취소(cancel)할 수 있도록 합니다.
      _streamSubscription = _channel!.stream.listen((message) {
        print("[LobbyService] 메시지 수신: $message");
        if (message.toString().startsWith('CONNECTED')) {
          print("🎉 [LobbyService] STOMP 연결 성공! 로비 구독을 시작합니다.");
          _subscribeToLobby();
        }

        // ✨ 서버가 보내주는 Map 형태의 JSON을 정확히 파싱합니다.
        if (message.toString().startsWith('MESSAGE')) {
          try {
            final bodyIndex = message.indexOf('\n\n');
            if (bodyIndex != -1) {
              final jsonBody = message.substring(bodyIndex).trim().replaceAll('\x00', '');
              final data = json.decode(jsonBody);
              // 서버가 보낸 메시지 타입이 'LOBBY_ROOM_UPDATE'가 맞는지 확인합니다.
              if (data['type'] == 'LOBBY_ROOM_UPDATE') {
                print("✅ [LobbyService] 로비 업데이트 신호 수신!");
                onLobbyUpdate();
              }
            }
          } catch(e) {
            print("[LobbyService] 메시지 파싱 에러: $e");
          }
        }
      });

      // ✨ 1. ChatService와 동일한 인증용 CONNECT 프레임을 만듭니다.
      final cleanToken = token.startsWith('Bearer ') ? token : 'Bearer $token';
      final connectFrame = 'CONNECT\n'
          'Authorization:$cleanToken\n'
          'accept-version:1.0,1.1,2.0\n'
          'heart-beat:10000,10000\n\n\x00';

      // ✨ 2. 프레임을 서버로 전송합니다.
      _channel!.sink.add(connectFrame);
      print("[LobbyService] CONNECT 프레임 전송 완료.");

    } catch (e) {
      print("❌ [LobbyService] 웹소켓 연결 에러: $e");
    }
  }

  void _subscribeToLobby() {
    final subscribeFrame = 'SUBSCRIBE\n'
        'id:sub-lobby\n' // 구독 ID
        'destination:/sub/chat/lobby\n\n\x00';
    _channel!.sink.add(subscribeFrame);
    print("[LobbyService] 로비 구독 프레임 전송.");
  }

  void dispose() {
    // ✨ 화면 나갈 때 스트림 구독과 채널을 모두 안전하게 닫습니다.
    _streamSubscription?.cancel();
    _channel?.sink.close();
    print("[LobbyService] 서비스 정리 완료.");
  }
}