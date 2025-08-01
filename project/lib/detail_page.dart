import 'dart:convert';

// import 'package:flutter/cupertino.dart'; //ios 설정 시
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:project/widget/translator.dart';
import 'festival_model.dart';

const SERVICE_KEY =
    "WCIc8hzzBS3Jdod%2BVa357JmB%2FOS0n4D2qPHaP9PkN4bXIfcryZyg4iaZeTj1fEYJ%2B8q2Ol8FIGe3RkW3d72FHA%3D%3D";

class DetailPage extends StatefulWidget {
  final String festivalId;
  final String initialTitle;

  const DetailPage(
      {super.key, required this.festivalId, required this.initialTitle});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  FestivalDetail? _festivalDetail;
  List<FestivalImage> _images = [];
  bool _isLoading = true;
  String? _error;
  LatLng? _festivalLocation;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
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

      print(
          'Common Response: ${responses[0].statusCode} - ${responses[0].body}');
      print(
          'Intro Response: ${responses[1].statusCode} - ${responses[1].body}');
      print(
          'Image Response: ${responses[2].statusCode} - ${responses[2].body}');

      final commonData = _getSafeItem(responses[0]);
      final introData =
          (responses[1].statusCode == 200) ? _getSafeItem(responses[1]) : null;
      final imageDataList = (responses[2].statusCode == 200)
          ? _getSafeListOfItems(responses[2])
          : [];

      if (commonData == null) {
        final decoded = jsonDecode(responses[0].body);
        throw Exception(
            '필수 상세 정보(Common)를 찾을 수 없습니다: ${decoded['response']?['header']?['resultMsg'] ?? 'Unknown error'}');
      }

      setState(() {
        _festivalDetail = FestivalDetail.fromJsons(commonData, introData ?? {});
        _images =
            imageDataList.map((item) => FestivalImage.fromJson(item)).toList();
        _setupMapData();
        _isLoading = false;
      });
    } catch (e) {
      print('상세 정보 로딩 실패: $e');
      setState(() {
        _error = '정보를 불러오는 데 실패했습니다.';
        _isLoading = false;
      });
    }
  }

  void _setupMapData() {
    if (_festivalDetail == null) return;

    if (_festivalDetail!.mapx.isEmpty ||
        _festivalDetail!.mapy.isEmpty ||
        _festivalDetail!.mapx == '0.0' ||
        _festivalDetail!.mapy == '0.0') {
      return;
    }

    final lat = double.tryParse(_festivalDetail!.mapy);
    final lng = double.tryParse(_festivalDetail!.mapx);

    if (lat != null && lng != null) {
      _festivalLocation = LatLng(lat, lng);
      _markers.add(Marker(
        markerId: MarkerId(_festivalDetail!.contentid),
        position: _festivalLocation!,
        infoWindow: InfoWindow(title: _festivalDetail!.title),
      ));
    }
  }

  Map<String, dynamic>? _getSafeItem(http.Response response) {
    if (response.statusCode != 200) return null;
    try {
      final decoded = jsonDecode(response.body);
      final body = decoded['response']?['body'];
      if (body == null || body['items'] == '' || body['items'] == null)
        return null;
      final item = body['items']?['item'];
      if (item == null) return null;
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
    if (body == null || body['items'] == '' || body['items'] == null) return [];
    final item = body['items']?['item'];
    if (item == null) return [];
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
        title: TranslatedText(
            text: _isLoading
                ? widget.initialTitle
                : _festivalDetail?.title ?? ''),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildDetailContent(),
    );
  }

  Widget _buildDetailContent() {
    if (_festivalDetail == null) return const Center(child: Text('데이터가 없습니다.'));
    final detail = _festivalDetail!;
    final allImages = [
      if (detail.firstimage.isNotEmpty) detail.firstimage,
      ..._images.map((img) => img.originimgurl)
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            child: Swiper(
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
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
                _festivalLocation != null
                    ? SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                              target: _festivalLocation!, zoom: 15),
                          markers: _markers,
                        ),
                      )
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
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('위치 서비스를 활성화해주세요.')));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('위치 권한이 거부되었습니다.')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요.')));
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('구글 맵을 열 수 없습니다.')));
    }
  }
}
