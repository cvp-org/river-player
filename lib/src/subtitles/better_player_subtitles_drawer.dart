import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:river_player/river_player.dart';
import 'package:river_player/src/subtitles/better_player_subtitle.dart';

class BetterPlayerSubtitlesDrawer extends StatefulWidget {
  final List<BetterPlayerSubtitle> subtitles;
  final BetterPlayerController betterPlayerController;
  final BetterPlayerSubtitlesConfiguration betterPlayerSubtitlesConfiguration;
  final Stream<bool> playerVisibilityStream;

  const BetterPlayerSubtitlesDrawer({
    Key? key,
    required this.subtitles,
    required this.betterPlayerController,
    required this.betterPlayerSubtitlesConfiguration,
    required this.playerVisibilityStream,
  }) : super(key: key);

  @override
  _BetterPlayerSubtitlesDrawerState createState() =>
      _BetterPlayerSubtitlesDrawerState();
}

class _BetterPlayerSubtitlesDrawerState
    extends State<BetterPlayerSubtitlesDrawer> {
  final RegExp htmlRegExp =
      // ignore: unnecessary_raw_strings
      RegExp(r"<[^>]*>", multiLine: true);
  VideoPlayerValue? _latestValue;
  bool _playerVisible = false;

  ///Stream used to detect if play controls are visible or not
  late StreamSubscription _visibilityStreamSubscription;

  late BetterPlayerSubtitlesConfiguration _subtitlesConfiguration;

  @override
  void initState() {
    _visibilityStreamSubscription =
        widget.playerVisibilityStream.listen((state) {
      if (_playerVisible != state) {
        setState(() {
          _playerVisible = state;
        });
      }
    });
    
    _subtitlesConfiguration = widget.betterPlayerSubtitlesConfiguration;

    widget.betterPlayerController.videoPlayerController!
        .addListener(_updateState);

    super.initState();
  }

  @override
  void didUpdateWidget(BetterPlayerSubtitlesDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_subtitlesConfiguration != widget.betterPlayerSubtitlesConfiguration) {
      setState(() {
        _subtitlesConfiguration = widget.betterPlayerSubtitlesConfiguration;
      });
    }
  }

  @override
  void dispose() {
    final videoPlayerController =
        widget.betterPlayerController.videoPlayerController;
    if (videoPlayerController != null) {
      videoPlayerController.removeListener(_updateState);
    }
    _visibilityStreamSubscription.cancel();
    super.dispose();
  }

  ///Called when player state has changed, i.e. new player position, etc.
  void _updateState() {
    if (mounted) {
      setState(() {
        _latestValue =
            widget.betterPlayerController.videoPlayerController!.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<BetterPlayerSubtitle> currentSubtitles = _getSubtitlesAtCurrentPosition();
    widget.betterPlayerController.renderedSubtitle = currentSubtitles.isNotEmpty ? currentSubtitles.first : null;
    
    final List<String> allSubtitles = currentSubtitles
        .expand((subtitle) => subtitle.texts ?? [])
        .cast<String>()
        .toList();

    final List<Widget> textWidgets = allSubtitles.asMap().entries.map((entry) {
      int index = entry.key;
      String text = entry.value;
      return _buildSubtitleTextWidget(text, isLast: index == allSubtitles.length - 1);
    }).toList();

    return Container(
      height: double.infinity,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Padding(
        padding: EdgeInsets.only(
            bottom: _playerVisible
                ? _subtitlesConfiguration.bottomPadding + 88
                : _subtitlesConfiguration.bottomPadding,
            left: _subtitlesConfiguration.leftPadding,
            right: _subtitlesConfiguration.rightPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: textWidgets,
        ),
      ),
    );
  }


  List<BetterPlayerSubtitle> _getSubtitlesAtCurrentPosition() {
    if (_latestValue == null) {
      return [];
    }

    final Duration position = _latestValue!.position;
    final List<BetterPlayerSubtitle> currentSubtitles = [];
    
    for (final BetterPlayerSubtitle subtitle in widget.betterPlayerController.subtitlesLines) {
      if (subtitle.start! <= position && subtitle.end! >= position) {
        currentSubtitles.add(subtitle);
      }
    }
    return currentSubtitles;
  }


  Widget _buildSubtitleTextWidget(String subtitleText, {bool isLast = false}) {
    return Row(children: [
      Expanded(
        child: Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 4),
          alignment: _subtitlesConfiguration.alignment,
          child: _getTextWithStroke(subtitleText),
        ),
      ),
    ]);
  }
  Widget _getTextWithStroke(String subtitleText) {
    final outerTextStyle = TextStyle(
        fontSize: _subtitlesConfiguration.fontSize,
        fontFamily: _subtitlesConfiguration.fontFamily,
        fontWeight: _subtitlesConfiguration.fontWeight,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _subtitlesConfiguration.outlineSize
          ..color = _subtitlesConfiguration.outlineColor);

    final innerTextStyle = TextStyle(
        fontFamily: _subtitlesConfiguration.fontFamily,
        color: _subtitlesConfiguration.fontColor,
        fontSize: _subtitlesConfiguration.fontSize,
        fontWeight: _subtitlesConfiguration.fontWeight);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _subtitlesConfiguration.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: _subtitlesConfiguration.alignment,
        children: [
          if (_subtitlesConfiguration.outlineEnabled)
            _buildHtmlWidget(subtitleText, outerTextStyle)
          else
            const SizedBox(),
          _buildHtmlWidget(subtitleText, innerTextStyle)
        ],
      ),
    );
  }

  Widget _buildHtmlWidget(String text, TextStyle textStyle) {
    return HtmlWidget(
      text,
      textStyle: textStyle,
    );
  }
}
