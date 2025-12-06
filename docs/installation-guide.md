
# ======================================================================================================
# USB-TTL
# ======================================================================================================
识别后设备在/dev/ttyUSB0, 然后Putty就按普通串口设置即可。




# ======================================================================================================
# Firmware update
# ======================================================================================================
# BIOS
+ Bios version
sudo dmidecode -s bios-version

+ iso
g2uj33us.iso BIOS Update (Bootable CD)



# SATA SSD-850 EVO FIRMWARE
1. ISO
[FIRMWARE](https://www.samsung.com/semiconductor/minisite/ssd/download/tools/)

2. dd
dmesg  | grep sdc
sudo dd if=Samsung_SSD_850_EVO_EMT02B6Q_Win.iso of=/dev/sdc bs=4M status=progress

3. *** BIOS must choose UEFI+LEGACY ***
启动它并更新850 EVO。


# Check & Update
## check
sudo service fwupd start
sudo fwupdmgr get-devices
sudo fwupdmgr get-updates


## update 
sudo fwupdmgr refresh --force
sudo fwupdmgr update

*** X230 is earlier than 2015. Cannot use this way to update firmware ****

```
sudo fwupdmgr update
WARNING: UEFI capsule updates not available or enabled in firmware setup
  See https://github.com/fwupd/fwupd/wiki/PluginFlag:capsules-unsupported for more information.
Devices with no available firmware updates: 
 • BCM20702A0
 • Samsung SSD 850 EVO 250GB
 • Thinklife SSD ST600 MSATA 128G
 • UEFI dbx
No updatable devices
```




# ======================================================================================================
#   系统安装
# ======================================================================================================
# U盘准备
1. 下载ISO

2. 写入ISO到u盘
+ windows
用rufus

+ linux
sudo dmesg  | grep sdc [sda/sdb/sdc/...]
sudo dd if=ubuntu-24.04.1-desktop-amd64.iso of=/dev/sdc bs=4M status=progress


# 插入U盘，选择最小安装

# 安装完，U盘不拔下重启。

# 重启后，根据提示拔下U盘。


# Finish
+ 跳过Setup Live patch
+ 不发送system info.
+ 不启动Location Services

	

# ======================================================================================================
#   系统设置  
# ======================================================================================================
# root
```
sudo passwd root

password: 8pSZ8wSj

su root 
```

# 卸载 snapd, 安装原版软件中心 (22.04 LTS not good)
```
sudo apt update
sudo apt install ubuntu-software
sudo apt autoremove --purge snapd 
sudo apt upgrade
```



# 修改host文件，屏蔽站点
sudo gedit /etc/hosts
增加广告站点如下：
```
127.0.0.1	baidustatic.com
127.0.0.1	cpro.baidustatic.com
...

```



# 网卡
0. X200内部网卡：
Network controller		: Intel Corporation PRO/Wireless 5100 AGN 

1. basic
ubuntu 从 17.10 开始，已放弃在 /etc/network/interfaces 里固定 IP 的配置，即使配置了也不会生效。
改成 netplan 方式 ，配置写在 /etc/netplan/01-netcfg.yaml 或者类似名称的 yaml 文件里

2. rtl8812au 无线网卡驱动
+ morrownr
https://github.com/morrownr/8812au

+ gordboy
https://github.com/gordboy/rtl8812au-5.6.4.2



# ======================================================================================================
# 软件安装和使用
# ======================================================================================================

# Gnome-Tweak-Tool
sudo apt install gnome-tweak-tool -y
sudo apt install gnome-tweaks -y


- 去掉桌面图标
- 改主题
- 改title
- 增加开机启动程序（如Nextcloud,bluemail,...)







# Device manager (System Profiler)
sudo apt install hardinfo -y



# adb/fastboot
sudo apt-get install android-tools-adb android-tools-fastboot -y



# Bluemail


## NextCloud
1. Download Linux AppImage
https://nextcloud.com/install/#install-clients
 
mv Nextcloud-3.2.4-x86_64.AppImage ~/programs/nextcloud


2. run
cd ~/programs/nextcloud
chmod +x Nextcloud-3.2.4-x86_64.AppImage
./+AppImage文件名


3. 服务器地址
nc.nl.tab.digital


## 五笔输入法
1. 安装
sudo apt-get install ibus-rime librime-data-wubi librime-data-pinyin-simp  -y
重启电脑


2. 配置
把rime目录下所有文件copy到/usr/share/rime-data/下
重新启动并部署


3. 增加输入法
### 20.04
设置-地区和语言-输入源(input source)中，
+ 增加other (在列表最后)
+ other中选择Chinese(Rime)

### 22.04
1. Open Settings, go to Region & Language -> Manage Installed Languages
2. Make sure Keyboard Input method system has Ibus selected.
3. Install / Remove languages.
4. Select Chinese (Simplified). Apply.
5. Reboot
6. Log back in, reopen Settings, go to Keyboard.
7. Click on the "+" sign under Input sources. 
Select Chinese (China) and then Chinese (Intelligent Pinyin).


### 24.04
Same as 22.04


4. 切换
Ctrl+空格 切换语言。


5. 输入方案选单
按组合键 Ctrl+~ 或 F4 键唤出输入方案选单，由此调整 Rime 输入法最常用的选项。。





## putty
1. 安装
从软件中心安装 Putty SSH Client

2. 配置
**注意**： AC3100的外网端口是30000

