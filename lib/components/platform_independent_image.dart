import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../app_common.dart';
import '../screen_tools.dart';

class PlatformIndependentImage extends StatelessWidget with ScreenTools {
  final String imageUrl;
  final BoxFit? fit;
  final Codec<String, String> stringToBase64 = utf8.fuse(base64Url);

  PlatformIndependentImage({super.key, required this.imageUrl, this.fit});

  Widget buildWebImage(context) {
    return Image.network(
        AppCommon.boardGameGeekProxyUrl +
            "/cors-proxy/_" +
            stringToBase64.encode(this.imageUrl),
        height: fit == null
            ? getScreenHeightPercentageInPixels(
                context, ScreenTools.fiftyPercentScreen)
            : null,
        alignment: Alignment.topCenter,
        fit: fit ?? BoxFit.fitHeight);
  }

  Widget buildMobileCachedImage(context) {
    return CachedNetworkImage(
      imageUrl: this.imageUrl,
      imageBuilder: (context, provider) => Container(
        height: fit == null
            ? getScreenHeightPercentageInPixels(
                context, ScreenTools.fiftyPercentScreen)
            : null,
        decoration: BoxDecoration(
          image: DecorationImage(
              image: provider,
              fit: fit ?? BoxFit.fitHeight,
              alignment: Alignment.topCenter),
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
