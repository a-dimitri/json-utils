JSON Utilities — macOS App Icon assets
========================================

icon_1024.png            Master render (1024×1024, transparent corners)
icon_512/256/128/64/32/16.png   Standalone PNGs at each size

AppIcon.iconset/         Apple iconset folder (correctly named for iconutil)
  icon_16x16.png         16
  icon_16x16@2x.png      32
  icon_32x32.png         32
  icon_32x32@2x.png      64
  icon_128x128.png       128
  icon_128x128@2x.png    256
  icon_256x256.png       256
  icon_256x256@2x.png    512
  icon_512x512.png       512
  icon_512x512@2x.png    1024

Build the .icns (run in this folder on macOS):
  iconutil -c icns AppIcon.iconset
  -> produces AppIcon.icns

Or drop icon_1024.png into Xcode's Assets.xcassets AppIcon slot
(Xcode 14+ accepts a single 1024 image and generates the rest).
