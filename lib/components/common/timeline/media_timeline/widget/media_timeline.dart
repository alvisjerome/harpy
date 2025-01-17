import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harpy/components/components.dart';
import 'package:harpy/core/core.dart';
import 'package:harpy/harpy_widgets/harpy_widgets.dart';
import 'package:provider/provider.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

/// Builds the list of tweet media widgets for a [MediaTimelineModel].
///
/// Tapping a media will open the media gallery.
class MediaTimeline extends StatefulWidget {
  const MediaTimeline({
    required this.showInitialLoading,
    required this.showLoadingOlder,
  });

  final bool showInitialLoading;
  final bool showLoadingOlder;

  @override
  _MediaTimelineState createState() => _MediaTimelineState();
}

class _MediaTimelineState extends State<MediaTimeline> {
  bool _buildTiled = app<LayoutPreferences>().mediaTiled;

  Widget _buildTopRow(Config config, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: config.edgeInsetsOnly(
          top: true,
          left: true,
          right: true,
        ),
        child: Row(
          children: [
            const Spacer(),
            HarpyButton.raised(
              padding: config.edgeInsets,
              elevation: 0,
              backgroundColor: theme.cardTheme.color,
              icon: Icon(
                _buildTiled
                    ? CupertinoIcons.square_split_1x2
                    : CupertinoIcons.square_split_2x2,
              ),
              onTap: () => setState(() {
                final value = !_buildTiled;
                _buildTiled = value;
                app<LayoutPreferences>().mediaTiled = value;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemBuilder(List<MediaTimelineEntry> entries, int index) {
    return MediaTimelineMediaWidget(
      entry: entries[index],
      index: index,
      onImageTap: () => _showGallery(
        context: context,
        entries: entries,
        initialIndex: index,
      ),
      onVideoTap: (videoPlayerModel) => _showGallery(
        context: context,
        entries: entries,
        initialIndex: index,
        videoPlayerModel: videoPlayerModel,
      ),
      buildCompactOverlay: _buildTiled,
    );
  }

  Widget _buildList(Config config, List<MediaTimelineEntry> entries) {
    return SliverWaterfallFlow(
      gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
        crossAxisCount: _buildTiled ? 2 : 1,
        mainAxisSpacing: config.smallPaddingValue,
        crossAxisSpacing: config.smallPaddingValue,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, index) => _itemBuilder(entries, index),
        childCount: entries.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final config = context.watch<ConfigCubit>().state;

    final model = context.watch<MediaTimelineModel>();
    final entries = model.value;

    return CustomScrollView(
      key: const PageStorageKey<String>('user_media_timeline'),
      slivers: [
        if (widget.showInitialLoading)
          const SliverFillLoadingIndicator()
        else if (model.hasEntries) ...[
          _buildTopRow(config, theme),
          SliverPadding(
            padding: config.edgeInsets,
            sliver: _buildList(config, entries),
          ),
          if (widget.showLoadingOlder) const SliverBoxLoadingIndicator(),
        ] else
          const SliverFillLoadingError(
            message: Text('no media found'),
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: mediaQuery.padding.bottom),
        ),
      ],
    );
  }
}

/// Show the media gallery for the media timeline [entries].
///
/// The [videoPlayerModel] is used when tapping on a gif or video to build
/// the video or gif with the video player model.
void _showGallery({
  required BuildContext context,
  required List<MediaTimelineEntry> entries,
  required int initialIndex,
  HarpyVideoPlayerModel? videoPlayerModel,
}) {
  Navigator.of(context).push<void>(
    HeroDialogRoute<void>(
      builder: (_) => MediaTimelineGalleryOverlay(
        entries: entries,
        initialIndex: initialIndex,
        videoPlayerModel: videoPlayerModel,
      ),
    ),
  );
}
