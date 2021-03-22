import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harpy/api/api.dart';
import 'package:harpy/components/components.dart';

class HomeTimeline extends StatefulWidget {
  @override
  _HomeTimelineState createState() => _HomeTimelineState();
}

class _HomeTimelineState extends State<HomeTimeline> {
  ScrollController _controller;

  @override
  void initState() {
    super.initState();

    _controller = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
  }

  void _blocListener(BuildContext context, HomeTimelineState state) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    if (state is HomeTimelineResult &&
        state.initialResults &&
        state.newTweets > 0) {
      // scroll to the end after the list has been built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.jumpTo(
          // + height to make sure we reach the end
          _controller.position.maxScrollExtent + mediaQuery.size.height / 2,
        );
      });
    }
  }

  Widget _tweetBuilder(HomeTimelineState state, TweetData tweet) {
    if (state.showNewTweetsExist(tweet.originalIdStr)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NewTweetsText(state.newTweets),
          defaultVerticalSpacer,
          TweetCard(tweet, rememberVisibility: true),
        ],
      );
    } else {
      return TweetCard(tweet, rememberVisibility: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final HomeTimelineBloc bloc = context.watch<HomeTimelineBloc>();
    final HomeTimelineState state = bloc.state;

    return BlocListener<HomeTimelineBloc, HomeTimelineState>(
      listener: _blocListener,
      child: ScrollToStart(
        controller: _controller,
        child: CustomRefreshIndicator(
          offset: mediaQuery.padding.top + kToolbarHeight,
          onRefresh: () async {
            ScrollDirection.of(context).reset();
            bloc.add(const RefreshHomeTimeline());
            await bloc.refreshCompleter.future;
          },
          child: LoadMoreListener(
            listen: state.enableRequestOlder,
            onLoadMore: () async {
              bloc.add(const RequestOlderHomeTimeline());
              await bloc.requestOlderCompleter.future;
            },
            child: TweetList(
              state.timelineTweets,
              controller: _controller,
              tweetBuilder: (TweetData tweet) => _tweetBuilder(state, tweet),
              enableScroll: state.enableScroll,
              beginSlivers: const <Widget>[
                HomeAppBar(),
              ],
              endSlivers: <Widget>[
                if (state.showInitialLoading)
                  const SliverFillLoadingIndicator()
                else if (state.showNoTweetsFound)
                  SliverFillLoadingError(
                    message: const Text('no tweets found'),
                    onRetry: () => bloc.add(
                      const RefreshHomeTimeline(clearPrevious: true),
                    ),
                    onClearFilter: state.hasTimelineFilter
                        ? () => bloc.add(const FilterHomeTimeline(
                              timelineFilter: TimelineFilter.empty,
                            ))
                        : null,
                  )
                else if (state.showTimelineError)
                  SliverFillLoadingError(
                    message: const Text('error loading tweets'),
                    onRetry: () => bloc.add(
                      const RefreshHomeTimeline(clearPrevious: true),
                    ),
                  )
                else if (state.showLoadingOlder)
                  const SliverBoxLoadingIndicator()
                else if (state.showReachedEnd)
                  const SliverBoxInfoMessage(
                    secondaryMessage: Text('no more tweets available'),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: mediaQuery.padding.bottom),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}