# Embershore: four-player split-screen performance

Measured by tools/embershore_screenshots.gd at 2026-11-07T09:52:46, window (1920, 1080), 4 local players, 180 frames a stage after 150 to settle.

| Stage | FPS | process ms | physics ms | draw calls | primitives | near / mid / far landblocks |
| :-- | --: | --: | --: | --: | --: | :-- |
| bramblebridge | 58 | 15.46 | 2.77 | 7957 | 7620438 | 12 / 19 / 128 |
| moss_oaks | 38 | 23.64 | 2.84 | 2882 | 22285387 | 14 / 23 / 128 |
| sunken_holloway | 65 | 15.51 | 2.14 | 1714 | 4264468 | 9 / 21 / 128 |
| doverslap_bridge | 74 | 13.73 | 1.94 | 1458 | 3994701 | 11 / 20 / 128 |
| coast_road | 55 | 17.12 | 1.96 | 7978 | 6490347 | 12 / 17 / 128 |
| hearthstead | 67 | 15.08 | 1.71 | 5372 | 6415573 | 12 / 23 / 128 |
| mill_downs | 65 | 15.48 | 2.51 | 3000 | 5347375 | 14 / 30 / 128 |
