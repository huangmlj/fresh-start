# Fresh Start

一个给 macOS 用的“睡前清场”小工具：一键退出正在运行的用户应用，必要时强制结束卡住的应用，然后可选让电脑进入睡眠。

它不会无差别杀掉系统服务。macOS 刚开机时也会运行很多后台服务，真正应该清理的是你打开的 App、菜单栏工具和你明确指定的后台进程。

## 快速开始

下载 `.dmg` 后打开，把 `Fresh Start.app` 拖到 `Applications` 即可。

安装成可双击的 macOS App：

```zsh
./install-app.sh
```

打包成 `.dmg` 安装包：

```zsh
./build-dmg.sh
```

生成位置：

```text
dist/Fresh Start.dmg
```

如果你从 Finder 双击安装脚本，建议双击英文名的 `install.command`。有些 Terminal 配置会把中文路径显示成乱码，但不会影响已经生成的 App。

安装后会生成：

```text
~/Applications/Fresh Start.app
```

安装脚本会把 `assets/AppIcon.png` 打包成 macOS 图标文件 `assets/AppIcon.icns`。

打开后会看到一个表格界面：

- 表格列出当前识别到的正在运行的应用。
- 左侧勾选框代表这个应用在关闭清单里；取消勾选后，它仍会显示在列表中，但不会被一键关闭。
- 表头左侧的勾选框用于全选或取消全选可关闭应用；部分选中时会显示半选状态。
- 在应用行上右键可以添加到“默认不退出”；加入后勾选框会变灰且不可选择。对这类应用再右键，可以移除“默认不退出”。
- 点击 `应用名称`、`状态`、`内存占用`、`PID` 表头可以排序；再次点击同一列会在正序和倒序之间切换。
- 顶部 `+` 可以添加没有自动识别出来的 `.app`。
- 顶部 `-` 会把选中的应用从关闭清单里移除，也就是取消勾选，不会卸载或删除应用。
- 顶部电源图标会一键关闭清单中的应用。
- 顶部电池图标会开启或关闭系统低电量模式；macOS 会弹出管理员授权，因为 `pmset` 修改该设置需要 root 权限。
- 顶部月亮图标会关闭应用后让 Mac 进入睡眠。
- 顶部刷新图标会重新扫描当前运行应用。
- 顶部偏好设置可以选择显示或隐藏系统应用。
- 偏好设置里可以打开“请我喝杯咖啡”二维码。

Finder 会默认保留。Fresh Start 本身也可以加入关闭清单；执行一键关闭时，它会在其它应用都处理完之后最后退出。微信会先正常请求退出，如果还在运行，会用普通 `TERM` 兜底关闭。

## 命令行后备

先看会关闭哪些 App：

```zsh
./bin/reset-mac --dry-run
```

温和清理，只发送退出指令：

```zsh
./bin/reset-mac
```

睡前强力清理：先请求退出，等待 12 秒，仍未退出的 App 会被结束，然后睡眠：

```zsh
./bin/reset-mac --force --sleep
```

## 配置

复制示例配置：

```zsh
mkdir -p ~/.config/reset-mac
cp config/reset-mac.example.zsh ~/.config/reset-mac/config.zsh
```

常用配置项：

```zsh
KEEP_APPS+=("Finder" "Raycast" "1Password")
MENU_BAR_APPS+=("Dropbox" "Google Drive")
EXTRA_PROCESSES+=("node" "adb")
TIMEOUT_SECONDS=12
```

- `KEEP_APPS`：永远保留的 App 名称。
- `KEEP_BUNDLE_IDS`：永远保留的 bundle identifier。内置的一键启动器会默认保留，避免清理时关闭自己。
- `SOFT_TERM_BUNDLE_IDS`：对不响应普通退出的 App，先发 `quit`，短暂等待后再发普通 `TERM`。默认包含微信 `com.tencent.xinWeChat`。
- `MENU_BAR_APPS`：需要额外退出的菜单栏 App。默认不扫菜单栏，避免误杀同步盘、密码管理器等常驻工具。
- `EXTRA_PROCESSES`：需要额外结束的后台进程名。只有在传入 `--kill-extra` 时才会处理。
- `TIMEOUT_SECONDS`：`--force` 模式下，温和退出后等待多久再强制结束。

## 命令选项

```text
--dry-run, -n             只展示将要处理的项目
--force, -f               超时后强制结束仍未退出的 App
--sleep                   清理完成后进入睡眠
--timeout <seconds>       覆盖强制退出等待时间
--soft-term-delay <s>     覆盖普通 TERM 兜底等待时间
--keep <app>              本次运行额外保留某个 App
--keep-bundle-id <id>     本次运行按 bundle identifier 额外保留某个 App
--soft-term-bundle-id <id>
                          本次运行把某个 App 加入普通 TERM 兜底名单
--menu-bar-app <app>      本次运行额外退出某个菜单栏 App
--kill-extra              处理配置里的 EXTRA_PROCESSES
--extra-process <name>    本次运行额外结束某个后台进程，需要配合 --kill-extra
--no-config               不加载 ~/.config/reset-mac/config.zsh
--list                    列出当前可见 App 和已配置项目
--help                    查看帮助
```

## 安全边界

强制结束可能导致未保存内容丢失。建议第一次使用先看界面里的关闭清单，或者运行 `--dry-run`，确认保留名单符合你的习惯。

有些 App 会在退出时弹出保存窗口，这时温和清理会停留在 App 自己的保存提示；强力清理会在超时后结束它。

## 项目概览

- 技术栈：SwiftUI + AppKit + Swift Package Manager。
- 分发方式：本地构建 `.app`，并通过 `build-dmg.sh` 打包为 `.dmg`。
- 主要能力：扫描运行中应用、维护关闭清单、右键设置默认不退出、关闭应用后可睡眠、切换系统低电量模式。
- 安全边界：不会无差别杀系统服务；Finder 默认保留；Fresh Start 自身可关闭，但会排在最后退出。

## 请我喝杯咖啡

如果 Fresh Start 对你有帮助，可以扫码请我喝杯咖啡：

<img src="assets/DonateQRCode.png" width="240" alt="请我喝杯咖啡二维码">
