# Ubuntu 24.04 LTS Autoinstall 使用说明

## 📋 配置文件说明

### autoinstall.yaml 包含的软件包

#### ✅ 已通过 APT 预装的软件（共 100+ 个包）

| 类别 | 软件包 | 说明 |
|------|--------|------|
| **系统工具** | gnome-tweaks, hardinfo, htop | GNOME优化、硬件信息、进程监控 |
| **开发工具** | git, python3-pip, python3-venv | Python 开发环境 |
| **Android** | adb, fastboot | Android 调试工具 |
| **网络** | openvpn, aria2, filezilla, putty | VPN、下载、FTP、SSH客户端 |
| **浏览器** | Firefox (PPA版本) | 替代Snap版本 |
| **多媒体** | VLC, FFmpeg, GIMP | 播放器、编辑器 |
| **图像** | gthumb, XnView MP | 图片管理、查看 |
| **办公** | LibreOffice, GoldenDict | 办公套件、词典 |
| **输入法** | ibus-rime, 五笔, 拼音 | 中文输入法完整支持 |
| **虚拟化** | KVM/QEMU, virt-manager | Virtual Machine Manager |
| **压缩** | 7z, rar, zip 等 | 所有常见压缩格式 |
| **文件系统** | NTFS, exFAT, CIFS | Windows 兼容性 |
| **字体** | 文泉驿微米黑、正黑 | 中文字体支持 |

#### ⏳ 首次启动后自动安装

- **Google Chrome**（通过 user-data 自动下载安装）

#### 🔧 需要手动安装的软件

以下软件需要在系统安装完成后运行配置脚本安装：

1. **Double Commander** - 从源码安装
2. **NextCloud Desktop** - AppImage
3. **tinyMediaManager** - Java应用
4. **BlueMail** - DEB包
5. **VeraCrypt** - DEB包
6. **XnView** - DEB包

---

## 🚀 使用方法

### 方法一：修改 ISO 注入配置

```bash
# 1. 下载 Ubuntu 24.04 ISO
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso

# 2. 挂载 ISO
mkdir -p /mnt/iso
sudo mount -o loop ubuntu-24.04-desktop-amd64.iso /mnt/iso

# 3. 复制内容
mkdir -p ~/ubuntu-custom
sudo cp -rT /mnt/iso ~/ubuntu-custom

# 4. 添加 autoinstall 配置
mkdir -p ~/ubuntu-custom/autoinstall
cp autoinstall.yaml ~/ubuntu-custom/autoinstall/user-data
touch ~/ubuntu-custom/autoinstall/meta-data

# 5. 修改启动配置
sudo nano ~/ubuntu-custom/boot/grub/grub.cfg

# 在 "Try or Install Ubuntu" 后添加:
menuentry "Autoinstall Ubuntu 24.04" {
    set gfxpayload=keep
    linux   /casper/vmlinuz autoinstall ds=nocloud\;s=/cdrom/autoinstall/ ---
    initrd  /casper/initrd
}

# 6. 生成新 ISO
sudo apt install genisoimage
cd ~/ubuntu-custom
sudo genisoimage -o ~/ubuntu-24.04-autoinstall.iso \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -J -R -V "Ubuntu 24.04 Autoinstall" .

# 7. 写入 USB
sudo dd if=~/ubuntu-24.04-autoinstall.iso of=/dev/sdX bs=4M status=progress
```

### 方法二：使用自动化脚本（推荐）

```bash
# 使用项目提供的工具
sudo bash tools/create-bootable-usb.sh
```

---

## ⚙️ 自定义配置

### 1. 修改用户信息

```yaml
identity:
  hostname: Home-X230        # 改为你的主机名
  realname: David            # 改为你的真实姓名
  username: david            # 改为你的用户名
  password: $6$...           # 改为你的密码哈希
```

生成密码哈希：
```bash
# 安装 whois 包（包含 mkpasswd）
sudo apt install whois

# 生成密码哈希
echo '你的密码' | mkpasswd -m sha-512 -s
```

### 2. 配置 WiFi

```yaml
network:
  wifis:
    wlp3s0:
      access-points:
        "你的WiFi名称":
          password: "你的WiFi密码"
```

### 3. 调整分区

```yaml
storage:
  config:
    # 修改 EFI 分区大小
    - type: partition
      size: 1127219200  # 1GB，可以改为 536870912 (512MB)
    
    # 根分区大小
    - type: partition
      size: -1  # -1 表示使用剩余所有空间
```

### 4. 添加/移除软件包

```yaml
packages:
  # 添加新软件
  - 你的软件包名称
  
  # 不想安装的软件，注释掉即可
  # - unwanted-package
```

### 5. 添加 PPA 源

```yaml
apt:
  sources:
    你的源名称:
      source: "ppa:用户名/仓库名"
      # 或者
      source: "deb [arch=amd64] https://... focal main"
      key: |
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        你的GPG密钥
        -----END PGP PUBLIC KEY BLOCK-----
```

---

