# fun with bash
This is a repository of random bash scripts, in addition to these lovely commands.

## Webcam Stuff

### Opening Local Webcam with dd and mplayer
see [Maciej Piechotka](https://unix.stackexchange.com/users/305/maciej-piechotka)'s post [here](https://unix.stackexchange.com/a/2311/260866)

```bash
dd if=/dev/video0 | mplayer tv://device=/dev/stdin
## OR ##
mkfifo videoCam
dd if=/dev/video0 of=videoCam &
mplayer tv://device=videoCam
```


### Opening Local Webcam with VLC:
```bash
sudo apt update && sudo apt install vlc
cvlc v4l2:///dev/video0
```

### Opening Local Webcam with mplayer
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
- `-hide_banner` is what it says it is
- `-r` is framerate
- `-s` is size of window in pixels
- `-f` is the format
- `-i` is the input device

__Again, but with `tee` for saving to a file as well__
```bash
[me@myComp /some/dir]$ ssh someone@remoteComp "ffmpeg  -r 14 -s 640x480 -f video4linux2 -i /dev/video0 -f matroska -" | tee $(date +%Y-%m-%d_%H-%M-%S)_recording.mkv | mplayer - -idle
```

It also works with netcat:
```bash
# From remote machine
ffmpeg -hide_banner -r 14 -s 640x480 -f video4linux2 -i /dev/video0 -f matroska - | nc -l 12345

# from local machine
nc <remote machine IP> 12345 | mplayer - -idle
```

Whether using netcat or ssh, the delay was roughly 9 seconds. So, the benefit of netcat is bypassing ssh security, like odd ports and firewalls. Netcat worked without opening the port on either computer's firewall. However, netcat has to be started on the remote computer somehow...