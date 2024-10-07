import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xmihoyo/page/RemarksPage.dart';
import 'package:xmihoyo/provider/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:xmihoyo/provider/announcement_provider.dart';

class AnnouncementPage extends StatefulWidget {
  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> genshinAnnouncements = [];
  List<dynamic> starRailAnnouncements = [];
  bool isLoading = false;
  int _selectedGameTab = 0;
  int _selectedAnnouncementTab = 0;
  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
    _subscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _loadCachedAnnouncements();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _selectedGameTab) {
        setState(() {
          _selectedGameTab = _tabController.index;
          _selectedAnnouncementTab = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkNetworkStatus() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      if (result == ConnectivityResult.mobile) {
        _connectionStatus = '流量';
      } else if (result == ConnectivityResult.wifi) {
        _connectionStatus = 'WiFi';
      } else {
        _connectionStatus = '无网络';
      }
    });
  }

  Future<void> _loadCachedAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final genshinData = prefs.getString('genshinAnnouncements');
    final starRailData = prefs.getString('starRailAnnouncements');

    setState(() {
      if (genshinData != null) {
        genshinAnnouncements = json.decode(genshinData);
      }
      if (starRailData != null) {
        starRailAnnouncements = json.decode(starRailData);
      }
    });

    await fetchGenshinAnnouncements();
    await fetchStarRailAnnouncements();
  }

  Future<void> fetchGenshinAnnouncements() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
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

          activityAnnouncements.sort((a, b) =>
              _getRemainingDuration(a['end_time'])
                  .compareTo(_getRemainingDuration(b['end_time'])));
          gameAnnouncements.sort((a, b) => _getRemainingDuration(a['end_time'])
              .compareTo(_getRemainingDuration(b['end_time'])));

          setState(() {
            genshinAnnouncements = [
              {'type_label': '活动公告', 'list': activityAnnouncements},
              {'type_label': '游戏公告', 'list': gameAnnouncements},
            ];
          });

          // Save to cache
          await prefs.setString(
              'genshinAnnouncements', json.encode(genshinAnnouncements));
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

    final prefs = await SharedPreferences.getInstance();
    final url = Uri.parse(
        'https://sg-hkrpg-api.hoyoverse.com/common/hkrpg_global/announcement/api/getAnnList?game=hkrpg&game_biz=hkrpg_global&lang=zh-cn&bundle_id=hkrpg_global&level=55&platform=pc&region=prod_official_cht&uid=900000000');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        if (jsonData['retcode'] == 0) {
          List<dynamic> allAnnouncements = jsonData['data']['list'] ?? [];
          List<dynamic> picAnnouncements =
              (jsonData['data']['pic_list']?.isNotEmpty ?? false)
                  ? jsonData['data']['pic_list'][0]['type_list'] ?? []
                  : [];
          List<dynamic> starRailNotices = [];
          List<dynamic> starRailNotices2 = [];

          for (var category in allAnnouncements) {
            starRailNotices2.addAll(category['list'] ?? []);
          }
          for (var category in picAnnouncements) {
            starRailNotices.addAll(category['list'] ?? []);
          }

          starRailNotices.sort((a, b) => _getRemainingDuration(a['end_time'])
              .compareTo(_getRemainingDuration(b['end_time'])));

          setState(() {
            starRailAnnouncements = [
              {'type_label': '活动公告', 'list': starRailNotices},
              {'type_label': '游戏公告', 'list': starRailNotices2},
            ];
          });

          // Save to cache
          await prefs.setString(
              'starRailAnnouncements', json.encode(starRailAnnouncements));
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

  Duration _getRemainingDuration(String endTime) {
    try {
      DateTime endDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(endTime);
      return endDate.difference(DateTime.now());
    } catch (e) {
      return Duration.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final announcementProvider = Provider.of<AnnouncementProvider>(context);
    bool isWideScreen = MediaQuery.of(context).size.width > 800;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '游戏活动',
            style: TextStyle(
              fontWeight: FontWeight.bold, // 加粗字体
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  // 切换公告类型
                  _selectedAnnouncementTab = (_selectedAnnouncementTab + 1) % 2;
                });
              },
              child: Text(
                _selectedAnnouncementTab == 0 ? '活动公告' : '游戏公告',
                style: TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: Icon(Icons.restore), // 显示所有公告的按钮图标
              onPressed: () {
                setState(() {
                  // 清空过滤条件，恢复显示所有公告
                  announcementProvider.showAllAnnouncements();
                });
              },
            ),
            IconButton(
              icon: Icon(themeProvider.isDarkMode
                  ? Icons.wb_sunny
                  : Icons.nightlight_round),
              onPressed: themeProvider.toggleDarkMode,
            ),
            IconButton(
              icon: Icon(Icons.summarize),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RemarksPage(),
                  ),
                ).then((_) => setState(() {}));
              },
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
                  : () async {
                      if (_selectedGameTab == 0) {
                        await fetchGenshinAnnouncements();
                      } else {
                        await fetchStarRailAnnouncements();
                      }
                    },
            ),
          ],
        ),
        body: Row(
          children: [
            if (isWideScreen)
              NavigationRail(
                selectedIndex: _selectedGameTab,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedGameTab = index;
                    _selectedAnnouncementTab = 0;
                  });
                  _tabController.animateTo(index);
                },
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.gamepad),
                    label: Text('原神'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.train),
                    label: Text('星穹铁道'),
                  ),
                ],
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAnnouncementContent(
                      genshinAnnouncements, announcementProvider),
                  _buildAnnouncementContent(
                      starRailAnnouncements, announcementProvider),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: !isWideScreen
            ? BottomNavigationBar(
                currentIndex: _selectedGameTab,
                onTap: (index) {
                  setState(() {
                    _selectedGameTab = index;
                    _selectedAnnouncementTab = 0;
                  });
                  _tabController.animateTo(index);
                },
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.gamepad),
                    label: '原神',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.train),
                    label: '星穹铁道',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildAnnouncementContent(
      List<dynamic> announcements, AnnouncementProvider announcementProvider) {
    return IndexedStack(
      index: _selectedAnnouncementTab,
      children: [
        _buildAnnouncementList(
            announcements.firstWhere(
                (element) => element['type_label'] == '活动公告',
                orElse: () => {'list': []})['list'] as List<dynamic>,
            announcementProvider),
        _buildAnnouncementList(
            announcements.firstWhere(
                (element) => element['type_label'] == '游戏公告',
                orElse: () => {'list': []})['list'] as List<dynamic>,
            announcementProvider),
      ],
    );
  }

  Widget _buildAnnouncementList(
      List<dynamic> items, AnnouncementProvider announcementProvider) {
    List<dynamic> filteredItems = items
        .where((item) => !announcementProvider.markedAnnouncements
            .contains(item['ann_id'].toString()))
        .toList();

    // 如果没有过滤条件，显示所有公告
    if (announcementProvider.markedAnnouncements.isEmpty) {
      filteredItems = items;
    }

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
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            final annId = item['ann_id'].toString();
            bool isMarked =
                announcementProvider.markedAnnouncements.contains(annId);

            Duration remainingDuration =
                _getRemainingDuration(item['end_time'] ?? '');
            String remainingTimeText;
            if (remainingDuration.inDays > 0) {
              remainingTimeText = '${remainingDuration.inDays} 天后结束';
            } else if (remainingDuration.inHours > 0) {
              remainingTimeText = '${remainingDuration.inHours} 小时后结束';
            } else if (remainingDuration.inMinutes > 0) {
              remainingTimeText = '${remainingDuration.inMinutes} 分钟后结束';
            } else {
              remainingTimeText = '活动已结束';
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            (item['subtitle'] ?? '') != ''
                                ? item['subtitle']
                                : item['title'],
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isMarked
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: isMarked ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isMarked) {
                                announcementProvider
                                    .removeMarkedAnnouncement(annId);
                              } else {
                                announcementProvider.addMarkedAnnouncement(
                                    annId, item);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(item['subtitle'] ?? 'No Subtitle'),
                    SizedBox(height: 5),
                    (item['banner'] != null && item['banner'].isNotEmpty) ||
                            (item['img'] != null && item['img'].isNotEmpty)
                        ? Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: CachedNetworkImage(
                                imageUrl: item['banner']?.isNotEmpty == true
                                    ? item['banner']
                                    : item['img'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    Image.asset(
                                  'assets/placeholder.png',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
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
                            remainingTimeText,
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
