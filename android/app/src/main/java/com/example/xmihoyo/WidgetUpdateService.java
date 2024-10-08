package com.example.xmihoyo;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.net.Uri;  // 导入 Uri
import android.widget.RemoteViews;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.AppWidgetTarget;
import android.util.Log;

import java.util.List;  // 导入 List
import java.util.Map;   // 导入 Map

public class WidgetUpdateService extends AppWidgetProvider {

    private static MethodChannel methodChannel;

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        // 初始化 Flutter 引擎
        FlutterEngine flutterEngine = new FlutterEngine(context);
        flutterEngine.getDartExecutor().executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        );

        // 初始化 MethodChannel，用于接收公告数据
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.xmihoyo/widget");
        methodChannel.setMethodCallHandler(new MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                if (call.method.equals("updateWidget")) {
                    // 强制转换传入的数据类型
                    List<Map<String, String>> announcements = (List<Map<String, String>>) call.arguments;
                    updateWidgetContent(context, appWidgetManager, appWidgetIds, announcements);
                }
            }
        });
    
        // 继续其他 widget 更新任务...
    }



private void updateWidgetContent(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds, List<Map<String, String>> announcements) {
    for (int appWidgetId : appWidgetIds) {
        // 创建 RemoteViews
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);

        // 更新第一条公告标题和图片
        if (announcements != null && !announcements.isEmpty()) {
            Map<String, String> firstAnnouncement = announcements.get(0);
            views.setTextViewText(R.id.txt_announcement_title, firstAnnouncement.get("title"));

            String imageUrl = firstAnnouncement.get("imageUrl");

            if (imageUrl != null && !imageUrl.isEmpty()) {
                // 使用 Glide 下载图片并加载到小组件
                AppWidgetTarget appWidgetTarget = new AppWidgetTarget(context, R.id.img_announcement, views, appWidgetId);

                Glide.with(context.getApplicationContext())
                    .asBitmap()
                    .load(imageUrl)
                    .into(appWidgetTarget);
            } else {
                Log.e("WidgetUpdateService", "Invalid image URL");
                // 设置默认图片或占位图片
                views.setImageViewResource(R.id.img_announcement, R.drawable.placeholder);
            }
        }

        // 更新 widget
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
}

}
