
# ======================================================================================================
# ES100 USB DAC 无声解决
# ======================================================================================================
## 查看这个USB设备的具体信息，这里用到命令lsusb。
lsusb
```
Bus 003 Device 002: ID 0a12:1243 Cambridge Silicon Radio, Ltd EarStudio USB DAC
```

Bus 003，Device为002
lsusb -D /dev/bus/usb/003/002 

sudo lsusb -s 003:002 -v

## 查看当前可用的音频设备可以通过命令
aplay -l 
```
card 0: Intel [HDA Intel], device 0: CX20561 Analog [CX20561 Analog]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
card 0: Intel [HDA Intel], device 1: CX20561 Digital [CX20561 Digital]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
card 1: DAC [EarStudio USB DAC], device 0: USB Audio [USB Audio]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```

## 音频设备的参数
cat /proc/asound/card1/pcm0p/sub0/hw_params  
下面是没有播放的结果:
```
closed
```

下面是正在播放的结果：
```
access: MMAP_INTERLEAVED
format: S16_LE
subformat: STD
channels: 2
rate: 44100 (44100/1)
period_size: 44100
buffer_size: 88200
```


## 查看音频流的当前参数
cat /proc/asound/card1/stream0
下面是没有播放的结果:
```
david@Home-Ubuntu:~$ cat /proc/asound/card1/stream0
EarStudio USB DAC at usb-0000:00:1a.0-1, full speed : USB Audio

Playback:
  Status: Stop
  Interface 1
    Altset 1
    Format: S16_LE
    Channels: 2
    Endpoint: 0x03 (3 OUT) (NONE)
    Rates: 48000, 44100
    Bits: 16
    Channel map: FL FR
```


下面是正在播放的结果：
```
david@Home-Ubuntu:~$ cat /proc/asound/card1/stream0
EarStudio USB DAC at usb-0000:00:1a.0-1, full speed : USB Audio

Playback:
  Status: Running
    Interface = 1
    Altset = 1
    Packet Size = 192
    Momentary freq = 44100 Hz (0x2c.199a)
  Interface 1
    Altset 1
    Format: S16_LE
    Channels: 2
    Endpoint: 0x03 (3 OUT) (NONE)
    Rates: 48000, 44100
    Bits: 16
    Channel map: FL FR
```


## 详细信息
aplay -L 

```
iec958:CARD=DAC,DEV=0
    EarStudio USB DAC, USB Audio
    IEC958 (S/PDIF) Digital Audio Output
dmix:CARD=DAC,DEV=0
    EarStudio USB DAC, USB Audio
    Direct sample mixing device
dsnoop:CARD=DAC,DEV=0
    EarStudio USB DAC, USB Audio
    Direct sample snooping device
hw:CARD=DAC,DEV=0
    EarStudio USB DAC, USB Audio
    Direct hardware device without any conversions
plughw:CARD=DAC,DEV=0
    EarStudio USB DAC, USB Audio
    Hardware device with all software conversions
usbstream:CARD=DAC
    EarStudio USB DAC
    USB Stream Output
```

DAC正常：
alsaplayer -o alsa -d dmix:CARD=DAC,DEV=0 2.mp3 

DAC无声：
alsaplayer -o alsa -d hw:CARD=DAC,DEV=0 2.mp3 
alsaplayer -o alsa -d plughw:CARD=DAC,DEV=0 2.mp3 
alsaplayer -o alsa -d usbstream:CARD=DAC 1.wav 




## 修改配置文件，解决DAC无声
ref: alsa 配置文件asound.conf
[url]https://blog.csdn.net/weixin_41965270/article/details/81272710?utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromMachineLearnPai2%7Edefault-4.control&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromMachineLearnPai2%7Edefault-4.control[/url]

ref: Asoundrc
[url]https://www.alsa-project.org/main/index.php/Asoundrc[/url]


0. alsa.conf 
sudo gedit /usr/share/alsa/alsa.conf 

```
defaults.ctl.card 1
defaults.pcm.card 1
defaults.pcm.device 0

```

1. asound.conf
sudo gedit /etc/asound.conf
```
pcm.!default {
        type hw
        card 1
}

ctl.!default {
        type hw           
        card 1
}

pcm.!default {
        type plug
        slave.pcm "dmixer"
}

pcm.dmixer  {
        type dmix
        ipc_key 1024
        slave {
                pcm "hw:1,0"
                period_time 0
                period_size 1024
                buffer_size 4096
                rate 44100
        }
        bindings {
                0 0
                1 1
        }
}

ctl.dmixer {
        type hw
        card 1
}
```

