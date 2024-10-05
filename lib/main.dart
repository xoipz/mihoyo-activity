import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '游戏活动',
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
  List<dynamic> genshinAnnouncements = [];
  List<dynamic> starRailAnnouncements = [];
  bool isLoading = false;
  int _selectedGameTab = 0;
  int _selectedAnnouncementTab = 0;
  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
    _subscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    fetchGenshinAnnouncements();
    fetchStarRailAnnouncements();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkNetworkStatus() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    String status;
    if (result == ConnectivityResult.mobile) {
      status = '流量';
    } else if (result == ConnectivityResult.wifi) {
      status = 'WiFi';
    } else {
      status = '无网络';
    }
    setState(() {
      _connectionStatus = status;
    });
  }

  Future<void> fetchGenshinAnnouncements() async {
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
            genshinAnnouncements = [
              {'type_label': '活动公告', 'list': activityAnnouncements},
              {'type_label': '游戏公告', 'list': gameAnnouncements},
            ];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch Genshin announcements.')),
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

  Future<void> fetchStarRailAnnouncements() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        'https://sg-hkrpg-api.hoyoverse.com/common/hkrpg_global/announcement/api/getAnnList?game=hkrpg&game_biz=hkrpg_global&lang=zh-cn&bundle_id=hkrpg_global&level=55&platform=pc&region=prod_official_cht&uid=900000000');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        if (jsonData['retcode'] == 0) {
          List<dynamic> allAnnouncements = jsonData['data']['list'] ?? [];
          List<dynamic> picAnnouncements =
              jsonData['data']['pic_list'][0]['type_list'] ?? [];
          List<dynamic> starRailNotices = [];
          List<dynamic> starRailNotices2 = [];

          for (var category in allAnnouncements) {
            starRailNotices2.addAll(category['list'] ?? []);
          }
          for (var category in picAnnouncements) {
            starRailNotices.addAll(category['list'] ?? []);
          }

          starRailNotices.sort((a, b) => _getRemainingDays(a['end_time'])
              .compareTo(_getRemainingDays(b['end_time'])));

          setState(() {
            starRailAnnouncements = [
              {'type_label': '活动公告', 'list': starRailNotices},
              {'type_label': '游戏公告', 'list': starRailNotices2},
            ];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch Star Rail announcements.')),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('游戏活动'),
              Text('$_connectionStatus', style: TextStyle(fontSize: 14)),
            ],
          ),
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _selectedGameTab = index;
                _selectedAnnouncementTab = 0;
              });
            },
            tabs: [
              Tab(text: '原神'),
              Tab(text: '星穹铁道'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedAnnouncementTab =
                      _selectedAnnouncementTab == 0 ? 1 : 0;
                });
              },
              child: Text(
                _selectedAnnouncementTab == 0 ? '活动公告' : '游戏公告',
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
              onPressed: isLoading
                  ? null
                  : () {
                      if (_selectedGameTab == 0) {
                        fetchGenshinAnnouncements();
                      } else {
                        fetchStarRailAnnouncements();
                      }
                    },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedGameTab,
                        children: [
                          IndexedStack(
                            index: _selectedAnnouncementTab,
                            children: [
                              _buildAnnouncementList(
                                  genshinAnnouncements.firstWhere(
                                      (element) =>
                                          element['type_label'] == '活动公告',
                                      orElse: () => {'list': []})['list']),
                              _buildAnnouncementList(
                                  genshinAnnouncements.firstWhere(
                                      (element) =>
                                          element['type_label'] == '游戏公告',
                                      orElse: () => {'list': []})['list']),
                            ],
                          ),
                          IndexedStack(
                            index: _selectedAnnouncementTab,
                            children: [
                              _buildAnnouncementList(
                                  starRailAnnouncements.firstWhere(
                                      (element) =>
                                          element['type_label'] == '活动公告',
                                      orElse: () => {'list': []})['list']),
                              _buildAnnouncementList(
                                  starRailAnnouncements.firstWhere(
                                      (element) =>
                                          element['type_label'] == '游戏公告',
                                      orElse: () => {'list': []})['list']),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    (item['banner'] != null && item['banner'].isNotEmpty) ||
                            (item['img'] != null && item['img'].isNotEmpty)
                        ? Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                item['banner']?.isNotEmpty == true
                                    ? item['banner']
                                    : item['img'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          )
                        : Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                'assets/placeholder.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                    SizedBox(height: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${item['start_time']} - ${item['end_time']}'),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '还有 $remainingDays 天结束',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
