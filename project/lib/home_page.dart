import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:project/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _fetchedImages = [];
  bool _isLoading = true;
  String? _error;
  PageController _pageController = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchFestivalImages();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startImageSlider() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= _fetchedImages.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchFestivalImages() async {
    const SERVICE_KEY =
        "WCIc8hzzBS3Jdod%2BVa357JmB%2FOS0n4D2qPHaP9PkN4bXIfcryZyg4iaZeTj1fEYJ%2B8q2Ol8FIGe3RkW3d72FHA%3D%3D";
    final today = DateTime.now();
    final eventStartDate =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    final String apiUrl =
        'https://apis.data.go.kr/B551011/KorService2/searchFestival2?serviceKey=$SERVICE_KEY&MobileApp=AppTest&MobileOS=ETC&_type=json&numOfRows=50&pageNo=1&arrange=A&eventStartDate=$eventStartDate';
    final uri = Uri.parse(apiUrl);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dynamic rawItems = data['response']?['body']?['items']?['item'];
        List<dynamic> items = [];
        if (rawItems is List) {
          items = rawItems;
        } else if (rawItems is Map) {
          items = [rawItems];
        }
        final List<String> imageUrls = items
            .map<String?>((item) => item['firstimage'] as String?)
            .where((url) => url != null && url.isNotEmpty)
            .map((url) => url!)
            .toList();
        setState(() {
          if (imageUrls.isNotEmpty) {
            _fetchedImages = imageUrls;
            _startImageSlider();
          } else {
            _error = "표시할 축제 이미지가 없습니다.";
          }
          _isLoading = false;
        });
      } else {
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오는 데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_fetchedImages.isEmpty) return Center(child: Text(l10n.noImages));
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _fetchedImages.length,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: _fetchedImages[index],
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image),
            );
          },
        ),
        Container(color: Colors.black.withOpacity(0.4)),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l10n.homeTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  l10n.homeSubtitle,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
