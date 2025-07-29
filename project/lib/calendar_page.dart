import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'festival_model.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Festival> _allFestivals = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  String _sortOrder = 'views';
  Map<DateTime, List<Festival>> _events = {};

  @override
  void initState() {
    super.initState();
    _fetchFestivals();
  }

  Future<void> _fetchFestivals() async {
    const SERVICE_KEY =
        "WCIc8hzzBS3Jdod%2BVa357JmB%2FOS0n4D2qPHaP9PkN4bXIfcryZyg4iaZeTj1fEYJ%2B8q2Ol8FIGe3RkW3d72FHA%3D%3D";
    final startDate =
        DateTime.now().subtract(const Duration(days: 30)); // 30일 전부터
    final eventStartDate =
        '${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
      'https://apis.data.go.kr/B551011/KorService2/searchFestival2?serviceKey=$SERVICE_KEY&MobileApp=AppTest&MobileOS=ETC&_type=json&numOfRows=150&pageNo=1&arrange=B&eventStartDate=$eventStartDate',
    );

    try {
      final response = await http.get(uri);
      print('CalendarPage API Response Status: ${response.statusCode}');
      print('CalendarPage API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dynamic rawItems = data['response']?['body']?['items']?['item'];
        List<dynamic> items = [];
        if (rawItems is List) {
          items = rawItems;
        } else if (rawItems is Map) {
          items = [rawItems];
        }
        print('CalendarPage Parsed Items: $items');
        if (items.isNotEmpty) {
          final festivals =
              items.map((item) => Festival.fromJson(item)).toList();
          final newEvents = <DateTime, List<Festival>>{};
          for (final festival in festivals) {
            if (festival.eventstartdate.isEmpty ||
                festival.eventenddate.isEmpty) {
              print('Skipping festival due to empty dates: ${festival.title}');
              continue;
            }
            try {
              final startDate =
                  DateFormat('yyyyMMdd').parse(festival.eventstartdate);
              final endDate =
                  DateFormat('yyyyMMdd').parse(festival.eventenddate);
              for (var day = startDate;
                  day.isBefore(endDate.add(const Duration(days: 1)));
                  day = day.add(const Duration(days: 1))) {
                final dayWithoutTime =
                    DateTime.utc(day.year, day.month, day.day);
                if (newEvents[dayWithoutTime] == null)
                  newEvents[dayWithoutTime] = [];
                newEvents[dayWithoutTime]!.add(festival);
              }
            } catch (e) {
              print('Error parsing dates for festival ${festival.title}: $e');
            }
          }
          setState(() {
            _allFestivals = festivals;
            _events = newEvents;
            _isLoading = false;
            print('Events Map: $_events');
          });
        } else {
          setState(() {
            _allFestivals = [];
            _events = {};
            _isLoading = false;
            _error = '해당 기간에 축제 데이터가 없습니다.';
          });
          print('No festivals found for $eventStartDate');
        }
      } else {
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('CalendarPage Error: $e');
      setState(() {
        _isLoading = false;
        _error = '데이터를 불러오는 데 실패했습니다: $e';
      });
    }
  }

  List<Festival> _getEventsForDay(DateTime day) {
    final dayWithoutTime = DateTime.utc(day.year, day.month, day.day);
    print('Fetching events for $dayWithoutTime');
    List<Festival> events = List.from(_events[dayWithoutTime] ?? []);
    print('Events found: $events');
    switch (_sortOrder) {
      case 'name':
        events.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'ending':
        events.sort((a, b) => a.eventenddate.compareTo(b.eventenddate));
        break;
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('월별 축제 달력')),
      body: ListView(
        children: [
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) => setState(() {
              if (isSameDay(_selectedDay, selectedDay)) {
                _selectedDay = null;
              } else {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              }
            }),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _getEventsForDay(day),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  print('Events for $date: $events');
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        '${events.length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(_error!),
              ),
            )
          else if (_selectedDay == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('달력에서 날짜를 선택해주세요.'),
              ),
            )
          else
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy년 MM월 dd일').format(_selectedDay!),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ToggleButtons(
                        isSelected: [
                          _sortOrder == 'views',
                          _sortOrder == 'name',
                          _sortOrder == 'ending',
                        ],
                        onPressed: (index) => setState(() {
                          if (index == 0) _sortOrder = 'views';
                          if (index == 1) _sortOrder = 'name';
                          if (index == 2) _sortOrder = 'ending';
                        }),
                        constraints: const BoxConstraints(
                            minHeight: 32.0, minWidth: 60.0),
                        borderRadius: BorderRadius.circular(8),
                        children: const [Text('조회순'), Text('이름순'), Text('마감순')],
                      ),
                    ],
                  ),
                  if (_getEventsForDay(_selectedDay!).isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('해당 날짜에 예정된 축제가 없습니다.'),
                    )
                  else
                    ..._getEventsForDay(_selectedDay!).map((festival) => Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            leading: festival.firstimage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: festival.firstimage,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.broken_image,
                                            size: 80),
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child:
                                        const Icon(Icons.image_not_supported),
                                  ),
                            title: Text(
                              festival.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              festival.addr1,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              // TODO: 상세 페이지로 이동
                            },
                          ),
                        )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
