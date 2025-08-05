import 'dart:math';

import 'package:flutter/material.dart';
import 'package:project/widget/translator.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../provider/auth_provider.dart';
import 'chat_api_service.dart';
import 'chat_model.dart';
import 'chat_screen.dart';
import 'lobby_service.dart';

// ✨ StatefulWidget을 그대로 사용합니다.
class ChatRoomListScreen extends StatefulWidget {
  const ChatRoomListScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomListScreen> createState() => _ChatRoomListScreenState();
}

class _ChatRoomListScreenState extends State<ChatRoomListScreen> {
  // 채팅방 목록 데이터를 저장할 Future 상태 변수
  late Future<List<ChatRoom>> _chatRoomsFuture;
  LobbyService? _lobbyService;

  // initState: 위젯이 처음 생성될 때 딱 한 번 호출
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatRooms();
      _initializeLobbyService(); // ✨ 로비 서비스 초기화
    });
  }

  void _initializeLobbyService() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      _lobbyService = LobbyService(onLobbyUpdate: () {
        // ✨ 서버에서 신호가 오면, 목록을 다시 불러옴
        if (mounted) {
          _loadChatRooms();
        }
      });
      _lobbyService!.connectAndSubscribe(authProvider.token!);
    }
  }

  @override
  void dispose() {
    _lobbyService?.dispose(); // ✨ 화면 나갈 때 연결 해제
    super.dispose();
  }

  // 데이터를 불러오는 로직
  void _loadChatRooms() {
    // ✨ Provider를 사용하여 AuthProvider에 접근합니다.
    // ✨ listen: false는 build 메서드 밖에서 상태를 읽을 때 불필요한 재빌드를 막는 최적화 옵션입니다.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoggedIn && authProvider.userProfile != null) {
      // 로그인 상태일 때만 API를 호출
      setState(() {
        _chatRoomsFuture =
            ChatApiService.getChatRooms(authProvider.userProfile!.username);
      });
    } else {
      // 로그인 상태가 아닐 경우, 에러를 포함한 Future를 생성
      setState(() {
        _chatRoomsFuture = Future.error('로그인이 필요합니다.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.chatRoomList,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChatRooms, // 새로고침 버튼
          ),
        ],
      ),
      body: FutureBuilder<List<ChatRoom>>(
        future: _chatRoomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(l10n.chatMessage));
          } else {
            final chatRooms = snapshot.data!;
            return ListView.separated(
              itemCount: chatRooms.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final room = chatRooms[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${room.participantCount}'),
                  ),
                  title: TranslatedText(
                      text: room.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(children: [
                    Text('${l10n.chatRoomCreator}: '),
                    TranslatedText(text: room.creatorNickname),
                  ]),
                  trailing: room.unreadCount > 0
                      ? Chip(
                          label: Text('${room.unreadCount}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          backgroundColor: Colors.redAccent,
                        )
                      : null,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          roomId: room.id,
                          roomName: room.title,
                        ),
                      ),
                    );
                    if (mounted) {
                      _loadChatRooms();
                    }
                  },
                );
              },
            );
          }
        },
      ),
      // ✨ 2. 여기에 디버그 화면으로 가는 플로팅 액션 버튼을 추가합니다.
      // floatingActionButton: FloatingActionButton(
      //   tooltip: '연결 디버그', // 버튼을 길게 누르면 나오는 설명
      //   child: const Icon(Icons.bug_report), // 벌레 모양 아이콘
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       // DebugTokenScreen으로 이동하는 경로를 설정합니다.
      //       MaterialPageRoute(builder: (context) => DebugTokenScreen()),
      //     );
      //   },
      // ),
    );
  }
}