2. reload
sudo alsa force-reload

3. test
aplay 1.wav



## audacious 配置
配合上面/usr/share/alsa/alsa.conf 
Output-Audio Settings-Audio-Output plugin-"ALSA Output"-Settings
PCM Device-"sysdefault-Default Audio Device"
Mix Device-"default-Default	mixer device"



## 其它解决办法
安装完ubuntu后所用USB接口耳机一直无法放出声音。注意：USB耳机内置声卡显示都很正常。
$ sudo alsamixer
$ sudo alsactl store
按F6选择USB声卡，按左右键选择发声单元，用“<”或者“>”健将其调整为“60”（默认为MM）。

if alsamixer command returns error, it’s probably because you have more than one sound card. 
In that case, you need to specify the sound card number (refer to the inxi output I mentioned in the beginning) like this:

alsamixer -c 1


## 重启alsa
sudo alsa force-reload


## alsaplayer
alsaplayer -o alsa -d hw:0,0 1.wav


## 修复无声
1. reinstalling Alsa and Pulse audio 
sudo apt-get install --reinstall alsa-base pulseaudio
sudo alsa force-reload

2. Try starting Pulseaudio
pulseaudio --start

3. remove old Pulseaudio config
mv ~/.config/pulse ~/.config/old_pulse
reboot your system



# pulseaudio
## Using PulseAudio Volume Control Graphical Utility
sudo apt install pavucontrol




# pulseaudio之pacmd命令
[url]https://blog.csdn.net/u010164190/article/details/105842325[/url]
OSS sink表示输出音源部分,从PulseAudio要转到声音设备的介面.
Sinks are your sound cards
sink-inputs are what applications create when producing sound. 
 
## 如何使用pacmd来选择输出设备
1. 找出有那些sink index
pacmd list-sinks
```
2 sink(s) available.
    index: 1
	name: <alsa_output.pci-0000_00_1b.0.analog-stereo>
	driver: <module-alsa-card.c>
	flags: HARDWARE HW_MUTE_CTRL HW_VOLUME_CTRL DECIBEL_VOLUME LATENCY DYNAMIC_LATENCY
	state: IDLE
	suspend cause: (none)
	priority: 9039
	volume: front-left: 25019 /  38% / -25.09 dB,   front-right: 25019 /  38% / -25.09 dB
	        balance 0.00
	base volume: 65536 / 100% / 0.00 dB
	volume steps: 65537
	muted: no
	current latency: 39.89 ms
	max request: 6 KiB
	max rewind: 6 KiB
	monitor source: 1
	sample spec: s16le 2ch 44100Hz
	channel map: front-left,front-right
	             Stereo
	used by: 0
	linked by: 1
	configured latency: 40.00 ms; range is 0.50 .. 2000.00 ms
	card: 0 <alsa_card.pci-0000_00_1b.0>
	module: 23
	properties:
		alsa.resolution_bits = "16"
		device.api = "alsa"
		device.class = "sound"
		alsa.class = "generic"
		alsa.subclass = "generic-mix"
		alsa.name = "CX20561 Analog"
		alsa.id = "CX20561 Analog"
		alsa.subdevice = "0"
		alsa.subdevice_name = "subdevice #0"
		alsa.device = "0"
		alsa.card = "0"
		alsa.card_name = "HDA Intel"
		alsa.long_card_name = "HDA Intel at 0xf2620000 irq 33"
		alsa.driver_name = "snd_hda_intel"
		device.bus_path = "pci-0000:00:1b.0"
		sysfs.path = "/devices/pci0000:00/0000:00:1b.0/sound/card0"
		device.bus = "pci"
		device.vendor.id = "8086"
		device.vendor.name = "Intel Corporation"
		device.product.id = "293e"
		device.product.name = "82801I (ICH9 Family) HD Audio Controller (ThinkPad T400)"
		device.form_factor = "internal"
		device.string = "front:0"
		device.buffering.buffer_size = "352800"
		device.buffering.fragment_size = "176400"
		device.access_mode = "mmap+timer"
		device.profile.name = "analog-stereo"
		device.profile.description = "Analog Stereo"
		device.description = "Built-in Audio Analog Stereo"
		module-udev-detect.discovered = "1"
		device.icon_name = "audio-card-pci"
	ports:
		analog-output-speaker: Speakers (priority 10000, latency offset 0 usec, available: unknown)
			properties:
				device.icon_name = "audio-speakers"
		analog-output-headphones: Headphones (priority 9900, latency offset 0 usec, available: no)
			properties:
				device.icon_name = "audio-headphones"
	active port: <analog-output-speaker>
  * index: 4
	name: <alsa_output.usb-0a12_EarStudio_USB_DAC_ABCDEF0123456789-00.analog-stereo>
	driver: <module-alsa-card.c>
	flags: HARDWARE HW_MUTE_CTRL HW_VOLUME_CTRL DECIBEL_VOLUME LATENCY DYNAMIC_LATENCY
	state: RUNNING
	suspend cause: (none)
	priority: 9049
	volume: front-left: 18352 /  28% / -33.17 dB,   front-right: 18352 /  28% / -33.17 dB
	        balance 0.00
	base volume: 65536 / 100% / 0.00 dB
	volume steps: 65537
	muted: no
	current latency: 43.36 ms
	max request: 6 KiB
	max rewind: 6 KiB
	monitor source: 5
	sample spec: s16le 2ch 44100Hz
	channel map: front-left,front-right
	             Stereo
	used by: 1
	linked by: 3
	configured latency: 40.00 ms; range is 0.50 .. 2000.00 ms
	card: 1 <alsa_card.usb-0a12_EarStudio_USB_DAC_ABCDEF0123456789-00>
	module: 24
	properties:
		alsa.resolution_bits = "16"
		device.api = "alsa"
		device.class = "sound"
		alsa.class = "generic"
		alsa.subclass = "generic-mix"
		alsa.name = "USB Audio"
		alsa.id = "USB Audio"
		alsa.subdevice = "0"
		alsa.subdevice_name = "subdevice #0"
		alsa.device = "0"
		alsa.card = "1"
		alsa.card_name = "EarStudio USB DAC"
		alsa.long_card_name = "EarStudio USB DAC at usb-0000:00:1a.0-1, full speed"
		alsa.driver_name = "snd_usb_audio"
		device.bus_path = "pci-0000:00:1a.0-usb-0:1:1.0"
		sysfs.path = "/devices/pci0000:00/0000:00:1a.0/usb3/3-1/3-1:1.0/sound/card1"
		udev.id = "usb-0a12_EarStudio_USB_DAC_ABCDEF0123456789-00"
		device.bus = "usb"
		device.vendor.id = "0a12"
		device.vendor.name = "Cambridge Silicon Radio, Ltd"
		device.product.id = "1243"
		device.product.name = "EarStudio USB DAC"
		device.serial = "0a12_EarStudio_USB_DAC_ABCDEF0123456789"
		device.string = "front:1"
		device.buffering.buffer_size = "352800"
		device.buffering.fragment_size = "176400"
		device.access_mode = "mmap+timer"
		device.profile.name = "analog-stereo"
		device.profile.description = "Analog Stereo"
		device.description = "EarStudio USB DAC Analog Stereo"
		module-udev-detect.discovered = "1"
		device.icon_name = "audio-card-usb"
	ports:
		analog-output: Analog Output (priority 9900, latency offset 0 usec, available: unknown)
			properties:
				
	active port: <analog-output>

```

