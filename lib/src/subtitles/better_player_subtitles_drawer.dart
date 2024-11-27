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
      setState(() {
        _playerVisible = state;
      });
    });

    widget.betterPlayerController.videoPlayerController!
        .addListener(_updateState);

    super.initState();
    _subtitlesConfiguration = widget.betterPlayerSubtitlesConfiguration;
  }

  @override
  void dispose() {
    widget.betterPlayerController.videoPlayerController!
        .removeListener(_updateState);
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
    final BetterPlayerSubtitle? subtitle = _getSubtitleAtCurrentPosition();
    widget.betterPlayerController.renderedSubtitle = subtitle;
    final List<String> subtitles = subtitle?.texts ?? [];
    final List<Widget> textWidgets =
        subtitles.map((text) => _buildSubtitleTextWidget(text)).toList();

    return Container(
      height: double.infinity,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(
            bottom: _playerVisible
                ? _subtitlesConfiguration.bottomPadding + 30
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

  BetterPlayerSubtitle? _getSubtitleAtCurrentPosition() {
    if (_latestValue == null) {
      return null;
    }

    final Duration position = _latestValue!.position;
    for (final BetterPlayerSubtitle subtitle
        in widget.betterPlayerController.subtitlesLines) {
      if (subtitle.start! <= position && subtitle.end! >= position) {
        return subtitle;
      }
    }
    return null;
  }

  Widget _buildSubtitleTextWidget(String subtitleText) {
    return Row(children: [
      Expanded(
        child: Align(
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
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _subtitlesConfiguration.outlineSize
          ..color = _subtitlesConfiguration.outlineColor);

    final innerTextStyle = TextStyle(
        fontFamily: _subtitlesConfiguration.fontFamily,
        color: _subtitlesConfiguration.fontColor,
        fontSize: _subtitlesConfiguration.fontSize);

    return Container(
      color: _subtitlesConfiguration.backgroundColor,
      child: Stack(
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

  BetterPlayerSubtitlesConfiguration setupDefaultConfiguration() {
    return const BetterPlayerSubtitlesConfiguration();
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
}
