# Ubuntu 24.04 LTS 最终软件包清单

## 📋 通过 Autoinstall 自动安装（约50个）

### 系统工具 (7个)
- gnome-tweaks
- gnome-shell-extension-manager
- dconf-editor
- hardinfo
- htop
- tree
- bleachbit

### 网络工具 (9个)
- curl
- wget
- net-tools
- openssh-server
- openvpn
- network-manager-openvpn-gnome
- aria2
- filezilla
- putty

### 开发工具 (4个)
- git
- python3
- python3-pip
- python3-venv

### Android 工具 (2个)
- adb
- fastboot

### 浏览器 (2个)
- firefox (PPA版本)
- google-chrome (首次启动自动安装)

### 多媒体 (7个)
- vlc
- vlc-plugin-access-extra
- vlc-plugin-notify
- vlc-plugin-samba
- ffmpeg
- gimp
- gimp-data-extras

### 图像查看 (1个)
- gthumb

### 办公软件 (2个)
- libreoffice
- goldendict

### 输入法 (4个)
- ibus
- ibus-rime
- librime-data-wubi
- librime-data-pinyin-simp

### 虚拟化 (9个)
- qemu-kvm
- libvirt-daemon-system
- libvirt-daemon
- libvirt-clients
- bridge-utils
- virt-manager
- virt-viewer
- ovmf
- qemu-utils

### 压缩工具 (9个)
- p7zip-full
- p7zip-rar
- unrar
- libunrar5
- unzip
- zip
- gzip
- bzip2
- xz-utils

### 文件系统支持 (4个)
- exfat-futils
- exfatprogs
- ntfs-3g
- cifs-utils

### 字体 (4个)
- fonts-liberation
- fonts-dejavu
- fonts-wqy-microhei
- fonts-wqy-zenhei

### 终端工具 (3个)
- vim
- tmux
- rsync

### 系统监控 (3个)
- iotop
- nethogs
- sysstat

---

## 🔧 通过安装脚本手动安装（6个）

1. **Double Commander 1.1.18**
   - 双窗口文件管理器
   - 源码安装（tar.xz）

2. **NextCloud Desktop 3.14.2**
   - 云存储同步客户端
   - AppImage

3. **tinyMediaManager 5.0.11**
   - 媒体库管理工具
   - 需要 Java（自动安装 OpenJDK 21）

4. **BlueMail**
   - 邮件客户端
   - DEB 包

5. **VeraCrypt 1.26.15**
   - 磁盘加密工具
   - DEB 包

6. **XnView MP**
   - 图像查看器
   - DEB 包

---

## 📊 统计汇总

| 类别 | 数量 |
|------|------|
| Autoinstall 自动安装 | ~50个 |
| 手动安装（脚本） | 6个 |
| **总计** | **56个** |

| 阶段 | 时间 |
|------|------|
| Autoinstall 安装 | 15-20分钟 |
| 手动脚本安装 | 10-15分钟 |
| **总计** | **25-35分钟** |

---

## ✅ 设计原则

1. **只包含明确指定的软件**
   - 不自动添加额外软件包
   - Ubuntu 自带的不列出

2. **精简高效**
   - 移除所有冗余软件
   - 保留核心功能

3. **功能替代**
   - VirtualBox → KVM/QEMU
   - imagemagick → GIMP
   - Samba 服务端 → 仅保留客户端

4. **按需安装**
   - Java 只在 tinyMediaManager 需要时安装
   - 编译工具不预装

---

## 🎯 关键软件说明

### 图像处理
- **编辑**：GIMP（功能强大，替代 imagemagick）
- **管理**：gthumb（GNOME原生）
- **查看**：XnView MP（支持格式最全）

### 虚拟化
- **KVM/QEMU**：内核级虚拟化，性能最佳
- **virt-manager**：图形界面管理工具
- **优势**：无需禁用 Secure Boot，比 VirtualBox 更轻量

### 字体
- **文泉驿微米黑**：中文界面字体
- **文泉驿正黑**：中文文档字体
- **Liberation**：替代 MS 字体
- **DejaVu**：编程字体

### 压缩工具
- **完整支持**：7z, rar, zip, tar, gz, bz2, xz
- **解压 RAR**：libunrar5
- **创建 7z**：p7zip-full

---

## 🚫 明确不安装的软件

- build-essential (编译工具)
- Java (JDK/JRE) - 仅 tinyMediaManager 按需安装
- Cheese (摄像头)
- VirtualBox
- Samba 服务端
- Noto CJK 字体
- imagemagick
- nano (系统自带)
- screen (有 tmux)
- gparted (系统自带)
- eog (系统自带)
- lm-sensors
- psensor
- gnome-disk-utility (系统自带)
- baobab (系统自带)
- seahorse (系统自带)
- deja-dup (系统自带)

---

## 💾 磁盘空间

- **系统 + 软件**：~10 GB
- **建议分区**：≥50 GB（含用户数据）
- **虚拟机存储**：单独考虑

---

## 🔍 验证命令

```bash
# 检查关键软件
dpkg -l | grep -E "firefox|vlc|gimp|virt-manager|ibus-rime"

# 检查 Snap 移除
snap list  # 应显示 "command not found"

# 检查虚拟化
systemctl status libvirtd
virsh --version

# 统计已安装包
dpkg -l | grep "^ii" | wc -l
```
