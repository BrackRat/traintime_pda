// Copyright 2023 BenderBlog Rodriguez and contributors.
// SPDX-License-Identifier: MPL-2.0
// Main window for score.

import 'dart:io';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:flutter/material.dart';
import 'package:watermeter/page/public_widget/column_choose_dialog.dart';
import 'package:watermeter/page/score/score_choice_page.dart';
import 'package:watermeter/page/score/score_info_card.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';
import 'package:watermeter/page/score/score_state.dart';
import 'package:watermeter/page/score/score_statics.dart';

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  late ScoreState c;
  late TextEditingController text;

  @override
  void didChangeDependencies() {
    c = ScoreState.of(context)!;
    c.controllers.addListener(() => mounted ? setState(() {}) : null);
    text = TextEditingController.fromValue(
      TextEditingValue(text: c.controllers.search),
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    c.controllers.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> scoreList = List<Widget>.generate(
      c.toShow.length,
      (index) => ScoreInfoCard(
        mark: c.toShow[index].mark,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Platform.isIOS || Platform.isMacOS
                ? Icons.arrow_back_ios_new
                : Icons.arrow_back,
          ),
          onPressed: Navigator.of(c.context).pop,
        ),
        title: const Text("成绩查询"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: () => c.setScoreChoiceMod(),
          ),
        ],
      ),
      body: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            children: [
              TextField(
                style: const TextStyle(fontSize: 14),
                controller: text,
                autofocus: false,
                decoration: InputDecoration(
                  isDense: true,
                  fillColor: Colors.grey.withOpacity(0.2),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  hintText: "搜索成绩记录",
                  hintStyle: const TextStyle(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (String text) => c.search = text,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
                onPressed: () async {
                  await showDialog<int>(
                    context: context,
                    builder: (context) => ColumnChooseDialog(
                      chooseList: ["所有学期", ...c.semester].toList(),
                    ),
                  ).then((value) {
                    if (value != null) {
                      c.chosenSemester = ["", ...c.semester].toList()[value];
                    }
                  });
                },
                child: Text(
                  "学期 ${c.controllers.chosenSemester == "" ? "所有学期" : c.controllers.chosenSemester}",
                ),
              ).padding(right: 8),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
                onPressed: () async {
                  await showDialog<int>(
                    context: context,
                    builder: (context) => ColumnChooseDialog(
                      chooseList: ["所有类型", ...c.statuses].toList(),
                    ),
                  ).then((value) {
                    if (value != null) {
                      c.chosenStatus = ["", ...c.statuses].toList()[value];
                    }
                  });
                },
                child: Text(
                  "类型 ${c.controllers.chosenStatus == "" ? "所有类型" : c.controllers.chosenStatus}",
                ),
              ),
            ],
          )
              .padding(horizontal: 14, top: 8, bottom: 6)
              .constrained(maxWidth: 480),
          Expanded(
            child: c.toShow.isNotEmpty
                ? MasonryGridView.count(
                    shrinkWrap: true,
                    itemCount: c.toShow.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width ~/ cardWidth,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    itemBuilder: (context, index) => scoreList[index],
                  )
                : const Text("未筛查到合请求的记录").center(),
          ),
        ],
      ),
      bottomNavigationBar: Visibility(
        visible: c.controllers.isSelectMod,
        child: BottomAppBar(
          height: 136,
          elevation: 5.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () => c.setScoreChoiceState(ChoiceState.all),
                    child: const Text(
                      "全选",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () => c.setScoreChoiceState(ChoiceState.none),
                    child: const Text(
                      "全不选",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () =>
                        c.setScoreChoiceState(ChoiceState.original),
                    child: const Text(
                      "重置选择",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c.bottomInfo),
                  FloatingActionButton(
                    elevation: 0.0,
                    highlightElevation: 0.0,
                    focusElevation: 0.0,
                    disabledElevation: 0.0,
                    onPressed: () {
                      Navigator.of(context).push(
                        createRoute(const ScoreChoicePage()),
                      );
                    },
                    child: const Icon(
                      Icons.panorama_fisheye,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
