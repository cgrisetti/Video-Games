# Embershore: four-player split-screen performance

Measured by tools/embershore_screenshots.gd at 2026-11-07T15:16:51, window (1920, 1080) (vsync off), 4 local players, 180 frames a stage after 150 to settle.

| Stage | FPS | process ms | physics ms | draw calls | primitives | near / mid / far landblocks |
| :-- | --: | --: | --: | --: | --: | :-- |
| bramblebridge | 59 | 16.94 | 2.80 | 8225 | 7533464 | 12 / 19 / 128 |
| moss_oaks | 49 | 18.03 | 2.73 | 3931 | 6560712 | 14 / 23 / 128 |
| sunken_holloway | 63 | 16.00 | 2.28 | 1901 | 4685897 | 9 / 21 / 128 |
| doverslap_bridge | 71 | 28.73 | 2.27 | 1753 | 4854592 | 11 / 20 / 128 |
| coast_road | 55 | 19.85 | 1.98 | 8443 | 7389940 | 12 / 17 / 128 |
| hearthstead | 65 | 15.78 | 1.73 | 5955 | 8156558 | 12 / 23 / 128 |
| mill_downs | 60 | 16.71 | 2.28 | 3156 | 5777026 | 14 / 30 / 128 |
