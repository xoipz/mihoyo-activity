package com.example.xmihoyo;

import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

  private static final String CHANNEL = "com.example.xmihoyo/widget";

  @Override
  public void configureFlutterEngine(FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);

    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
      .setMethodCallHandler((call, result) -> {
        if (call.method.equals("updateWidget")) {
          // 处理 updateWidget 调用的逻辑
          // 你可以在这里编写逻辑来更新小组件
          result.success("Widget updated successfully");
        } else {
          result.notImplemented();
        }
      });
  }
}
