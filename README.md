# fun with bash
This is a repository of random bash scripts, in addition to these lovely commands.

## Webcam Stuff

### Opening Local Webcam With VLC:

```bash
sudo apt update && sudo apt install vlc
cvlc v4l2:///dev/video0
```

### Opening Local Webcam With Mplayer
```bash
sudo apt update && sudo apt install mplayer
mplayer tv://device=/dev/video0
```

### Streaming Remote Webcam in Terminal as ascii Video

see my post [here](https://unix.stackexchange.com/a/724658/260866)

```bash
[me@myComp /some/dir]$ ssh someone@remoteComp
...
[someone@remoteComp /some/dir]$ cvlc v4l2:///dev/video0
```

### Streaming Remote Webcam to mplayer

__Just the live stream__

see [confetti](https://unix.stackexchange.com/users/296862/confetti)'s post [here](https://unix.stackexchange.com/a/483328/260866)

```bash
[me@myComp /some/dir]$ sudo apt update && sudo apt install mplayer
[me@myComp /some/dir]$ ssh someone@remoteComp
...
[someone@remoteComp /some/dir]$ sudo apt update && sudo apt install ffmpeg
[someone@remoteComp /some/dir]$ exit
...
[me@myComp /some/dir]$ ssh someone@remoteComp "ffmpeg -hide_banner -r 14 -s 640x480 -f video4linux2 -i /dev/video0 -f matroska -" | mplayer - -idle
```
- '-hide_banner' is what it says it is
- 'r' is framerate
- 's' is size of window in pixels
- 'f' is the format
- 'i' is the input device

__Again, but with `tee` for saving to a file as well__
```bash
[me@myComp /some/dir]$ ssh someone@remoteComp "ffmpeg  -r 14 -s 640x480 -f video4linux2 -i /dev/video0 -f matroska -" | tee $(date +%Y-%m-%d_%H-%M-%S)_recording.mkv | mplayer - -idle
```
