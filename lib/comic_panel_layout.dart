import 'package:flutter/material.dart';

import 'video_export_contract.dart';

List<Rect> comicPanelLayout(ComicTemplate template) {
  const gap = 0.025;
  return switch (template) {
    ComicTemplate.fourPanel => [
      const Rect.fromLTWH(gap, gap, 0.4625, 0.4625),
      const Rect.fromLTWH(0.5125, gap, 0.4625, 0.4625),
      const Rect.fromLTWH(gap, 0.5125, 0.4625, 0.4625),
      const Rect.fromLTWH(0.5125, 0.5125, 0.4625, 0.4625),
    ],
    ComicTemplate.sixPanel => [
      for (var row = 0; row < 3; row++)
        for (var column = 0; column < 2; column++)
          Rect.fromLTWH(
            gap + column * 0.4875,
            gap + row * 0.325,
            0.4625,
            0.3,
          ),
    ],
    ComicTemplate.heroPanel => [
      const Rect.fromLTWH(gap, gap, 0.55, 0.95),
      const Rect.fromLTWH(0.60, gap, 0.375, 0.4625),
      const Rect.fromLTWH(0.60, 0.5125, 0.375, 0.4625),
    ],
    ComicTemplate.dynamic => [
      const Rect.fromLTWH(gap, gap, 0.46, 0.56),
      const Rect.fromLTWH(gap, 0.61, 0.46, 0.365),
      const Rect.fromLTWH(0.51, gap, 0.465, 0.46),
      const Rect.fromLTWH(0.51, 0.51, 0.465, 0.465),
    ],
    ComicTemplate.vertical => [
      for (var row = 0; row < 4; row++)
        Rect.fromLTWH(gap, gap + row * 0.25, 0.95, 0.225),
    ],
  };
}
