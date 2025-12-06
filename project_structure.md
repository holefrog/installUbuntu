# Ubuntu 24.04 LTS 自动化安装项目 - 重构后结构

```
ubuntu-install/
│
├── README.md
├── .gitignore                    # 🔒 排除敏感文件
│
├── autoinstall/
│   ├── autoinstall.yaml
│   ├── meta-data
│   └── README.md
│
├── config/
│   ├── backup.sh
│   ├── restore.sh
│   ├── backup.ini
│   ├── secrets.env.example       # ✨ 新增：环境变量模板
│   └── settings.ini
│
├── data/                          # 📁 所有文件改为模板
│   ├── aria2/
│   │   ├── aria2.conf.template   # ✨ 模板化
│   │   ├── aria2.session
│   │   └── dht.dat
│   │
│   ├── nextcloud/
│   │   └── nextcloud.desktop.template
│   │
│   ├── openvpn/
│   │   ├── AC3100.ovpn.template  # ✨ 模板化
│   │   └── ac3100.desktop.template
│   │
│   ├── rime-data/
│   │   └── (保持不变)
│   │
│   └── tinymediamanager/
│       └── tmm.desktop.template
│
├── scripts/
│   ├── main.sh
│   ├── common.sh                  # ✨ 增强模板引擎
│   ├── config.ini
│   │
│   ├── modules/
│   │   ├── 00_prepare.sh
│   │   ├── 01_base_system.sh
│   │   ├── 02_remove_snap.sh
│   │   ├── 03_apt_packages.sh
│   │   ├── 04_deb_packages.sh
│   │   ├── 05_firefox.sh
│   │   ├── 06_doublecmd.sh
│   │   ├── 07_nextcloud.sh
│   │   ├── 08_tinymediamanager.sh
│   │   ├── 09_aria2.sh            # ✨ 重构：使用模板
│   │   ├── 10_openvpn.sh          # ✨ 重构：使用模板
│   │   └── 11_rime.sh
│   │
│   └── templates/
│       ├── nosnap.pref
│       ├── mozilla-firefox.pref
│       ├── aria2c.service.template # ✨ 新增
│       └── desktop-files/
│           ├── doublecmd.desktop.template
│           ├── nextcloud.desktop.template
│           ├── openvpn.desktop.template
│           └── tmm.desktop.template
│
├── tools/
│   ├── create-bootable-usb.sh
│   ├── verify-installation.sh
│   ├── setup-personal-config.sh   # ✨ 改进
│   └── backup-personal-config.sh
│
├── docs/
│   └── (保持不变)
│
└── logs/
    └── (运行时创建)
```

---

## 🔑 关键变更

### 1. 敏感文件处理
```
真实文件（不提交）           模板文件（提交）
├── aria2.conf       →      aria2.conf.template
├── AC3100.ovpn      →      AC3100.ovpn.template
└── secrets.env      →      secrets.env.example
```

### 2. 模板占位符统一
所有模板使用 `@@VARIABLE@@` 格式：

```ini
# aria2.conf.template
rpc-secret=@@ARIA2_RPC_SECRET@@
http-passwd=@@ARIA2_WEBDAV_PASSWORD@@
dir=@@ARIA2_DOWNLOAD_DIR@@
log=@@ARIA2_CONFIG_DIR@@/aria2.log
```

```
# AC3100.ovpn.template
remote @@OPENVPN_SERVER@@ @@OPENVPN_PORT@@
<ca>
@@OPENVPN_CA_CERT@@
</ca>
```

### 3. 环境变量加载顺序
```
1. config.ini (默认值)
2. secrets.env (敏感信息覆盖)
3. 运行时参数 (最高优先级)
```

---

## 📝 使用流程

### 首次部署
```bash
# 1. 克隆项目
git clone https://github.com/your-repo/ubuntu-install.git
cd ubuntu-install

# 2. 创建个人配置
cp config/secrets.env.example config/secrets.env
nano config/secrets.env  # 填写敏感信息

# 3. (可选) 从备份恢复真实配置
bash tools/setup-personal-config.sh

# 4. 运行安装
bash scripts/main.sh
```

### 备份个人配置
```bash
# 备份到安全位置（不提交到 Git）
bash tools/backup-personal-config.sh
```

---

## 🔒 .gitignore 规则

```gitignore
# 敏感配置文件（真实版本）
config/secrets.env
data/aria2/aria2.conf
data/openvpn/*.ovpn
!data/openvpn/*.ovpn.template

# 私有备份
local_backup/
*_backup/
*.bak

# SSH 密钥
rpi_keys/*
*.pem
*.key
data/ssh/*

# 日志
*.log
logs/

# 临时文件
*.tmp
.cache/
```

---

## ✅ 安全检查清单

- [ ] 所有 `.template` 文件不包含真实密码
- [ ] `secrets.env.example` 只包含占位符
- [ ] `.gitignore` 正确排除敏感文件
- [ ] Git 历史中无敏感信息泄露
- [ ] 模板引擎正确处理特殊字符
- [ ] 错误时不泄露配置内容
