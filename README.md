# 雲端 · 发布产物目录

这个目录存放 **雲端** 打好的安装包与发布清单，**不含源码**。

- 源码工程：`E:\Dee\雲导图软件开发`
- 开发者：BlackTuanzi　出品：雲阁科技工作室

## 目录内容

| 文件 | 说明 |
| --- | --- |
| `雲端-<版本>-便携版.exe` | 单文件免安装，双击即用 |
| `雲端-<版本>-安装版.exe` | 安装向导，可建桌面 / 开始菜单快捷方式 |
| `SHA256SUMS.txt` | 所有安装包的 SHA256（可用 `sha256sum -c` 校验） |
| `releases.json` | 结构化版本清单：版本号 / 构建时间 / 文件大小 / 校验和 |
| `electron-v*/` | Electron 运行时（按需解包用，**不纳入版本控制**） |

> 安装包本身被 `.gitignore` 排除：单个 105–116 MB，纳入 Git 会让仓库随每版膨胀约 220 MB，
> 且超过 GitHub 单文件 100 MB 限制。仓库只版本化**清单**，二进制留在本地目录。

## 校验安装包

```powershell
cd E:\Dee\软件
Get-FileHash *.exe -Algorithm SHA256 | Format-Table Hash, Path
```

与 `SHA256SUMS.txt` 中对应行比对即可（`releases.json` 里也有一份同样的小写十六进制值）。

## 发版流程

1. 在源码工程里改 `package.json` 的 `version`
2. 执行构建：

```powershell
cd E:\Dee\雲导图软件开发
$env:ELECTRON_MIRROR='https://npmmirror.com/mirrors/electron/'
$env:ELECTRON_BUILDER_BINARIES_MIRROR='https://npmmirror.com/mirrors/electron-builder-binaries/'
$env:CSC_IDENTITY_AUTO_DISCOVERY='false'
.\node_modules\.bin\electron-builder.cmd --win --x64
```

3. 把 `dist\*.exe` 复制到本目录
4. 重新生成清单并提交：

```powershell
cd E:\Dee\软件
node tools/update-manifest.js
git add -A
git commit -m "release: 雲端 <版本>"
```

## 说明

- 本目录的 Git 仓库只跟踪：`README.md`、`.gitignore`、`SHA256SUMS.txt`、`releases.json`、`tools/`
- 没有代码签名证书，首次运行会出现 SmartScreen 提示，属预期
- 应用数据存放在 `%APPDATA%\雲端`，卸载 / 替换安装包不会丢失
