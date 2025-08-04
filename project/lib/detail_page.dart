import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/widget/festival_map.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:project/widget/translator.dart';
import 'festival_model.dart';

const SERVICE_KEY =
    "WCIc8hzzBS3Jdod%2BVa357JmB%2FOS0n4D2qPHaP9PkN4bXIfcryZyg4iaZeTj1fEYJ%2B8q2Ol8FIGe3RkW3d72FHA%3D%3D";

// 1. 데이터를 하나로 묶어줄 새로운 클래스 정의
class FestivalPageData {
  final FestivalDetail detail;
  final List<FestivalImage> images;
  final LatLng? location;
  final Set<Marker> markers;

  FestivalPageData({
    required this.detail,
    required this.images,
    this.location,
    required this.markers,
  });
}

// ✨ 2. 커스텀 캐시 매니저 정의
final CacheManager customCacheManager = CacheManager(
  Config(
    'customImageCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 200,
  ),
);

class DetailPage extends StatefulWidget {
  final String festivalId;
  final String initialTitle;

  const DetailPage(
      {super.key, required this.festivalId, required this.initialTitle});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<FestivalPageData> _festivalDataFuture;

  @override
  void initState() {
    super.initState();
    _festivalDataFuture = _fetchDetails();
    _debugCurrentLocation();
  }

