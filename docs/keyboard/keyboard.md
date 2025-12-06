*** 解决G7BTS遥控器 "OK"键 ***

################################################################################################################################
# 修改hwdb配置, 改变scancode。
################################################################################################################################
# udev
udev provides a builtin function called hwdb to maintain the hardware database index in /etc/udev/hwdb.bin. The database is compiled from files with .hwdb extension located in directories /usr/lib/udev/hwdb.d/, /run/udev/hwdb.d/ and /etc/udev/hwdb.d/. 

The default scancodes-to-keycodes mapping file is /usr/lib/udev/hwdb.d/60-keyboard.hwdb. See hwdb(7) for details. 


# Generic input devices (also USB keyboards) identified by the usb kernel modalias:
```
evdev:input:b<bus_id>v<vendor_id>p<product_id>e<version_id>-<modalias>
```
where <vendor_id>, <product_id> and <version_id> are the 4-digit hex uppercase vendor, product and version IDs 

(you can find those by running the lsusb command) and <modalias> is an arbitrary length input-modalias describing the device capabilities. <bus_id> is the 4-digit hex bus id and should be 0003 for usb devices. The possible <bus_id> values are defined in /usr/include/linux/input.h (you can run awk '/BUS_/ {print $2, $3}' /usr/include/linux/input.h to get a list).
   

# 获取 <vendor_id>, <product_id> and <version_id>
## 方法一
1. 安装hardinfo
sudo apt install hardinfo -y

2. hardinfo - Input Devices - G7BTS Comsumer Control
```
Device Information
 Name       G7BTS Comsumer Control
 Type       keyboard
 Bus        0x0005
 Vender     0x045e
 Product    0x0041
 Version    0x0300

```

## 方法二
dmesg | grep -i G7BTS
```
[  157.109242] input: G7BTS Keyboard as /devices/virtual/misc/uhid/0005:045E:0041.0001/input/input17
[  157.109486] input: G7BTS Mouse as /devices/virtual/misc/uhid/0005:045E:0041.0001/input/input18
[  157.109636] input: G7BTS Consumer Control as /devices/virtual/misc/uhid/0005:045E:0041.0001/input/input19
[  157.109708] input: G7BTS System Control as /devices/virtual/misc/uhid/0005:045E:0041.0001/input/input20
[  157.109773] hid-generic 0005:045E:0041.0001: input,hidraw0: BLUETOOTH HID v3.00 Keyboard [G7BTS] on 3c:77:e6:f3:46:d5
[  190.159330] input: G7BTS Keyboard as /devices/virtual/misc/uhid/0005:045E:0041.0002/input/input21
[  190.159769] input: G7BTS Mouse as /devices/virtual/misc/uhid/0005:045E:0041.0002/input/input22
[  190.160020] input: G7BTS Consumer Control as /devices/virtual/misc/uhid/0005:045E:0041.0002/input/input23
[  190.160125] input: G7BTS System Control as /devices/virtual/misc/uhid/0005:045E:0041.0002/input/input24
[  190.160238] hid-generic 0005:045E:0041.0002: input,hidraw0: BLUETOOTH HID v3.00 Keyboard [G7BTS] on 3c:77:e6:f3:46:d5
[ 2178.126613] input: G7BTS Keyboard as /devices/virtual/misc/uhid/0005:045E:0041.0003/input/input25
[ 2178.127258] input: G7BTS Mouse as /devices/virtual/misc/uhid/0005:045E:0041.0003/input/input26
[ 2178.127569] input: G7BTS Consumer Control as /devices/virtual/misc/uhid/0005:045E:0041.0003/input/input27
[ 2178.127744] input: G7BTS System Control as /devices/virtual/misc/uhid/0005:045E:0041.0003/input/input28
[ 2178.127906] hid-generic 0005:045E:0041.0003: input,hidraw0: BLUETOOTH HID v3.00 Keyboard [G7BTS] on 3c:77:e6:f3:46:d5
[ 2211.100774] input: G7BTS Keyboard as /devices/virtual/misc/uhid/0005:045E:0041.0004/input/input29
[ 2211.101470] input: G7BTS Mouse as /devices/virtual/misc/uhid/0005:045E:0041.0004/input/input30
[ 2211.101779] input: G7BTS Consumer Control as /devices/virtual/misc/uhid/0005:045E:0041.0004/input/input31
[ 2211.101887] input: G7BTS System Control as /devices/virtual/misc/uhid/0005:045E:0041.0004/input/input32
[ 2211.101998] hid-generic 0005:045E:0041.0004: input,hidraw0: BLUETOOTH HID v3.00 Keyboard [G7BTS] on 3c:77:e6:f3:46:d5
```

