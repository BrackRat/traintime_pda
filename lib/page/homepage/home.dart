// Copyright 2023 BenderBlog Rodriguez and contributors.
// SPDX-License-Identifier: MPL-2.0

// Main page of this program.

import 'dart:developer' as developer;

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:restart_app/restart_app.dart';
import 'package:watermeter/applet/update_classtable_info.dart';
import 'package:watermeter/applet/update_sport_info.dart';
import 'package:watermeter/page/homepage/homepage.dart';
import 'package:watermeter/page/homepage/refresh.dart';
import 'package:watermeter/page/homepage/toolbox/toolbox_view.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';
import 'package:watermeter/page/setting/setting.dart';
import 'package:watermeter/repository/message_session.dart' as message;
import 'package:watermeter/repository/xidian_ids/ids_session.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:watermeter/page/login/jc_captcha.dart';
import 'package:watermeter/repository/preference.dart' as preference;

class PageInformation {
  final int index;
  final String name;
  final IconData icon;
  final IconData iconChoice;

  PageInformation({
    required this.index,
    required this.name,
    required this.icon,
    required this.iconChoice,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      updateOnAppResumed();
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          stopOnTerminate: true,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.NONE,
        ), (String taskId) async {
      developer.log(
        'Headless event received $taskId.',
        name: "BackgroundFetchFromHome",
      );
      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      await Future.wait([
        updateClasstableInfo(),
        updateSportInfo(),
      ]).then((value) => BackgroundFetch.finish(taskId));
    }, (String taskId) async {
      // <-- Task timeout handler.
      // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
      developer.log(
        "TASK TIMEOUT taskId: $taskId",
        name: "BackgroundFetchFromHome",
      );
      BackgroundFetch.finish(taskId);
    });
    developer.log(
      "Configure success: $status",
      name: "BackgroundFetchFromHome",
    );

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  static final _destinations = [
    PageInformation(
      index: 0,
      name: "主页",
      icon: MingCuteIcons.mgc_home_3_line,
      iconChoice: MingCuteIcons.mgc_home_3_fill,
    ),
    PageInformation(
      index: 1,
      name: "小工具",
      icon: MingCuteIcons.mgc_compass_line,
      iconChoice: MingCuteIcons.mgc_compass_fill,
    ),
    PageInformation(
      index: 2,
      name: "设置",
      icon: MingCuteIcons.mgc_user_2_line,
      iconChoice: MingCuteIcons.mgc_user_2_fill,
    ),
  ];

  late PageController _controller;
  late PageView _pageView;
  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _pageView = PageView(
      controller: _controller,
      children: [
        const MainPage(),
        LayoutBuilder(
          builder: (context, constraints) => ToolBoxView(
            constraints: constraints,
          ),
        ),
        const SettingWindow(),
      ],
      onPageChanged: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
    WidgetsBinding.instance.addObserver(this);
    message.checkMessage();
    developer.log("$loginState", name: "Home");
    if (loginState == IDSLoginState.none) {
      developer.log("Relogin.", name: "Home");
      _loginAsync();
    } else {
      developer.log("Updating infos.", name: "Home");
      update();
    }
    initPlatformState();
  }

  void _loginAsync() async {
    Fluttertoast.showToast(msg: "登录中，暂时显示缓存数据");

    try {
      await update(
        forceRetryLogin: true,
        sliderCaptcha: (String cookieStr) {
          return Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CaptchaWidget(cookie: cookieStr),
            ),
          );
        },
      );
    } finally {
      Fluttertoast.cancel();

      if (loginState == IDSLoginState.success) {
        Fluttertoast.showToast(msg: "登录成功");
      } else if (loginState == IDSLoginState.passwordWrong) {
        preference.remove(preference.Preference.idsPassword);

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("用户名或密码有误"),
              content: const Text("是否重启应用后手动登录？"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Restart.restartApp();
                  },
                  child: const Text("是"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showOfflineModeNotice();
                  },
                  child: const Text("否，进入离线模式"),
                ),
              ],
            ),
          );
        });
      } else {
        _showOfflineModeNotice();
      }
    }
  }

  void _showOfflineModeNotice() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("统一认证服务离线模式开启"),
          content: const Text(
            "无法连接到统一认证服务服务器，所有和其相关的服务暂时不可用。\n"
            "成绩查询，考试信息查询，欠费查询，校园卡查询关闭。课表显示缓存数据。其他功能暂不受影响。\n"
            "如有不便，敬请谅解。",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("确定"),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Row(
        children: [
          Visibility(
            visible: !isPhone(context),
            child: NavigationRail(
              backgroundColor: Theme.of(context).colorScheme.background,
              indicatorColor: Theme.of(context).colorScheme.secondary,
              elevation: 1,
              destinations: _destinations
                  .map(
                    (e) => NavigationRailDestination(
                      icon: _selectedIndex == e.index
                          ? Icon(e.iconChoice)
                          : Icon(e.icon),
                      label: Text(e.name),
                    ),
                  )
                  .toList(),
              labelType: NavigationRailLabelType.all,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
                _controller.jumpToPage(_selectedIndex);
              },
            ),
          ),
          Expanded(
            child: _pageView,
          ),
        ],
      ),
      bottomNavigationBar: isPhone(context)
          ? NavigationBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              indicatorColor: Theme.of(context).colorScheme.secondary,
              height: 64,
              destinations: _destinations
                  .map(
                    (e) => NavigationDestination(
                      icon: _selectedIndex == e.index
                          ? Icon(e.iconChoice)
                          : Icon(e.icon),
                      label: e.name,
                    ),
                  )
                  .toList(),
              selectedIndex: _selectedIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
                _controller.jumpToPage(_selectedIndex);
              },
            )
          : null,
    );
  }
}