  Future<FestivalPageData> _fetchDetails() async {
    try {
      final commonUri = Uri.parse(
          'https://apis.data.go.kr/B551011/KorService2/detailCommon2?serviceKey=$SERVICE_KEY&MobileApp=AppTest&MobileOS=ETC&_type=json&contentId=${widget.festivalId}');
      final introUri = Uri.parse(
          'https://apis.data.go.kr/B551011/KorService2/detailIntro2?serviceKey=$SERVICE_KEY&MobileApp=AppTest&MobileOS=ETC&_type=json&contentId=${widget.festivalId}&contentTypeId=15');
      final imageUri = Uri.parse(
          'https://apis.data.go.kr/B551011/KorService2/detailImage2?serviceKey=$SERVICE_KEY&MobileApp=AppTest&MobileOS=ETC&_type=json&contentId=${widget.festivalId}&imageYN=Y');

      final responses = await Future.wait([
        http.get(commonUri),
        http.get(introUri),
        http.get(imageUri),
      ]);

      final commonData = _getSafeItem(responses[0]);
      if (commonData == null) {
        final decoded = jsonDecode(responses[0].body);
        throw Exception(
            '필수 상세 정보(Common)를 찾을 수 없습니다: ${decoded['response']?['header']?['resultMsg'] ?? 'Unknown error'}');
      }

      final introData =
          (responses[1].statusCode == 200) ? _getSafeItem(responses[1]) : null;
      final imageDataList = (responses[2].statusCode == 200)
          ? _getSafeListOfItems(responses[2])
          : [];

      final detail = FestivalDetail.fromJsons(commonData, introData ?? {});
      final images =
          imageDataList.map((item) => FestivalImage.fromJson(item)).toList();

      final lat = double.tryParse(detail.mapy);
      final lng = double.tryParse(detail.mapx);
      LatLng? location;
      Set<Marker> markers = {};

      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        location = LatLng(lat, lng);
        markers.add(Marker(
          markerId: MarkerId(detail.contentid),
          position: location,
          infoWindow: InfoWindow(title: detail.title),
        ));
      }

      return FestivalPageData(
          detail: detail, images: images, location: location, markers: markers);
    } catch (e) {
      print('상세 정보 로딩 실패: $e');
      rethrow;
    }
  }

  Future<void> _debugCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ 위치 서비스 꺼짐");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ 위치 권한 없음");
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("📍 현재 위치 (디버그): ${position.latitude}, ${position.longitude}");
    } catch (e) {
      print("❌ 위치 가져오기 실패: $e");
    }
  }

  Map<String, dynamic>? _getSafeItem(http.Response response) {
    if (response.statusCode != 200) return null;
    try {
      final decoded = jsonDecode(response.body);
      final body = decoded['response']?['body'];
      final item = body?['items']?['item'];
      return (item is List) ? (item.isNotEmpty ? item[0] : null) : item;
    } catch (e) {
      print('JSON 파싱 오류: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _getSafeListOfItems(http.Response response) {
    if (response.statusCode != 200) return [];
    final decoded = jsonDecode(response.body);
    final body = decoded['response']?['body'];
    final item = body?['items']?['item'];
    if (item is List) {
      return item.whereType<Map<String, dynamic>>().toList();
    } else if (item is Map) {
      return [item.cast<String, dynamic>()];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(text: widget.initialTitle),
        centerTitle: true,
      ),
      body: FutureBuilder<FestivalPageData>(
        future: _festivalDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('표시할 데이터가 없습니다.'));
          }
          final festivalData = snapshot.data!;
          return _buildDetailContent(festivalData);
        },
      ),
    );
  }

  Widget _buildDetailContent(FestivalPageData data) {
    final detail = data.detail;
    final allImages = [
      if (detail.firstimage.isNotEmpty) detail.firstimage,
      ...data.images.map((img) => img.originimgurl)
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            child: Swiper(
              itemCount: allImages.length,
              loop: false,
              viewportFraction: 1.0,
              scale: 1.0,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  cacheManager: customCacheManager,
                  imageUrl: allImages[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              },
              pagination: const SwiperPagination(),
              control: const SwiperControl(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                    text: detail.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TranslatedText(
                    text: detail.overview
                        .replaceAll('<br>', '\n')
                        .replaceAll(RegExp('<[^>]*>'), ''),
                    style: Theme.of(context).textTheme.bodyMedium),
                const Divider(height: 32),
                _buildInfoRow(Icons.calendar_today, '행사 기간',
                    '${detail.eventstartdate} ~ ${detail.eventenddate}'),
                if (detail.playtime.isNotEmpty)
                  _buildInfoRow(Icons.access_time, '공연 시간', detail.playtime),
                if (detail.usetimefestival.isNotEmpty)
                  _buildInfoRow(Icons.payment, '이용 요금', detail.usetimefestival),
                if (detail.tel.isNotEmpty)
                  _buildInfoRow(Icons.phone, '전화번호', detail.tel),
                const SizedBox(height: 24),
                Text('오시는 길', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TranslatedText(text: detail.addr1),
                const SizedBox(height: 16),
                data.location != null
                    ? StaticFestivalMap(
                        location: data.location!, markers: data.markers)
                    : Container(
                        height: 200,
                        alignment: Alignment.center,
                        color: Colors.grey[200],
                        child: const Text('지도 정보를 제공하지 않습니다.'),
                      ),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () => _showDirectionsDialog(context, detail),
                    child: const Text('길찾기')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TranslatedText(
                    text: value
                        .replaceAll('<br>', '\n')
                        .replaceAll(RegExp('<[^>]*>'), '')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDirectionsDialog(
      BuildContext context, FestivalDetail destination) async {
    if (destination.mapx == '0.0' || destination.mapy == '0.0') {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('알림'),
                content: const Text('이 장소는 길찾기를 지원하지 않습니다.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('확인'))
                ],
              ));
      return;
    }

    final String? mapType = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('어떤 지도로 길을 찾으시겠어요?'),
        content: TranslatedText(text: destination.title),
        actions: [
          TextButton(
              child: const Text('카카오맵'),
              onPressed: () => Navigator.of(dialogContext).pop('kakao')),
          TextButton(
              child: const Text('구글맵'),
              onPressed: () => Navigator.of(dialogContext).pop('google')),
        ],
      ),
    );

    if (mapType == 'kakao') {
      final url = Uri.parse(
          'https://map.kakao.com/link/to/${destination.title},${destination.mapy},${destination.mapx}');
      if (await canLaunchUrl(url)) await launchUrl(url);
    } else if (mapType == 'google') {
      await _launchGoogleMapsDirections(destination.mapy, destination.mapx);
    }
  }

  Future<void> _launchGoogleMapsDirections(String lat, String lng) async {
    if (!mounted) return;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('위치 서비스를 활성화해주세요.')));
        return;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('위치 권한이 거부되었습니다.')));
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요.')));
        return;
      }
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
      print('Current Position: ${position.latitude}, ${position.longitude}');

      if (!mounted) return;

      final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}&destination=$lat,$lng');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('구글 맵을 열 수 없습니다.')));
        }
      }
    } catch (e) {
      print('Failed to get position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('현재 위치를 가져올 수 없습니다.')));
      }
    }
  }
}