## 方法三
使用evtest



# 生成
evdev:input:b<bus_id>v<vendor_id>p<product_id>e<version_id>-<modalias>
evdev:input:b<0005>v<045E>p<0041>e<0300>-<modalias>

``` 
evdev:input:b0005v045Ep0041e0300*
```



# Final
1. G7BTS.hwdb
```
evdev:input:b0005v045Ep0041e0300*
 KEYBOARD_KEY_c0041=enter

```

2. put G7BTS.hwdb to /etc/udev/hwdb.d/


3. update 
sudo udevadm hwdb --update
sudo udevadm trigger --verbose 
sudo udevadm hwdb --test='evdev:input:b0005v045Ep0041e0300*'





################################################################################################################################
# 各种所需要工具
################################################################################################################################
## showkey
showkey command in Linux is used to examine the codes sent by the keyboard. showkey prints to standard output either the scan codes or the key code or the `ascii’ code of each key pressed. In the first two modes, the program runs until 10 seconds have elapsed since the last key press or release event, or until it receives a suitable signal, like SIGTERM, from another process. In `ascii’ mode the program terminates when the user types ^D.

```
sudo showkey -a
sudo showkey -s
sudo showkey -k

```



## 蓝牙工具
bluetoothctl
进入菜单， 输入help查看命令。



## xev
通过运行 "xev" 可以找到对应的 keycode



## 需要evtest命令取得scan code
sudo apt-get install evtest

### 首先记录 KEYBOARD_KEY_，然后再记录设备
1. sudo evtest

```
No device specified, trying to scan all of /dev/input/event*
Available devices:
/dev/input/event0:	Lid Switch
/dev/input/event1:	Sleep Button
/dev/input/event2:	Power Button
/dev/input/event3:	AT Translated Set 2 keyboard
/dev/input/event4:	SynPS/2 Synaptics TouchPad
/dev/input/event5:	TPPS/2 IBM TrackPoint
/dev/input/event6:	ThinkPad Extra Buttons
/dev/input/event7:	Video Bus
/dev/input/event8:	Integrated Camera: Integrated C
/dev/input/event9:	G7BTS Keyboard
/dev/input/event10:	G7BTS Mouse
*** /dev/input/event11:	G7BTS Consumer Control ***
/dev/input/event12:	G7BTS System Control
/dev/input/event13:	HDA Intel PCH Mic
/dev/input/event14:	HDA Intel PCH Dock Mic
/dev/input/event15:	HDA Intel PCH Headphone
/dev/input/event16:	HDA Intel PCH Dock Headphone
/dev/input/event17:	HDA Intel PCH HDMI/DP,pcm=3
/dev/input/event11:	HDA Intel PCH HDMI/DP,pcm=7
/dev/input/event19:	HDA Intel PCH HDMI/DP,pcm=8
Select the device event number [0-19]: ^C

```

2. G7BTS Consumer Control
上面知道是event11

sudo evtest /dev/input/event11

按下"OK"键

```
Event: time 1640238746.775220, type 4 (EV_MSC), code 4 (MSC_SCAN), value c0041
Event: time 1640238746.775220, type 1 (EV_KEY), code 353 (KEY_SELECT), value 0
Event: time 1640238746.775220, -------------- SYN_REPORT ------------
```


3. 接下来记录evdev:input:
上面evtest中，依次试了event9-12，发现OK键在event11时有输出，因此选择event11:
grep "" /sys/class/input/event11/device/id/*

```
/sys/class/input/event11/device/id/bustype:0005
/sys/class/input/event11/device/id/product:0041
/sys/class/input/event11/device/id/vendor:045e
/sys/class/input/event11/device/id/version:0300
```



################################################################################################################################
# 参考
################################################################################################################################
[Linux键盘流-改键手册](https://zhuanlan.zhihu.com/p/40301792)
[How to get special keys to work](https://www.thinkwiki.org/wiki/How_to_get_special_keys_to_work)
[Map scancodes to keycodes](https://wiki.archlinux.org/title/Map_scancodes_to_keycodes)



*** Version 11 of the X protocol only supports single-byte key codes. ***
so key codes above 255 are ignored.


ubuntu用户，平时虚拟机跑Win，外接机械键盘，普通改键都有瑕疵。
+ 桌面X下改键，Console中（Ctrl+Alt+F1）不生效。
+ 主机下改键，虚拟机中Win不生效。
+ 新插入或插拔的外接键盘不生效。
    
Linux系统，每个输入设备（ls -l /dev/input）都有以下的过程:
/keyboard/ → scancode → /input driver/ → keycode → /X server XKB/ → keysym

从底层下手，改变scancode，因此能完美解决以上三个瑕疵。
