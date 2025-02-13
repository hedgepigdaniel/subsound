import 'dart:convert';
import 'dart:developer';

import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/requests/stream_id.dart';
import 'package:subsound/utils/duration.dart';

import '../base_request.dart';
import '../subsonic.dart';
import 'get_cover_art.dart';

class AlbumResult {
  final String id;
  final String name;
  final String artistName;
  final String artistId;
  final String coverArtId;
  final String coverArtLink;
  final int year;
  final Duration duration;
  final int songCount;
  final List<SongResult> songs;
  final DateTime createdAt;

  AlbumResult({
    required this.id,
    required this.name,
    required this.artistName,
    required this.artistId,
    required this.coverArtId,
    required this.coverArtLink,
    required this.year,
    required this.duration,
    required this.songCount,
    required this.createdAt,
    this.songs = const [],
  });

  String durationNice() {
    return formatDuration(duration);
  }
}

class SongResult {
  final String id;
  final String playUrl;
  final String? parent;
  final String title;
  final String artistName;
  final String artistId;
  final String albumName;
  final String albumId;
  final String coverArtId;
  // TODO: convert to Uri?
  final String coverArtLink;
  final int year;
  final Duration duration;
  final bool isVideo;
  final DateTime createdAt;
  final String type;
  final int bitRate;
  final int trackNumber;
  final int fileSize;
  final bool starred;
  final DateTime? starredAt;
  final String contentType;
  final String suffix;
  final int playCount;

  SongResult({
    required this.id,
    required this.playUrl,
    this.parent,
    required this.title,
    required this.artistName,
    required this.artistId,
    required this.albumName,
    required this.albumId,
    required this.coverArtId,
    required this.coverArtLink,
    required this.year,
    required this.duration,
    this.isVideo = false,
    required this.createdAt,
    required this.type,
    required this.bitRate,
    required this.trackNumber,
    required this.fileSize,
    required this.starred,
    required this.starredAt,
    required this.contentType,
    required this.suffix,
    required this.playCount,
  });

  String durationNice() {
    return formatDuration(duration);
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    final hours = duration.inHours;
    var minutes = duration.inMinutes;
    if (minutes > 75) {
      minutes = minutes - (hours * 60);
      var seconds = duration.inSeconds - (minutes * 60);
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      var seconds = duration.inSeconds - (minutes * 60);
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  static SongResult fromJson(
    Map<String, dynamic> songData,
    SubsonicContext ctx,
  ) {
    final songArtId = songData['coverArt'] as String? ?? '';
    final coverArtLink = songArtId.isNotEmpty
        ? GetCoverArt(songArtId).getImageUrl(ctx)
        : fallbackImageUrl;

    final duration = getDuration(songData['duration']);

    final id = songData['id'] as String;

    StreamFormat streamFormat = StreamFormat.mp3;
    final playUrl = StreamItem(
      id,
      streamFormat: streamFormat,
    ).getDownloadUrl(ctx);

    String suffix = songData['suffix'] as String? ?? '';
    String contentType = songData['contentType'] as String? ?? '';
    suffix = streamFormat.toSuffix() ?? suffix;
    contentType = streamFormat.toContentType() ?? contentType;

    final artistId = songData['artistId'];
    if (artistId == null) {
      log('artistId $id');
    }

    return SongResult(
      id: id,
      playUrl: playUrl,
      parent: songData['parent'] as String? ?? '',
      title: songData['title'] as String? ?? '',
      artistName: songData['artist'] as String? ?? '',
      artistId: artistId as String? ?? '',
      albumName: songData['album'] as String,
      albumId: songData['albumId'] as String,
      coverArtId: songArtId,
      coverArtLink: coverArtLink,
      year: songData['year'] as int? ?? 0,
      duration: duration,
      isVideo: songData['isVideo'] as bool? ?? false,
      createdAt: DateTime.parse(songData['created'] as String),
      type: songData['type'] as String,
      bitRate: songData['bitRate'] as int? ?? 0,
      trackNumber: songData['track'] as int? ?? 0,
      fileSize: songData['size'] as int? ?? 0,
      starred: parseStarred(songData['starred'] as String?),
      starredAt: parseDateTime(songData['starred'] as String?),
      contentType: contentType,
      suffix: suffix,
      playCount: songData['playCount'] as int? ?? 0,
    );
  }
}

class GetSongRequest extends BaseRequest<SongResult> {
  final String id;

  GetSongRequest(this.id);

  @override
  String get sinceVersion => '1.8.0';

  @override
  Future<SubsonicResponse<SongResult>> run(SubsonicContext ctx) async {
    final response = await ctx.client
        .get(ctx.buildRequestUri('getSong', params: {'id': id}));

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (data['subsonic-response']['status'] != 'ok') {
      throw Exception(data);
    }

    final songData = data['subsonic-response']['song'] as Map<String, dynamic>;

    final songResult = SongResult.fromJson(songData, ctx);

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'] as String,
      songResult,
    );
  }
}

class GetAlbum extends BaseRequest<AlbumResult> {
  final String id;

  GetAlbum(this.id);

  @override
  String get sinceVersion => '1.8.0';

  @override
  Future<SubsonicResponse<AlbumResult>> run(SubsonicContext ctx) async {
    final response = await ctx.client
        .get(ctx.buildRequestUri('getAlbum', params: {'id': id}));

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (data['subsonic-response']['status'] != 'ok') {
      throw Exception(data);
    }

    final albumDataNew = data['subsonic-response']['album'];
    final String? coverArtId = albumDataNew['coverArt'] as String?;

    final List<dynamic>? songList = albumDataNew['song'] as List<dynamic>;

    final songs =
        List<Map<String, dynamic>>.from(songList ?? []).map((songData) {
      return SongResult.fromJson(songData, ctx);
    }).toList();

    final coverArtLink = coverArtId != null
        ? GetCoverArt(coverArtId).getImageUrl(ctx)
        : fallbackImageUrl;

    // log('coverArtLink=$coverArtLink');

    final duration = getDuration(albumDataNew['duration']);

    final albumId = albumDataNew['id'] as String;

    final albumResult = AlbumResult(
      id: albumId,
      name: albumDataNew['name'] as String? ?? '',
      artistName: albumDataNew['artist'] as String? ?? '',
      artistId: albumDataNew['artistId'] as String? ?? '',
      coverArtId: coverArtId ?? albumId,
      coverArtLink: coverArtLink,
      year: albumDataNew['year'] as int? ?? 0,
      duration: duration,
      songCount: albumDataNew['songCount'] as int? ?? 0,
      createdAt: DateTime.parse(albumDataNew['created'] as String),
      songs: songs,
    );

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'] as String,
      albumResult,
    );
  }
}
