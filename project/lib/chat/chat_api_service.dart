import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import './chat_model.dart';
import 'package:project/api_client.dart';

class ChatApiService {
  // static const String _baseUrl = "http://arirangtrail.duckdns.org"; // 실제 서버 주소로 변경
  // static const _baseUrl = dotenv.env['PROD_API_BASE_URL'];
  //   static final _baseUrl = dotenv.env['DEV_API_BASE_URL'];
  // static const String _baseUrl = "http://10.0.2.2:8080";
  static final ApiClient _apiClient = ApiClient();

  // 모든 채팅방 목록을 가져오는 메서드
  static Future<List<ChatRoom>> getChatRooms(String username) async {
    // 수정 전: final response = await http.get(Uri.parse('$_baseUrl/chat/rooms'));

    // ✨ 수정 후: username 파라미터를 추가하여 호출
    // final uri = Uri.parse('$_baseUrl/api/chat/rooms').replace(queryParameters: {'username': username});
    // final response = await http.get(uri);
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
    // 수정 전: final response = await http.get(Uri.parse('$_baseUrl/chat/rooms/${roomId.toString()}/messages'));
    // ✨ 수정 후: /api 경로 추가
    // final response = await http.get(Uri.parse('$_baseUrl/api/chat/rooms/${roomId.toString()}/messages'));

    final response = await _apiClient.get('api/chat/rooms/${roomId.toString()}/messages');

    if (response.statusCode == 200) {
      final List<dynamic> messages = json.decode(utf8.decode(response.bodyBytes));
      return messages.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception('메시지 내역을 불러오는데 실패했습니다.');
    }
  }

  static Future<void> updateLastReadSequence(int roomId, String username, int lastReadSeq) async {
    // final baseUrl = dotenv.env['DEV_API_BASE_URL'];
    // final response = await http.post(
    //   Uri.parse('$baseUrl/api/chat/rooms/update-status'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({
    //     'roomId': roomId,
    //     'username': username,
    //     'lastReadSeq': lastReadSeq,
    //   }),
    // );

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