# Ubuntu 24.04.3 LTS 快速参考指南

## 📦 安装前准备

### 1. 制作启动U盘
```bash
# 查看U盘设备名
sudo dmesg | grep sd

# 写入ISO（替换sdc为实际设备）
sudo dd if=ubuntu-24.04.3-desktop-amd64.iso of=/dev/sdc bs=4M status=progress
```

### 2. 备份现有配置
```bash
cd /path/to/installUbuntu
bash config/backup.sh

# 备份会保存到 /media/david/Data/ubuntu_backups/
```

---

## 🚀 自动安装（推荐）

```bash
# 将整个项目复制到数据分区
cp -r /path/to/installUubuntu /media/david/Data/

cd /media/david/Data/installUbuntu

# 使脚本可执行
chmod +x *.sh
chmod +x config/*.sh

# 运行主安装脚本
bash master_install.sh
```

主脚本会自动执行所有安装步骤。

---

## 🔧 手动安装

如果需要分步执行：

```bash
# 步骤 1: 基础设置（移除Snap）
bash install_0_setup.sh
# 建议重启

# 步骤 2: 恢复配置
bash config/restore.sh

# 步骤 3: 安装apt软件
bash install_2_apt.sh

# 步骤 4: 安装deb软件
bash install_3_deb.sh

# 步骤 5: 安装Firefox
bash install_4_firefox.sh

# 步骤 6: 配置programs
bash install_5_folder.sh

# 步骤 7: 安装输入法
bash install_6_rime.sh
# 必须重启

# 步骤 8: 安装Double Commander
bash install_1_dbcommander.sh
```

---

## ⚙️ 安装后配置

### 1. Root密码
```bash
sudo passwd root
# 密码: 8pSZ8wSj
```

### 2. 中文输入法（重要）

**必须在重启后配置：**

1. **Settings → Region & Language → Manage Installed Languages**
   - 确保 Keyboard Input method = IBus
   - Install Chinese (Simplified)

2. **重启系统**

3. **Settings → Keyboard → Input Sources**
   - 点击 "+" 添加
   - 选择 Chinese (China) → Chinese (Rime)

4. **使用快捷键**
   - `Ctrl + Space`: 切换输入法
   - `Ctrl + ~` 或 `F4`: 选择输入方案

### 3. 开机自启动

使用 GNOME Tweaks 添加：
- NextCloud
- BlueMail
- aria2（已配置为系统服务）

### 4. GNOME扩展

打开 Extension Manager，搜索安装：
- Vitals
- OpenWeather
- Screenshot Tool
- Clipboard Indicator

---

## 🔍 验证安装

```bash
# 检查Snap是否移除
snap list  # 应该显示 "command not found"

# 检查aria2服务
sudo systemctl status aria2c

# 检查已安装软件
dpkg -l | grep -E "chrome|firefox|vlc|gimp|bluemail"

# 检查programs目录
ls -la ~/programs
```

---

## 📂 文件结构

```
installUbuntu/
├── master_install.sh          # 主安装脚本
├── install_0_setup.sh          # 基础设置
├── install_1_dbcommander.sh    # Double Commander
├── install_2_apt.sh            # APT软件包
├── install_3_deb.sh            # DEB软件包
├── install_4_firefox.sh        # Firefox PPA
├── install_5_folder.sh         # Programs目录
├── install_6_rime.sh           # 中文输入法
├── config/
│   ├── backup.sh               # 备份脚本
│   ├── restore.sh              # 恢复脚本
│   └── config_paths.txt        # 配置路径列表
├── folders/
│   ├── aria2/                  # aria2配置
│   ├── nextcloud/              # NextCloud
│   └── openvpn/                # OpenVPN配置
├── rime-data/                  # 输入法数据
└── doc/                        # 文档
    ├── hdmi/
    ├── keyboard/
    └── sound/
```

---

## 🐛 常见问题

### 1. G7BTS遥控器OK键不工作
```bash
sudo cp doc/keyboard/G7BTS.hwdb /etc/udev/hwdb.d/
sudo udevadm hwdb --update
sudo udevadm trigger --verbose
```

### 2. HDMI外接显示器黑屏
```bash
xrandr --output HDMI-1 --mode 1920x1080
```

### 3. USB DAC无声
参考 `doc/sound/sound.md`

### 4. 恢复失败
```bash
# 手动指定备份目录
BACKUP_DIR=/media/david/Data/ubuntu_backups/2024-12-04_12-00-00
cd config
# 编辑 restore.sh，修改 BACKUP_DIR
```

---

## 📦 主要安装软件

### 系统工具
- GNOME Tweaks
- Extension Manager
- hardinfo

### 网络工具
- OpenVPN
- aria2
- net-tools
- curl

### 开发工具
- git
- ADB/Fastboot
- Python3-pip

### 日常应用
- Firefox (PPA)
- Google Chrome
- BlueMail
- VLC
- GIMP
- LibreOffice
- GoldenDict
- FileZilla
- PuTTY
- XnView
- Double Commander

### 虚拟化
- VirtualBox 7.0
- VeraCrypt

### 输入法
- ibus-rime
- 五笔拼音

---

## 📞 获取帮助

- 详细文档: `ubuntu.md`
- 键盘配置: `doc/keyboard/keyboard.md`
- 音频配置: `doc/sound/sound.md`
- HDMI配置: `doc/hdmi/hdmi.md`

---

## 🎯 快速命令

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 清理系统
sudo apt autoremove -y
sudo apt autoclean

# 重新加载bashrc
source ~/.bashrc

# 检查服务
sudo systemctl status aria2c

# 挂载SMB
# 文件管理器中输入: smb://192.168.2.1
```

---

**预计安装时间: 60-90分钟**
