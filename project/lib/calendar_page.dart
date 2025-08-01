import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project/provider/locale_provider.dart';
import 'package:project/widget/translator.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'detail_page.dart';
import 'festival_model.dart';
import 'l10n/app_localizations.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final Set<String> _loadedMonths = {};
  bool _isMonthLoading = true;
  String? _error;
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  String _sortOrder = 'views';
  Map<DateTime, List<Festival>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchFestivalsForMonth(_focusedDay);
  }

  Future<void> _fetchFestivalsForMonth(DateTime month) async {
    final monthKey = DateFormat('yyyyMM').format(month);
    if (_loadedMonths.contains(monthKey)) return;
    setState(() {
      _isMonthLoading = true;
    });
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    const SERVICE_KEY =
        "WCIc8hzzBS3Jdod%2BVa357JmB%2FOS0n4D2qPHaP9PkN4bXIfcryZyg4iaZeTj1fEYJ%2B8q2Ol8FIGe3RkW3d72FHA%3D%3D";
    final eventStartDate =
        '${month.year}${month.month.toString().padLeft(2, '0')}01';
    final uri = Uri.parse(
        'https://apis.data.go.kr/B551011/KorService2/searchFestival2?serviceKey=$SERVICE_KEY&MobileApp=AppTest&MobileOS=ETC&_type=json&numOfRows=200&pageNo=1&arrange=B&eventStartDate=$eventStartDate');
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
        if (items.isNotEmpty) {
          final festivals =
              items.map((item) => Festival.fromJson(item)).toList();
          final newEvents = Map<DateTime, List<Festival>>.from(_events);
          for (final festival in festivals) {
            if (festival.eventstartdate.isEmpty ||
                festival.eventenddate.isEmpty) continue;
            final startDate = _parseDateSafely(festival.eventstartdate);
            final endDate = _parseDateSafely(festival.eventenddate);
            if (startDate == null || endDate == null) continue;
            for (var day = startDate;
                day.isBefore(endDate.add(const Duration(days: 1)));
                day = day.add(const Duration(days: 1))) {
              if (day.isBefore(today)) continue;
              final dayWithoutTime = DateTime.utc(day.year, day.month, day.day);
              if (newEvents[dayWithoutTime] == null)
                newEvents[dayWithoutTime] = [];
              newEvents[dayWithoutTime]!.add(festival);
            }
          }
          setState(() {
            _events = newEvents;
          });
        }
        _loadedMonths.add(monthKey);
      } else {
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('CalendarPage Error: $e');
      setState(() {
        _error = '데이터를 불러오는 데 실패했습니다: $e';
      });
    } finally {
      setState(() {
        _isMonthLoading = false;
      });
    }
  }

  List<Festival> _getEventsForDay(DateTime day) {
    final dayWithoutTime = DateTime.utc(day.year, day.month, day.day);
    List<Festival> events = List.from(_events[dayWithoutTime] ?? []);

    switch (_sortOrder) {
      case 'name':
        events.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'ending':
        events.sort((a, b) => a.eventenddate.compareTo(b.eventenddate));
        break;
      case 'views':
      default:
        break;
    }
    return events;
  }

  DateTime? _parseDateSafely(String dateStr) {
    final cleanDateStr = dateStr.trim();
    if (cleanDateStr.length != 8) return null;
    try {
      final year = int.parse(cleanDateStr.substring(0, 4));
      final month = int.parse(cleanDateStr.substring(4, 6));
      final day = int.parse(cleanDateStr.substring(6, 8));
      return DateTime.utc(year, month, day);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendar),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: locale.toString(),
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            headerStyle: const HeaderStyle(
                formatButtonVisible: false, titleCentered: true),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: Colors.orangeAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(
                  color: Colors.blueAccent, shape: BoxShape.circle),
            ),
            onDaySelected: (selectedDay, focusedDay) => setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            }),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _getEventsForDay(day),
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchFestivalsForMonth(focusedDay);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6.0)),
                      child: Text('${events.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(),
          if (_isMonthLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: Center(child: Text(_error!)))
          else
            Expanded(child: _buildFestivalList(l10n)),
        ],
      ),
    );
  }

  Widget _buildFestivalList(AppLocalizations l10n) {
    final selectedDayEvents = _getEventsForDay(_selectedDay!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMMd(l10n.localeName).format(_selectedDay!),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ToggleButtons(
                  isSelected: [
                    _sortOrder == 'views',
                    _sortOrder == 'name',
                    _sortOrder == 'ending'
                  ],
                  onPressed: (index) {
                    setState(() {
                      if (index == 0) _sortOrder = 'views';
                      if (index == 1) _sortOrder = 'name';
                      if (index == 2) _sortOrder = 'ending';
                    });
                  },
                  constraints:
                      const BoxConstraints(minHeight: 32.0, minWidth: 60.0),
                  borderRadius: BorderRadius.circular(8),
                  children: [
                    Text(l10n.calendarView),
                    Text(l10n.calendarName),
                    Text(l10n.calendarEnding)
                  ],
                ),
              ],
            ),
          ),
          if (selectedDayEvents.isEmpty)
            Expanded(child: Center(child: Text(l10n.calendarComment)))
          else
            Expanded(
              child: ListView.builder(
                itemCount: selectedDayEvents.length,
                itemBuilder: (context, index) {
                  final festival = selectedDayEvents[index];
                  return Card(
                    key: ValueKey(festival.contentid),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                  const Icon(Icons.broken_image, size: 80),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                      title: TranslatedText(
                        text: festival.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: TranslatedText(
                        text: festival.addr1,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              festivalId: festival.contentid,
                              initialTitle: festival.title,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
