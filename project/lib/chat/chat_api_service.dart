import 'dart:convert';
import './chat_model.dart';
import 'package:project/api_client.dart';

class ChatApiService {

  static final ApiClient _apiClient = ApiClient();

  // 모든 채팅방 목록을 가져오는 메서드
  static Future<List<ChatRoom>> getChatRooms(String username) async {

    final response = await _apiClient.get('api/chat/rooms?username=$username');

    if (response.statusCode == 200) {
      // UTF-8로 디코딩해야 한글이 깨지지 않습니다.
      final List<dynamic> rooms = json.decode(utf8.decode(response.bodyBytes));
      return rooms.map((json) => ChatRoom.fromJson(json)).toList();
    } else {
      throw Exception('채팅방 목록을 불러오는데 실패했습니다.');
    }
  }

  // 특정 채팅방의 과거 메시지를 가져오는 메서드
  static Future<List<ChatMessage>> getChatHistory(int roomId) async {
    final response = await _apiClient.get('api/chat/rooms/${roomId.toString()}/messages');

    if (response.statusCode == 200) {
      final List<dynamic> messages = json.decode(utf8.decode(response.bodyBytes));
      return messages.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception('메시지 내역을 불러오는데 실패했습니다.');
    }
  }

  static Future<void> updateLastReadSequence(int roomId, String username, int lastReadSeq) async {

    final response = await _apiClient.post('api/chat/rooms/update-status', {
      'roomId': roomId,
      'username': username,
      'lastReadSeq': lastReadSeq,
    });
    if (response.statusCode != 200) {
      throw Exception('읽음 상태 업데이트 실패');
    }
  }

}