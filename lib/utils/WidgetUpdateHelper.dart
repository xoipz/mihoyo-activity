import 'package:flutter/services.dart';
import 'package:intl/intl.dart';  // 用于日期解析

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
              // 计算剩余天数
              String endTime = announcement['end_time'];
              String daysLeft = _calculateDaysLeft(endTime);

              // 添加游戏活动公告数据到 announcementData 列表，确保非空值
              announcementData.add({
                "title": announcement['title'] != null
                    ? announcement['title'] as String
                    : "无标题",
                "imageUrl": announcement['img'] != null
                    ? announcement['img'] as String
                    : "", // 处理 null 值
                "daysLeft": daysLeft
              });
            });
          }
        });
      });

      // 调用平台通道，发送公告数据到 Android
      await platform.invokeMethod('updateWidget', announcementData);
    } on PlatformException catch (e) {
      print("Failed to update widget: '${e.message}'.");
    }
  }

  // 计算剩余天数的方法
  static String _calculateDaysLeft(String endTime) {
    if (endTime == null || endTime.isEmpty) {
      return "未知";
    }

    try {
      // 假设 endTime 是 "yyyy-MM-dd HH:mm:ss" 格式的字符串
      DateTime endDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(endTime);
      DateTime now = DateTime.now();
      
      // 计算剩余的天数
      Duration difference = endDate.difference(now);
      if (difference.inDays > 0) {
        return "${difference.inDays} 天";
      } else if (difference.inHours > 0) {
        return "${difference.inHours} 小时";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes} 分钟";
      } else {
        return "活动已结束";
      }
    } catch (e) {
      print("Error parsing date: $e");
      return "未知";
    }
  }
}
