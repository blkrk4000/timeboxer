#!/bin/sh
# Erzeugt die PNGs für das Asset-Verzeichnis aus den SVG-Quellen (benötigt rsvg-convert).
set -e
cd "$(dirname "$0")"
A=../TomatoBar/Assets.xcassets
for pair in idle:BarIconIdle work:BarIconWork rest:BarIconShortRest post:BarIconLongRest; do
  n=${pair%%:*}; d=$A/${pair##*:}.imageset
  rsvg-convert -w 16 -h 16 bar-$n.svg -o $d/icon_16x16.png
  rsvg-convert -w 32 -h 32 bar-$n.svg -o $d/icon_16x16@2x.png
  rsvg-convert -w 48 -h 48 bar-$n.svg -o $d/icon_16x16@3x.png
done
for s in 16 32 64 128 256 512 1024; do rsvg-convert -w $s -h $s app.svg -o /tmp/app-$s.png; done
d=$A/AppIcon.appiconset
cp /tmp/app-16.png $d/icon_16x16.png;   cp /tmp/app-32.png $d/icon_16x16@2x.png
cp /tmp/app-32.png $d/icon_32x32.png;   cp /tmp/app-64.png $d/icon_32x32@2x.png
cp /tmp/app-128.png $d/icon_128x128.png; cp /tmp/app-256.png $d/icon_128x128@2x.png
cp /tmp/app-256.png $d/icon_256x256.png; cp /tmp/app-512.png $d/icon_256x256@2x.png
cp /tmp/app-512.png $d/icon_512x512.png; cp /tmp/app-1024.png $d/icon_512x512@2x.png
