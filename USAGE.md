### FPS

Aseprite counts milliseconds per frame, for each frame.

Whereas Defold counts frame per second, across all animation frames.

| aseprite avg (ms/f) | defold fps (f/s) |
| ------------------- | ---------------- |
| 500 ms              | 2 fps            |
| 100 ms              | 10 fps           |
| 69 ms               | 14 fps           |

### Playback

| ase: direction    | ase: userdata | defold playback |
| ----------------- | ------------- | --------------- |
| Forward           |               | Once Forward    |
| Reverse           |               | Once Backward   |
| Ping-pong         |               | Once Ping Pong  |
| Ping-pong Reverse |               | Once Ping Pong  |
| Forward           | once          | Once Forward    |
| Reverse           | once          | Once Backward   |
| Ping-pong         | once          | Once Ping Pong  |
| Ping-pong Reverse | once          | Once Ping Pong  |
| Forward           | loop          | Loop Forward    |
| Reverse           | loop          | Loop Backward   |
| Ping-pong         | loop          | Loop Ping Pong  |
| Ping-pong Reverse | loop          | Loop Ping Pong  |
| Forward           | none          | None            |
| Reverse           | none          | None            |
| Ping-pong         | none          | None            |
| Ping-pong Reverse | none          | None            |

### Lua Modules

...
