# Ubuntu 24.04.3 LTS 完整安装指南

## 📋 安装前准备

### 1. 备份重要数据

在重装系统前，确保执行以下备份：

```bash
# 挂载数据分区
sudo mount /dev/sdX /media/david/Data  # 替换 sdX 为实际的数据分区

# 备份配置文件
cd /path/to/installUbuntu
bash config/backup.sh

# 备份 programs 目录
cp -r ~/programs /media/david/Data/backup_programs_$(date +%Y%m%d)
```

### 2. 准备安装介质

1. 下载 Ubuntu 24.04.3 LTS ISO
2. 制作启动U盘：
   ```bash
   # 查看U盘设备名
   sudo dmesg | grep sd
   
   # 写入ISO（假设U盘是 /dev/sdc）
   sudo dd if=ubuntu-24.04.3-desktop-amd64.iso of=/dev/sdc bs=4M status=progress
   ```

---

## 🚀 系统安装步骤

### 步骤 1: 安装 Ubuntu 24.04.3 LTS

1. 插入U盘启动，选择"Try or Install Ubuntu"
2. 选择**最小安装**（Minimal Installation）
3. 分区方案：
   - `/` (root): 建议 50GB+
   - `/home`: 剩余空间
   - 保留 `/media/david/Data` 分区（不要格式化）
4. 创建用户：`david`
5. 安装完成后**不要拔U盘**，先重启
6. 根据提示拔下U盘

### 步骤 2: 首次启动配置

- 跳过 Live Patch 设置
- 不发送系统信息
- 不启动位置服务

---

## 🔧 自动化配置脚本

### 安装顺序

将所有脚本保存到 `/media/david/Data/ubuntu_install/` 目录：

```bash
# 1. 系统基础设置
bash install_0_setup.sh

# 2. 从备份恢复配置
bash config/restore.sh

# 3. 安装 apt 软件包
bash install_2_apt.sh

# 4. 安装 deb 包
bash install_3_deb.sh

# 5. 安装 Firefox（PPA版本）
bash install_4_firefox.sh

# 6. 配置 programs 目录
bash install_5_folder.sh

# 7. 安装中文输入法
bash install_6_rime.sh

# 8. 安装 Double Commander
bash install_1_dbcommander.sh
```

---

## 📦 主要安装内容

### 系统软件
- ✅ 移除 Snap，使用 apt
- ✅ GNOME 调整工具
- ✅ Firefox（PPA版本）
- ✅ Google Chrome
- ✅ 中文输入法（ibus-rime 五笔）

### 开发工具
- ✅ ADB/Fastboot
- ✅ curl, git
- ✅ Python3-pip
- ✅ build-essential

### 网络工具
- ✅ OpenVPN
- ✅ net-tools
- ✅ aria2（下载工具）

### 日常应用
- ✅ BlueMail（邮件客户端）
- ✅ VLC（媒体播放器）
- ✅ GIMP（图像编辑）
- ✅ LibreOffice
- ✅ GoldenDict（词典）
- ✅ FileZilla（FTP客户端）
- ✅ PuTTY（SSH客户端）

### programs 目录应用
- ✅ Double Commander（文件管理器）
- ✅ NextCloud（云同步）
- ✅ aria2（后台下载）
- ✅ OpenVPN 配置

### 虚拟化
- ✅ VirtualBox 7.0
- ✅ VeraCrypt（加密）

---

## ⚙️ 手动配置项

### 1. Root 密码设置
```bash
sudo passwd root
# 输入密码：8pSZ8wSj
```

### 2. 中文输入法配置

安装后需要手动配置：

1. 打开 **Settings → Region & Language → Manage Installed Languages**
2. 确保 **Keyboard Input method system** 选择 **IBus**
3. 点击 **Install / Remove Languages**，勾选 **Chinese (Simplified)**
4. 重启系统
5. 打开 **Settings → Keyboard → Input Sources**
6. 点击 "+" 添加：**Chinese (China) → Chinese (Rime)**
7. 使用 `Ctrl + Space` 切换输入法
8. 使用 `Ctrl + ~` 或 `F4` 选择输入方案（五笔拼音）

### 3. GNOME 扩展

安装扩展管理器后，手动安装：
- Vitals（系统监控）
- OpenWeather（天气）
- Screenshot Tool（截图）
- Clipboard Indicator（剪贴板）

### 4. 开机自启动

使用 GNOME Tweaks 添加开机启动：
- NextCloud
- BlueMail
- aria2（已配置为服务）

---

## 🔍 验证安装

```bash
# 检查 Snap 是否完全移除
snap list  # 应该显示 "command not found"

# 检查 aria2 服务
sudo systemctl status aria2c

# 检查安装的软件
dpkg -l | grep -E "chrome|firefox|vlc|gimp"

# 检查 programs 目录
ls -la ~/programs
```

---

## 🐛 常见问题

### 1. G7BTS 遥控器 OK 键不工作

已包含修复脚本，需要手动配置：
```bash
sudo cp doc/keyboard/G7BTS.hwdb /etc/udev/hwdb.d/
sudo udevadm hwdb --update
sudo udevadm trigger --verbose
```

### 2. ES100 USB DAC 无声

参考 `doc/sound/sound.md` 中的配置方法。

### 3. HDMI 外接显示器黑屏

参考 `doc/hdmi/hdmi.md`：
```bash
xrandr --output HDMI-1 --mode 1920x1080
```

---

## 📝 注意事项

1. **数据安全**：安装前务必备份 `/media/david/Data/` 中的重要数据
2. **网络连接**：某些步骤需要稳定的网络连接
3. **执行顺序**：严格按照脚本编号顺序执行
4. **权限问题**：部分脚本需要 sudo 权限
5. **重启时机**：
   - 完成 `install_0_setup.sh` 后建议重启
   - 完成 `install_6_rime.sh` 后必须重启

---

## 📚 相关文档

- [键盘配置](doc/keyboard/keyboard.md)
- [音频配置](doc/sound/sound.md)
- [HDMI配置](doc/hdmi/hdmi.md)
- [系统详细说明](ubuntu.md)

---

## 🎯 安装后优化

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 清理
sudo apt autoremove -y
sudo apt autoclean

# 设置别名
source ~/.bashrc
```

---

**预计总安装时间：60-90分钟**
