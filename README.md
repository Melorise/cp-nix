# Nix 打包说明

本目录把锁定版本的上游桌面项目从源码构建为 Linux Nix Flake，不复用上游预制安装包。界面代码、原生 Node 模块和最终 ASAR 均在 Nix 构建中生成；共享 Electron、稳定运行组件及部分随包资源来自 nixpkgs 或 Flake inputs。版本和来源由 `flake.lock`、pnpm 锁文件及 Cargo 锁文件记录。

## 补丁说明

补丁按 `nix/unwrapped.nix` 中的顺序应用。

### 标识调整

上游构建配置中的可执行文件名、桌面项和图标标识与本地包名不同。补丁统一这些标识，避免生成物保留不匹配的窗口类、图标名和可执行文件元数据。

### 禁用内置更新

Nix store 只读，运行中的程序不能可靠替换自身或随包运行组件；绕过 Flake 锁定下载更新还会产生版本混用。补丁因此在 Linux 上跳过应用更新检查，并拒绝运行组件的内置升级请求，更新统一通过重新构建 Flake 完成。

### 固定稳定运行组件

当前打包只提供 nixpkgs 中的稳定版本，没有随包放入其他发布通道的文件。补丁让 Linux 路径解析始终选择已提供的稳定文件，防止旧配置或界面状态指向不存在的替代文件。

### NixOS 权限包装

上游会检查 setuid 所有权，并尝试通过 `pkexec` 对程序文件执行 `chown` 和 `chmod`；这些操作不适用于只读 Nix store。NixOS 模块改为在 `/run/wrappers` 创建 capability 包装器。Linux 上只要包装器存在，运行组件便始终通过它启动，因为界面可能在进程启动后才动态切换需要额外权限的配置；仅在启动时按当前配置选择路径会留下一个无 capability 的常驻进程。包装器不存在时，补丁给出明确错误，而不尝试修改 store。

### 共享 Electron 兼容

Nix 启动器使用共享 Electron，并把 `app.asar` 作为参数传入。此方式下 Electron 将进程视为 default app，`app.isPackaged` 为 `false`；而工具库把 `is.dev` 定义为 `!app.isPackaged`。若直接沿用该判断，正式构建会误走开发分支，自动打开 DevTools、选择开发资源目录，并影响静默启动和窗口页面加载。

补丁把“工具库判断为开发环境且应用路径不是 ASAR”作为实际开发状态。另一个差异是共享 Electron 的 `process.resourcesPath` 指向 Electron 自身的 store 路径，而不是应用资源目录；补丁改从 `app.getAppPath()` 所指 ASAR 的父目录定位随包文件和原生模块。主窗口、悬浮窗口、资源复制和原生模块加载共用这一约定，删除其中任一处修改都可能重新造成路径不一致。

## NixOS 模块

模块负责安装软件包和创建上述权限包装器，并提供可选的图形会话自启动及额外 Electron 参数。它不创建常驻系统服务。

默认构建：

```sh
nix build
```
## Cachix配置
地址：https://melorise-cp-nix.cachix.org   
公钥：melorise-cp-nix.cachix.org-1:GNg96VizkktTdGMrvl6+PLPHY3jPce4a72HqP2cj4S4=
