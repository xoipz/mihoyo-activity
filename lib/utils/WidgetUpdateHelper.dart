import 'package:flutter/services.dart';

class WidgetUpdateHelper {
  static const platform = MethodChannel('com.example.xmihoyo/widget');

  static Future<void> updateWidget(List<dynamic> announcements) async {
    try {
      List<Map<String, String>> announcementData = [];

      // 遍历所有游戏
      announcements.forEach((game) {
        // 遍历游戏中的每个公告类型（仅选择游戏活动）
        game['list'].forEach((category) {
          if (category['header'] == "游戏活动") {
            // 筛选游戏活动
            // 遍历具体的公告
            category['list'].forEach((announcement) {
              // 添加游戏活动公告数据到 announcementData 列表，确保非空值
              announcementData.add({
                "title": announcement['title'] != null
                    ? announcement['title'] as String
                    : "无标题",
                "imageUrl": announcement['img'] != null
                    ? announcement['img'] as String
                    : "", // 处理 null 值
              });
            });
          }
        });
      });

      // 调用平台通道，发送公告数据到 Android
      // 这里直接发送 announcementData 作为一个 List，而不是 Map
      await platform.invokeMethod('updateWidget', announcementData);
    } on PlatformException catch (e) {
      print("Failed to update widget: '${e.message}'.");
    }
  }
}
