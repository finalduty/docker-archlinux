### Releases and Tags

* ````latest```` - Updated on every push to Master [Dockerfile](https://github.com/finalduty/docker-archlinux/blob/master/Dockerfile)
* ````daily```` - Updated once every day [Dockerfile](https://github.com/finalduty/docker-archlinux/blob/daily/Dockerfile)
* ````weekly```` - Updated every Sunday night [Dockerfile](https://github.com/finalduty/docker-archlinux/blob/weekly/Dockerfile)
* ````monthly```` - Updated on the first day of every month [Dockerfile](https://github.com/finalduty/docker-archlinux/blob/monthly/Dockerfile)

Tagged images are built from the same source repo. The only difference is when the Git Tags on the repo are updated. For example, if you pull the monthly and daily images on the 1st of the month, the contents of each image will be the same. The only difference will be the Image ID as Dockerhub builds the two as seperate images.

### Arch Linux
![](https://sources.archlinux.org/other/artwork/archlinux-logo-dark-90dpi.png)

Arch Linux is an independently developed, i686/x86-64 general-purpose GNU/Linux distribution that strives to provide the latest stable versions of most software by following a rolling-release model, allowing for a one-time install with continuous upgrades. The default installation is a minimal base system, configured by the user to only add what is required for his purposes. 

> [wiki.archlinux.org](https://wiki.archlinux.org/index.php/Arch_Linux)

### Image Build Process
This image is built from scratch each day, using a modified version of [tmc's](https://github.com/tmc) [mkimage-arch.sh](https://github.com/dotcloud/docker/blob/master/contrib/mkimage-arch.sh) script. The script is triggered by anacron and runs completely unattended. As such, you can expect a fresh, up to date base image, every day of the week.


### Usage
Try out the container via CLI:
```
docker pull finalduty/docker:daily
docker run --rm -it finalduty/docker:daily
```

Build your own image from a Dockerfile via CLI:
```
cat << EOF > Dockerfile
FROM finalduty/docker:weekly
MAINTAINER foo <foo@bar.com>
RUN pacman -Syu vim --noconfirm; pacman -Scc --noconfirm
EOF
docker build -t local/archlinux -f Dockerfile .
```

### Caveats
##### Localisations and Man-Pages
To keep the size of the image down, a number of files are deleted during the build process, including man-pages and localisations. To see which files have been deleted, you can run ````pacman -Qkq````. If you need to replace one of these files, reinstall the applicable package then removing any extraneous files. Make sure to do this in one layer to save on wasted space. For instance if you wanted to add a certain localisation (en_GB in this example) you could use a Dockerfile such as the one below. It's a long one, but it'll help keep your image size down:

```
FROM finalduty/archlinux:daily
MAINTAINER foo <foo@bar.com>
RUN pacman -Q | awk '{print $1}' | pacman -Syu --noconfirm -; pacman -Scc --noconfirm; rm -r /usr/share/man/*; ls -d /usr/share/locale/* | egrep -v "alias|en_GB" | xargs rm -rf
```

##### systemd
I haven't tested if this works or what is required to get it to work. It is possible to take the ExecStart command out of a package's unit file and add that as a CMD layer to your own Dockerfile. This example will start xinetd and a bash shell so you can still attach to the container:

```
FROM finalduty/docker:monthly
MAINTAINER foo <foo@bar.com>
CMD /usr/bin/xinetd -dontfork; /bin/bash
```
