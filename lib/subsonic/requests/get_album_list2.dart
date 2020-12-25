import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:subsound/subsonic/subsonic.dart';

import './get_album_list.dart';

class GetAlbumList2 extends BaseRequest<List<Album>> {
  final GetAlbumListType type;
  final int size;
  final int offset;
  final String musicFolderId;

  GetAlbumList2({
    @required this.type,
    this.size,
    this.offset,
    this.musicFolderId,
  });

  @override
  String get sinceVersion => '1.8.0';

  @override
  Future<SubsonicResponse<List<Album>>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri(
      'getAlbumList2',
      params: {
        'type': describeEnum(type),
        'size': size.toString(),
        'offset': offset.toString(),
        'musicFolderId': musicFolderId
      }..removeWhere((key, value) => value == null),
    ));

    final data =
        jsonDecode(utf8.decode(response.bodyBytes))['subsonic-response'];

    if (data['status'] != 'ok') throw StateError(data);

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      (data['albumList2']['album'] as List)
          .map((album) => Album.parse(ctx, album))
          .toList(),
    );
  }
}
