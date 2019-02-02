import 'package:harpy/api/twitter/data/tweet.dart';
import 'package:harpy/api/twitter/services/handle_response.dart';
import 'package:harpy/api/twitter/twitter_client.dart';
import 'package:harpy/core/cache/home_timeline_cache.dart';
import 'package:harpy/core/cache/tweet_cache.dart';
import 'package:harpy/core/cache/tweet_cache_isolate.dart';
import 'package:harpy/core/cache/user_timeline_cache.dart';
import 'package:harpy/core/misc/directory_service.dart';
import 'package:harpy/core/misc/isolate_work.dart';
import 'package:harpy/core/misc/json_mapper.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final Logger _log = Logger("TweetService");

class TweetService {
  TweetService({
    @required this.directoryService,
    @required this.twitterClient,
    @required this.homeTimelineCache,
    @required this.userTimelineCache,
  })  : assert(directoryService != null),
        assert(twitterClient != null),
        assert(homeTimelineCache != null),
        assert(userTimelineCache != null);

  final DirectoryService directoryService;
  final TwitterClient twitterClient;
  final HomeTimelineCache homeTimelineCache;
  final UserTimelineCache userTimelineCache;

  /// Returns a the home timeline for the logged in user.
  ///
  /// If the response status code is not 200 a [Future.error] is returned
  /// instead.
  Future<List<Tweet>> getHomeTimeline({
    Map<String, String> params,
  }) async {
    _log.fine("get home timeline");

    params ??= Map();
    params["count"] ??= "800"; // max: 800
    params["tweet_mode"] ??= "extended";

    final response = await twitterClient.get(
      "https://api.twitter.com/1.1/statuses/home_timeline.json",
      params: params,
    );

    if (response.statusCode == 200) {
      _log.fine("got response");

      // todo: handle all response in just one isolate

      // parse tweets
      List<Tweet> tweets = await isolateWork<String, List<Tweet>>(
        callback: _parseTweets,
        message: response.body,
      );

      _log.fine("parsed ${tweets?.length} tweets");

      // update cached home timeline tweets
      tweets = await isolateWork<List<Tweet>, List<Tweet>>(
        callback: updateCachedTweets,
        message: tweets,
        tweetCacheData: homeTimelineCache.data,
        directoryServiceData: directoryService.data,
      );

      tweets ??= [];
      _log.fine("got ${tweets.length} home timeline tweets");

      return tweets;
    } else {
      return Future.error(response.body);
    }
  }

  /// Returns the user timeline for the [userId] or [screenName].
  Future<List<Tweet>> getUserTimeline(
    String userId, {
    Map<String, String> params,
  }) async {
    _log.fine("get user timeline");

    params ??= Map();
    params["count"] ??= "800";
    params["tweet_mode"] ??= "extended";
    params["user_id"] = userId;

    final response = await twitterClient.get(
      "https://api.twitter.com/1.1/statuses/user_timeline.json",
      params: params,
    );

    if (response.statusCode == 200) {
      _log.fine("got response");

      // todo: handle all response in just one isolate

      // parse tweets
      List<Tweet> tweets = await isolateWork<String, List<Tweet>>(
        callback: _parseTweets,
        message: response.body,
      );

      _log.fine("parsed ${tweets?.length} tweets");

      // copy over harpy data from cached home timeline tweets
      tweets = await isolateWork<List<Tweet>, List<Tweet>>(
          callback: _copyHomeHarpyData,
          message: tweets,
          tweetCacheData: homeTimelineCache.data,
          directoryServiceData: directoryService.data);

      // then update cached tweet for user
      isolateWork<List<Tweet>, void>(
        callback: updateCachedTweets,
        message: tweets,
        tweetCacheData: userTimelineCache.user(userId).data,
        directoryServiceData: directoryService.data,
      );

      tweets ??= [];
      _log.fine("got ${tweets.length} home timeline tweets");

      return tweets;
    } else {
      return Future.error(response.body);
    }
  }

  /// Retweets the tweet with the [tweetId].
  Future retweet(String tweetId) async {
    final response = await twitterClient.post(
      "https://api.twitter.com/1.1/statuses/retweet/$tweetId.json",
    );

    return handleResponse(response);
  }

  /// Unretweets the tweet with the [tweetId].
  Future unretweet(String tweetId) async {
    final response = await twitterClient.post(
      "https://api.twitter.com/1.1/statuses/unretweet/$tweetId.json",
    );

    return handleResponse(response);
  }

  /// Favorites the tweet with the [tweetId].
  Future favorite(String tweetId) async {
    final response = await twitterClient.post(
      "https://api.twitter.com/1.1/favorites/create.json?id=$tweetId",
    );

    return handleResponse(response);
  }

  /// Unfavorites the tweet with the [tweetId].
  Future unfavorite(String tweetId) async {
    final response = await twitterClient.post(
      "https://api.twitter.com/1.1/favorites/destroy.json?id=$tweetId",
    );

    return handleResponse(response);
  }
}

List<Tweet> _parseTweets(String data) {
  _log.fine("parsing tweets");

  List<Tweet> tweets = mapJson(data, (json) => Tweet.fromJson(json));

  _log.fine("parsed ${tweets.length} tweets");
  return tweets;
}

List<Tweet> _copyHomeHarpyData(List<Tweet> tweets) {
  _log.fine("copy home harpy data");

  for (Tweet tweet in tweets) {
    Tweet homeTweet = TweetCache.isolateInstance.getTweet("${tweet.id}");
    if (homeTweet != null) {
      tweet.harpyData = homeTweet.harpyData;
    }
  }

  return tweets;
}