3. 配置文件位置
copy 现有配置到 ~/.putty/sessions/



## GoldenDict
1. 安装
从软件中心安装 GoldenDict

2. 配置


## SSH server
1. install
sudo apt update
sudo apt install openssh-server

2. status
sudo systemctl status ssh

3. firewall
Ubuntu comes with a firewall configuration tool called UFW. If the firewall is enabled on your system, make sure to open the SSH port:
sudo ufw allow ssh

4. ip
If you don’t know your IP address you can easily find it using the ip command :
ip a
ip addr show

5. public key
cat ~/.ssh/ubuntu.pub >> authorized_keys


6. attribute
chmod 600 authorized_keys
chmod 700 ~/.ssh

7. config
sudo nano /etc/ssh/sshd_config
PubkeyAuthentication yes

8. restart server
sudo service sshd restart



## SSH key
1. Check for existing SSH key pair.
ls -al ~/.ssh/*.pub


2. Generate a new SSH key pair.
The following command will generate a new 4096 bits SSH key pair with your email address as a comment:
ssh-keygen -t rsa -b 4096 -C "liu_dong@outlook.com"

key name: ubuntu.pub


3. Copy the public key
in order to be able to login to your server without a password you need to copy the public key to the server you want to manage.
The easiest way to copy your public key to your server is to use a command called ssh-copy-id. On your local machine terminal type:
ssh-copy-id remote_username@server_ip_address
or
cat ~/.ssh/ubuntu.pub >> authorized_keys



## aria2
1. install
sudo apt install aria2 -y

2. aria2.conf, aria2.log, aria2.session, aria2c.service
copy 现有的即可

3. 桌面快捷方式
sudo desktop-file-install aria2c.desktop

4. 运行
sudo aria2c --conf-path=/home/david/programs/aria2/aria2.conf

如果没有提示错误，按ctrl+c停止运行命令，转为后台运行：
sudo aria2c --conf-path=/home/david/programs/aria2/aria2.conf -D

5. 服务模式开机启动
```
sudo cp aria2c.service /etc/init.d/aria2c.service
sudo chmod 755 /etc/init.d/aria2c.service
sudo update-rc.d aria2c.service defaults

sudo service aria2c start
sudo systemctl status aria2c
```

6. bt-tracker
很多人在初次使用 aria2 时会发现始终无速度的问题，这里有一份 trackers 列表，只需要添加进 aria2 就能明显的提高下载速度。
添加方法：打开 aria2 的配置文件 aria2.conf，然后在最后面添加一行：
bt-tracker=服务器1,服务器2,服务器2


在aria2.conf 加入
bt-racker=udp://tracker.coppersurfer.tk:6969/announce,udp://tracker.internetwarriors.net:1337/announce,udp://tracker.opentrackr.org:1337/announce



## Firefox
1. 扩展不显示在工具栏上
设置+隐私+历史记录,	去掉 "Always use private browsing mode".



## LinSSID
wifi强度

sudo apt install linssid -y



## git
sudo apt install git -y



## VLC
1. log
VLC -> Tools -> Messages



## Double Commander
+ Download **gtk** version from 
https://sourceforge.net/p/doublecmd/wiki/Download/

doublecmd-1.0.11.gtk2.x86_64.tar.xz


+ Setup
unzip folder to programs


+ Insall desktop file: doublecmd.desktop

1. content
```
[Desktop Entry]
Name=doublecmd
GenericName=doublecmd
Comment=
Exec=/home/david/programs/doublecmd/doublecmd
Icon=/home/david/programs/doublecmd/doublecmd.png
Type=Application
Categories=Network;
X-Desktop-File-Install-Version=0.26
```

2. install
```
sudo desktop-file-validate doublecmd.desktop 
sudo desktop-file-install doublecmd.desktop 
```


+ rar
sudo apt install libunrar5


+ config
/home/david/.config/doubldcmd/doublecmd.xml


+ show all files
ctrl+.


+ samba
地址栏直接输入： smb://192.168.2.1


+ plugin
/usr/lib/doublecmd/plugins/


+ Quick View 图片自动缩放
1. Open Innerviewer (F3)
2. Image - Strecth
3. Close Innerviewer



+ rar (other way)
1. install unrar
```
sudo apt install unrar
```

2. Double Commander v0.9.6 fix for error "Cannot load library libunrar.so! Please check your installation." 
[https://gist.github.com/luckylittle/90b250c72f482fd1932ca128c50497dd]
```
wget http://www.rarlab.com/rar/unrarsrc-5.9.2.tar.gz
tar -xvf unrarsrc-5.9.2.tar.gz
cd unrar
make -f makefile lib
sudo make install-lib
sudo ln -s /usr/lib/libunrar.so /usr/lib64/doublecmd
```





# Gnome 扩展
1. Install
```
sudo apt install gnome-shell-extension-manager
```

After that, we’ll launch the Activities menu, search for Extensions, and open it:
然后手动查找并安装下面的扩展


2. Others
[Vitals](https://extensions.gnome.org/extension/1460/vitals/)

[OpenWeather](https://extensions.gnome.org/extension/750/openweather/)

[Screenshot Tool](https://extensions.gnome.org/extension/1112/screenshot-tool/)

[Clipboard Indicator](https://extensions.gnome.org/extension/779/clipboard-indicator/)




# 摄像头
sudo apt install cheese




# ======================================================================================================
#   系统使用  
# ======================================================================================================

