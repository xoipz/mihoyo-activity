package com.example.xmihoyo;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.Intent;

public class WidgetUpdateHelper {

  // 获取刷新按钮的 PendingIntent
  public static PendingIntent getRefreshPendingIntent(Context context, int appWidgetId) {
    Intent intent = new Intent(context, WidgetUpdateService.class);
    intent.setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE);
    int[] ids = new int[] { appWidgetId };
    intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids);
    return PendingIntent.getBroadcast(context, appWidgetId, intent, PendingIntent.FLAG_UPDATE_CURRENT);
  }

  // 获取切换公告类型按钮的 PendingIntent
  public static PendingIntent getSwitchPendingIntent(Context context, int appWidgetId) {
    Intent intent = new Intent(context, WidgetUpdateService.class);
    intent.setAction("ACTION_SWITCH_ANNOUNCEMENT_TYPE");
    int[] ids = new int[] { appWidgetId };
    intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids);
    return PendingIntent.getBroadcast(context, appWidgetId, intent, PendingIntent.FLAG_UPDATE_CURRENT);
  }
}
