## finalduty/archlinux
Minimal base docker image for ArchLinux, built from scratch daily

### Releases and Tags

* ````latest```` - Updated on each push to Master
* ````daily```` - Updated once per day
* ````weekly```` - Updated every Sunday night
* ````monthly```` - Updated on the first day of every month

### Arch Linux
![](https://sources.archlinux.org/other/artwork/archlinux-logo-dark-90dpi.png)

Arch Linux is an independently developed, i686/x86-64 general-purpose GNU/Linux distribution that strives to provide the latest stable versions of most software by following a rolling-release model, allowing for a one-time install with continuous upgrades. The default installation is a minimal base system, configured by the user to only add what is required for his purposes. 

> [wiki.archlinux.org](https://wiki.archlinux.org/index.php/Arch_Linux)

### Image Build Process
This image is built from scratch each day, using a modified version of manchoz's [mkimage-arch.sh](https://github.com/dotcloud/docker/blob/master/contrib/mkimage-arch.sh) script. The script is triggered by anacron and runs completely unattended. As such, you can expect a fresh, up to date base image, every day of the week.

### Caveats
#### Localisations and Man-Pages
To keep the size of the image down, a number of files are deleted during the build process including man pages and localisations. To see what files have been deleted, you can run ````pacman -Qkq````. If you need to replace one of these files, I would suggest reinstalling the packages to replace the files. If you want to further remove files, it's suggested that you do it in one layer to save on wasted space. You can use a Dockerfile such as the one below:

    FROM finalduty/archlinux:daily
    
    RUN pacman -Q | awk '{print $1}' | pacman -Syu -; pacman -Scc

#### systemd
Not currently supported. If you can make it work, please let me know.

![](http://dockeri.co/image/finalduty/archlinux)

