import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:subsound/subsonic/subsonic.dart';

class Search3Result {
  final List<Song> songs;

  Search3Result(this.songs);
}

class CountOffset {
  final int count, offset;

  const CountOffset({
    @required this.count,
    this.offset = 0,
  });
}

class Search3 extends BaseRequest<Search3Result> {
  @override
  String get sinceVersion => '1.8.0';

  final String query;

  final CountOffset artist, album, song;
  final String musicFolderId;

  Search3(this.query, {this.artist, this.album, this.song, this.musicFolderId});

  @override
  Future<SubsonicResponse<Search3Result>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri(
      'search3',
      params: {'query': query}
        ..addAll(
          artist != null
              ? {
                  'artistCount': '${artist.count}',
                  'artistOffset': '${artist.offset}'
                }
              : {},
        )
        ..addAll(
          album != null
              ? {
                  'albumCount': '${album.count}',
                  'albumOffset': '${album.offset}'
                }
              : {},
        )
        ..addAll(
          song != null
              ? {'songCount': '${song.count}', 'songOffset': '${song.offset}'}
              : {},
        ),
    ));

    final data =
        jsonDecode(utf8.decode(response.bodyBytes))['subsonic-response'];

    if (data['status'] != 'ok') throw StateError(data);

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      Search3Result(
        (data['searchResult3']['song'] as List ?? const [])
            .map((song) => Song.parse(song, serverId: ctx.serverId))
            .toList(),
      ),
    );
  }
}
