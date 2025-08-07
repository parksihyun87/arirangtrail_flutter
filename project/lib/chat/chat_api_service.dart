// ChatApiService.dart (리팩토링 완료)

import './chat_model.dart';
import 'package:project/api_client.dart'; // 전역 apiClient 인스턴스를 사용합니다.

class ChatApiService {
  // static final ApiClient _apiClient = ApiClient(); // 로컬 인스턴스 생성 코드는 삭제합니다.

  // 모든 채팅방 목록을 가져오는 메서드
  static Future<List<ChatRoom>> getChatRooms(String username,{int retryCount = 0}) async {
    try {
      // 1. GET 요청을 queryParameters를 사용하도록 수정
      final response = await apiClient.get(
        'api/chat/rooms'/*,
        queryParameters: {'username': username},*/
      );

      if (response.statusCode == 200) {
        // 2. response.data를 직접 사용 (이미 List<dynamic> 타입)
        final List<dynamic> rooms = response.data;

        // if (rooms.isEmpty && retryCount == 0) {
        //   print("⚠️ 채팅방 목록이 비어있어 1초 후 재시도합니다.");
        //   await Future.delayed(const Duration(seconds: 1));
        //   return getChatRooms(username, retryCount: 1); // 재귀 호출
        // }

        return rooms.map((json) => ChatRoom.fromJson(json)).toList();
      } else {
        // dio는 2xx가 아닌 상태코드에서 예외를 발생시키므로 이 부분은 예방적으로 둡니다.
        throw Exception('채팅방 목록을 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      // DioException 등 네트워크 오류를 처리
      print('getChatRooms 오류: $e');
      throw Exception('채팅방 목록을 불러오는 중 오류가 발생했습니다.');
    }
  }

  // 특정 채팅방의 과거 메시지를 가져오는 메서드
  static Future<List<ChatMessage>> getChatHistory(int roomId) async {
    try {
      // 로컬 _apiClient 대신 전역 apiClient를 사용
      final response = await apiClient.get('api/chat/rooms/${roomId.toString()}/messages');

      if (response.statusCode == 200) {
        // response.data를 직접 사용
        final List<dynamic> messages = response.data;
        return messages.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('메시지 내역을 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('getChatHistory 오류: $e');
      throw Exception('메시지 내역을 불러오는 중 오류가 발생했습니다.');
    }
  }

  // 마지막으로 읽은 메시지 시퀀스를 업데이트하는 메서드
  static Future<void> updateLastReadSequence(int roomId, String username, int lastReadSeq) async {
    try {
      // 3. POST 요청을 data 파라미터를 사용하도록 수정
      final response = await apiClient.post(
        'api/chat/rooms/update-status',
        data: {
          'roomId': roomId,
          'username': username,
          'lastReadSeq': lastReadSeq,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('읽음 상태 업데이트 실패. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('updateLastReadSequence 오류: $e');
      // 이 오류는 사용자에게 직접 보여줄 필요는 없을 수 있으므로,
      // 조용히 로그만 남기고 넘어갈 수 있습니다.
      // throw Exception('읽음 상태 업데이트 중 오류가 발생했습니다.');
    }
  }
}