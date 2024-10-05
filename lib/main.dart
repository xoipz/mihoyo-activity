import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Announcement Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AnnouncementPage(),
    );
  }
}

class AnnouncementPage extends StatefulWidget {
  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  List<dynamic> announcements = [];
  bool isLoading = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        'https://hk4e-ann-api.mihoyo.com/common/hk4e_cn/announcement/api/getAnnList?game=hk4e&game_biz=hk4e_cn&bundle_id=hk4e_cn&platform=pc&level=55&uid=100000000&lang=zh-cn&region=cn_gf01');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        if (jsonData['retcode'] == 0) {
          List<dynamic> allAnnouncements = jsonData['data']['list'] ?? [];
          List<dynamic> activityAnnouncements = [];
          List<dynamic> gameAnnouncements = [];

          for (var category in allAnnouncements) {
            if (category['type_label'] == '活动公告') {
              activityAnnouncements.addAll(category['list'] ?? []);
            } else if (category['type_label'] == '游戏公告') {
              gameAnnouncements.addAll(category['list'] ?? []);
            }
          }

          activityAnnouncements.sort((a, b) => _getRemainingDays(a['end_time'])
              .compareTo(_getRemainingDays(b['end_time'])));
          gameAnnouncements.sort((a, b) => _getRemainingDays(a['end_time'])
              .compareTo(_getRemainingDays(b['end_time'])));

          setState(() {
            announcements = [
              {'type_label': '活动公告', 'list': activityAnnouncements},
              {'type_label': '游戏公告', 'list': gameAnnouncements},
            ];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch announcements.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  int _getRemainingDays(String endTime) {
    try {
      DateTime endDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(endTime);
      return endDate.difference(DateTime.now()).inDays;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcements'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTab = _selectedTab == 0 ? 1 : 0;
              });
            },
            child: Text(
              _selectedTab == 0 ? '活动公告' : '游戏公告',
              style: TextStyle(color: Colors.black),
            ),
          ),
          IconButton(
            icon: isLoading
                ? SizedBox(
                    height: 24.0,
                    width: 24.0,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.0),
                  )
                : Icon(Icons.refresh),
            onPressed: isLoading ? null : fetchAnnouncements,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildAnnouncementList(announcements.firstWhere(
                      (element) => element['type_label'] == '活动公告',
                      orElse: () => {'list': []})['list']),
                  _buildAnnouncementList(announcements.firstWhere(
                      (element) => element['type_label'] == '游戏公告',
                      orElse: () => {'list': []})['list']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementList(List<dynamic> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double itemWidth = 400;
        int crossAxisCount = (constraints.maxWidth / itemWidth).floor();
        return GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
            childAspectRatio: itemWidth / 230,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            int remainingDays = _getRemainingDays(item['end_time'] ?? '');

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'No Title',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(item['subtitle'] ?? 'No Subtitle'),
                    SizedBox(height: 5),
                    item['banner'] != null && item['banner'].isNotEmpty
                        ? Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                item['banner'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          )
                        : SizedBox.shrink(),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['start_time']} - ${item['end_time']}'),
                        Text(
                          '还有 $remainingDays 天结束',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
