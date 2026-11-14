# 雲端 · 发布产物

**雲端**是一款简约的桌面文档记录软件，集待办、日历、笔记、PRD、流程图、脑图、逻辑图于一体。

- 开发者：BlackTuanzi
- 出品：雲阁科技工作室
- 本仓库：只保存**发布清单**（版本、校验和），不包含源码与安装包本体

## 为什么这里没有 exe

安装包单个 105–116 MB，且超过 GitHub 单文件 100 MB 限制；纳入版本控制会让仓库随每版膨胀约 220 MB。

因此本仓库只版本化**清单**：`SHA256SUMS.txt` 与 `releases.json`，用于记录每个版本发了什么、文件指纹是多少。

## 目录说明

| 文件 | 说明 |
| --- | --- |
| `SHA256SUMS.txt` | 所有安装包的 SHA256，`sha256sum -c` 兼容格式 |
| `releases.json` | 结构化清单：版本号 / 构建时间 / 文件大小 / 校验和 |
| `tools/update-manifest.js` | 扫描安装包并重新生成上面两个文件 |

安装包命名约定：

```
雲端-<版本>-便携版.exe     单文件免安装，双击即用
雲端-<版本>-安装版.exe     安装向导，可建桌面 / 开始菜单快捷方式
```

## 校验安装包

Linux / macOS / Git Bash：

```bash
sha256sum -c SHA256SUMS.txt
```

Windows PowerShell：

```powershell
Get-FileHash *.exe -Algorithm SHA256 | Format-Table Hash, Path
```

与 `SHA256SUMS.txt` 对应行比对即可（`releases.json` 里也是同样的小写十六进制值）。

## 发版流程

1. 在源码工程中更新 `package.json` 的 `version`
2. 执行构建（示例）：

```powershell
$env:ELECTRON_MIRROR='https://npmmirror.com/mirrors/electron/'
$env:ELECTRON_BUILDER_BINARIES_MIRROR='https://npmmirror.com/mirrors/electron-builder-binaries/'
$env:CSC_IDENTITY_AUTO_DISCOVERY='false'
.\node_modules\.bin\electron-builder.cmd --win --x64
```

3. 将构建产物 `dist\*.exe` 复制到本仓库目录
4. 重新生成清单并提交：

```powershell
node tools/update-manifest.js
git add -A
git commit -m "release: <版本>"
git tag v<版本>
git push --follow-tags
```

`update-manifest.js` 是幂等的：安装包没变化时重复执行不会产生任何 diff。

## 说明

- 应用数据存放在 `%APPDATA%\雲端`，替换安装包或重装都不会丢失
- 未使用代码签名证书，首次运行时 Windows SmartScreen 会提示，属预期行为
- 本仓库只跟踪清单与工具，`*.exe`、`*.zip`、`electron-v*/` 均被 `.gitignore` 排除
