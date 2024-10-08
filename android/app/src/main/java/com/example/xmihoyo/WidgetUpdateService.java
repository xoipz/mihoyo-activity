package com.example.xmihoyo;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.util.Log;
import android.widget.RemoteViews;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.AppWidgetTarget;
import com.bumptech.glide.request.transition.Transition;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class WidgetUpdateService extends AppWidgetProvider {

  private static final String DATE_FORMAT = "yyyy-MM-dd HH:mm:ss"; // 假设 end_time 格式

  @Override
  public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
    Log.d("WidgetUpdateServiceLog", "=====================TEST=======================");
    Log.d("WidgetUpdateServiceLog", "onUpdate called");
    // 初始化 Flutter 引擎
    FlutterEngine flutterEngine = new FlutterEngine(context);
    flutterEngine.getDartExecutor().executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault());

    // 初始化 MethodChannel，用于接收公告数据
    MethodChannel methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.xmihoyo/widget");
    methodChannel.setMethodCallHandler(
      new MethodCallHandler() {
        @Override
        public void onMethodCall(MethodCall call, MethodChannel.Result result) {
          if (call.method.equals("updateWidget")) {
            List<Map<String, String>> announcements = (List<Map<String, String>>) call.arguments;
            updateWidgetContent(context, appWidgetManager, appWidgetIds, announcements);
          }
        }
      }
    );
  }

  private void updateWidgetContent(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds, List<Map<String, String>> announcements) {
    // 遍历所有的小组件实例
    for (int appWidgetId : appWidgetIds) {
      // 第一个公告的假数据
      RemoteViews announcementView1 = new RemoteViews(context.getPackageName(), R.layout.announcement_item);
      String announcementTitle1 = "活动公告：限时礼包上线";
      String daysLeft1 = "还有 2 天结束";
      String imageUrl1 = "https://example.com/image1.jpg"; // 假图片URL

      // 设置第一个公告的标题和剩余天数
      announcementView1.setTextViewText(R.id.txt_title, announcementTitle1);
      announcementView1.setTextViewText(R.id.txt_days_left, daysLeft1);

      // 加载第一个公告的图片
      loadImageIntoWidget(context, imageUrl1, announcementView1, R.id.img_announcement, appWidgetId, appWidgetManager);

      // 更新第一个公告的小组件
      appWidgetManager.updateAppWidget(appWidgetId, announcementView1);

      // 第二个公告的假数据
      RemoteViews announcementView2 = new RemoteViews(context.getPackageName(), R.layout.announcement_item);
      String announcementTitle2 = "更新公告：新版本即将到来";
      String daysLeft2 = "还有 5 天结束";
      String imageUrl2 = "https://example.com/image2.jpg"; // 假图片URL

      // 设置第二个公告的标题和剩余天数
      announcementView2.setTextViewText(R.id.txt_title, announcementTitle2);
      announcementView2.setTextViewText(R.id.txt_days_left, daysLeft2);

      // 加载第二个公告的图片
      loadImageIntoWidget(context, imageUrl2, announcementView2, R.id.img_announcement, appWidgetId, appWidgetManager);

      // 更新第二个公告的小组件
      appWidgetManager.updateAppWidget(appWidgetId, announcementView2);
    }
  }

  // 计算剩余天数的方法
  private String calculateDaysLeft(String endTime) {
    if (endTime == null || endTime.isEmpty()) {
      return "未知";
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat(DATE_FORMAT, Locale.getDefault());
    try {
      Date endDate = dateFormat.parse(endTime);
      if (endDate != null) {
        long diffInMillis = endDate.getTime() - System.currentTimeMillis();
        long daysLeft = diffInMillis / (1000 * 60 * 60 * 24); // 毫秒转换为天数
        return String.valueOf(daysLeft);
      }
    } catch (ParseException e) {
      e.printStackTrace();
    }

    return "未知";
  }

  // 定义 loadImageIntoWidget 方法
  private void loadImageIntoWidget(Context context, String imageUrl, RemoteViews views, int imageViewId, int appWidgetId, AppWidgetManager appWidgetManager) {
    // 使用 Glide 加载图片
    Glide
      .with(context.getApplicationContext())
      .asBitmap()
      .load(imageUrl)
      .override(50, 50) // 设置图片大小
      .into(
        new AppWidgetTarget(context, imageViewId, views, appWidgetId) {
          @Override
          public void onResourceReady(@NonNull Bitmap resource, @Nullable Transition<? super Bitmap> transition) {
            super.onResourceReady(resource, transition);
            views.setImageViewBitmap(imageViewId, resource);
            appWidgetManager.updateAppWidget(appWidgetId, views);
          }

          @Override
          public void onLoadFailed(@Nullable Drawable errorDrawable) {
            super.onLoadFailed(errorDrawable);
            // 如果图片加载失败，设置本地占位符图片
            views.setImageViewResource(imageViewId, R.drawable.placeholder); // 使用本地 placeholder.png
            appWidgetManager.updateAppWidget(appWidgetId, views);
          }
        }
      );
  }
}