2. 设置默认
pacmd set-default-sink 4
或 pacmd set-default-sink 名字(name)
pacmd set-default-sink alsa_output.usb-0a12_EarStudio_USB_DAC_ABCDEF0123456789-00.analog-stereo




## 查看当前客户
pacmd list-sink-inputs
正在使用声音的客户
```
1 sink input(s) available.
    index: 7
	driver: <protocol-native.c>
	flags: START_CORKED 
	state: RUNNING
	sink: 4 <alsa_output.usb-0a12_EarStudio_USB_DAC_ABCDEF0123456789-00.analog-stereo>
	volume: front-left: 52016 /  79% / -6.02 dB,   front-right: 52016 /  79% / -6.02 dB
	        balance 0.00
	muted: no
	current latency: 77.10 ms
	requested latency: 75.01 ms
	sample spec: float32le 2ch 44100Hz
	channel map: front-left,front-right
	             Stereo
	resample method: copy
	module: 10
	client: 14 <Firefox>
	properties:
		media.name = "蒙古人_天琪数码音频_单曲在线试听_酷我音乐"
		application.name = "Firefox"
		native-protocol.peer = "UNIX socket client"
		native-protocol.version = "33"
		application.process.id = "2236"
		application.process.user = "david"
		application.process.host = "Home-Ubuntu"
		application.process.binary = "firefox"
		application.language = "en_HK.UTF-8"
		window.x11.display = ":0"
		application.process.machine_id = "a8ee4bd444c64e08bb4f514ccdd6cb03"
		application.icon_name = "firefox"
		module-stream-restore.id = "sink-input-by-application-name:Firefox"
```

所有使用声音的客户
pacmd list-clients