## 🔍 常见问题

### Q1: 密码哈希怎么生成？

```bash
# Ubuntu/Debian
echo '你的密码' | mkpasswd -m sha-512 -s

# 如果没有 mkpasswd
sudo apt install whois
```

### Q2: 如何测试配置文件？

```bash
# 验证 YAML 语法
python3 -c "import yaml; yaml.safe_load(open('autoinstall.yaml'))"

# 或使用 yamllint
sudo apt install yamllint
yamllint autoinstall.yaml
```

### Q3: 安装卡在某个步骤？

1. 按 `Alt + F2` 切换到日志终端
2. 查看错误信息
3. 按 `Alt + F1` 返回安装界面

### Q4: 网络配置不生效？

检查网卡名称：
```bash
ip link show
```

常见网卡名：
- 有线: `enp0s25`, `eth0`, `eno1`
- 无线: `wlp3s0`, `wlan0`

### Q5: 如何启用虚拟化？

Virtual Machine Manager (KVM) 需要硬件虚拟化支持：

```bash
# 检查 CPU 是否支持虚拟化
egrep -c '(vmx|svm)' /proc/cpuinfo
# 非0表示支持

# 检查内核模块
lsmod | grep kvm

# 启动 libvirt 服务
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# 添加当前用户到 libvirt 组
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# 重新登录生效
```

### Q6: 如何跳过某些软件包？

```yaml
packages:
  # 方法1: 注释掉
  # - unwanted-package
  
  # 方法2: 移除整个类别
  # ==================== 虚拟化 ====================
  # - qemu-kvm
  # - libvirt-daemon-system
```

---

## 📊 安装时间估算

| 阶段 | 时间 | 说明 |
|------|------|------|
| 分区格式化 | 1-2 分钟 | SSD更快 |
| 基础系统 | 3-5 分钟 | 复制系统文件 |
| 软件包安装 | 15-30 分钟 | 取决于网络速度 |
| 配置系统 | 2-3 分钟 | 执行 late-commands |
| 首次启动 | 5-10 分钟 | Chrome下载、Snap清理 |
| **总计** | **25-50 分钟** | |

---

## 🎯 安装后检查清单

### 自动完成的配置

- ✅ Snap 已完全移除
- ✅ Firefox 使用 PPA 版本
- ✅ SSH 服务已启用
- ✅ 防火墙已配置（允许SSH）
- ✅ sudo 无需密码
- ✅ 时区设置为上海
- ✅ Bash 别名已添加
- ✅ 常用目录已创建
- ✅ Git 已配置
- ✅ Google Chrome 已安装

### 需要手动完成

1. **配置输入法**
   ```bash
   # 设置 → 地区和语言 → 管理已安装的语言
   # 确保输入法系统为 IBus
   # 重启后添加 Chinese (Rime)
   ```

2. **运行安装脚本**
   ```bash
   cd ~/ubuntu-install
   bash scripts/main.sh
   ```

3. **安装 GNOME 扩展**
   - 打开 Extension Manager
   - 搜索并安装: Vitals, OpenWeather, 等

4. **配置应用程序**
   - NextCloud: 登录服务器
   - Aria2: 检查服务状态
   - tinyMediaManager: 添加媒体库

---

## 🔐 安全建议

### 安装完成后立即执行

```bash
# 1. 修改用户密码
passwd

# 2. 修改 root 密码
sudo passwd root

# 3. 配置 SSH 密钥登录
ssh-keygen -t ed25519
ssh-copy-id user@host

# 4. 禁用 SSH 密码登录（可选）
sudo nano /etc/ssh/sshd_config
# PasswordAuthentication no
sudo systemctl restart sshd

# 5. 更新系统
sudo apt update && sudo apt upgrade -y
```

---

## 📝 配置文件位置

安装后的重要配置：

```
/etc/apt/preferences.d/nosnap.pref          # 阻止 Snap
/etc/apt/preferences.d/mozilla-firefox      # Firefox 优先级
/etc/sudoers.d/david                        # sudo 配置
/etc/motd                                   # 欢迎消息
/home/david/.bashrc                         # Bash 配置
/home/david/.first_login                    # 首次登录脚本
```

---

## 🆘 故障排除

### 安装失败回滚

1. 重启机器
2. 重新从 USB 启动
3. 选择 "Try Ubuntu"
4. 检查日志: `/var/log/installer/`

### 网络问题

```bash
# 测试网络
ping -c 4 8.8.8.8

# 检查 DNS
nslookup google.com

# 重启网络
sudo systemctl restart NetworkManager
```

### 软件包安装失败

```bash
# 查看详细错误
sudo apt update
sudo apt install -f

# 清理缓存
sudo apt clean
sudo apt autoclean
```

---

## 📚 相关资源

- [官方 Autoinstall 文档](https://ubuntu.com/server/docs/install/autoinstall)
- [Cloud-init 文档](https://cloudinit.readthedocs.io/)
- [项目 GitHub](https://github.com/your-repo)
