// lobby_service.dart (stomp_dart_client로 전체 리팩토링)

import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class LobbyService {
  final Function onLobbyUpdate;
  final String jwtToken; // ✨ 토큰을 생성자에서 받도록 변경

  StompClient? _stompClient;
  void Function()? _unsubscribeCallback;

  LobbyService({required this.onLobbyUpdate, required this.jwtToken}); // ✨ 토큰 추가

  void connectAndSubscribe() { // ✨ 파라미터에서 토큰 제거
    final wsUrl = dotenv.env['PROD_WS_FLUTTER_URL'];
    if (wsUrl == null) {
      print("LobbyService: .env 파일에서 DEV_WS_FLUTTER_URL을 찾을 수 없습니다.");
      return;
    }
    final pureToken = jwtToken.startsWith('Bearer ') ? jwtToken.substring(7) : jwtToken;

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnectCallback,
        stompConnectHeaders: {'Authorization': 'Bearer $pureToken'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $pureToken'},
        onWebSocketError: (dynamic error) => print("[Lobby] 웹소켓 오류: $error"),
        onStompError: (StompFrame frame) => print("[Lobby] STOMP 오류: ${frame.body}"),
      ),
    );

    print("✅ [LobbyService] StompClient 활성화 시도...");
    _stompClient!.activate();
  }

  void _onConnectCallback(StompFrame frame) {
    print("🎉 [LobbyService] STOMP 연결 성공! 로비 구독을 시작합니다.");
    _unsubscribeCallback = _stompClient?.subscribe(
      destination: '/sub/chat/lobby',
      callback: (frame) {
        print("[LobbyService] 메시지 수신!");
        try {
          final data = json.decode(frame.body!);
          if (data['type'] == 'LOBBY_ROOM_UPDATE') {
            print("✅ [LobbyService] 로비 업데이트 신호 수신!");
            onLobbyUpdate();
          }
        } catch(e) {
          print("[LobbyService] 메시지 파싱 에러: $e");
        }
      },
    );
  }

  void dispose() {
    _unsubscribeCallback?.call();
    _stompClient?.deactivate();
    print("[LobbyService] 서비스 정리 완료.");
  }
}