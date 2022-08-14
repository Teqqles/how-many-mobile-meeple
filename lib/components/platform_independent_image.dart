import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../app_common.dart';
import '../screen_tools.dart';

class PlatformIndependentImage extends StatelessWidget with ScreenTools {
  final String imageUrl;
  final Codec<String, String> stringToBase64 = utf8.fuse(base64);

  PlatformIndependentImage({this.imageUrl});

  Widget buildWebImage(context) {
    return Image.network(
        AppCommon.boardGameGeekProxyUrl + "/cors-proxy/_" + stringToBase64.encode(this.imageUrl),
        height: getScreenHeightPercentageInPixels(
            context, ScreenTools.fiftyPercentScreen),
        fit: BoxFit.fitHeight
    );
  }

  Widget buildMobileCachedImage(context) {
    return CachedNetworkImage(
      imageUrl: this.imageUrl,
      imageBuilder: (context, provider) => Container(
        height: getScreenHeightPercentageInPixels(
            context, ScreenTools.fiftyPercentScreen),
        decoration: BoxDecoration(
          image: DecorationImage(
              image: provider, fit: BoxFit.fitHeight),
        ),
      ),
      placeholder: (context, url) => SpinKitCubeGrid(
          color: Theme.of(context).colorScheme.secondary,
          size: getScreenWidthPercentageInPixels(
              context, ScreenTools.fiftyPercentScreen)),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  Widget build(context) {
    return kIsWeb ? buildWebImage(context) : buildMobileCachedImage(context);
  }
}