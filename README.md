# 旧手机视频监控项目 (oldphone-cam-monitor)

把闲置安卓旧手机变成局域网 IP 摄像头，跑在旧 WinServer2012 上，任何电脑 / iPhone / 安卓手机用浏览器实时观看。

```
[旧安卓手机]  IP Webcam App ──RTSP──>  [WinServer2012]  go2rtc ──WebRTC──>  浏览器观看
                                            (可选 ZeroTier, 实现异地观看)
```

**本仓库（git 源码）不含二进制文件**：`go2rtc.exe`、ZeroTier 安装包、`ffmpeg.exe` 请从 **GitHub Releases** 下载，或用 **`download.bat`** 一键自动获取（见「第二步」）。把这些文件放入后，整个文件夹即为完整的「离线部署包」——服务器全程不需要联网下载。视频流也只在局域网内传输，不经过任何第三方云端（若你开启录像上传，录像文件会按你的要求上传到你指定的云盘）。

---

## 需要准备的软件

| 组件 | 软件 | 说明 |
|---|---|---|
| 手机端 | **IP Webcam**（Play Store / 各大应用市场免费下载） | 把手机变成摄像头，输出 RTSP/MJPEG |
| 服务器端 | **go2rtc** v1.9.14（开源，MIT，单 exe） | 聚合/转发视频流，自带网页观看界面；从 Releases / `download.bat` 获取 |
| 远程观看（可选） | **ZeroTier One 1.6.6** | 免费组网，异地也能看（Server 2012 专用版）；同上获取 |
| 录像存云盘（可选） | **FFmpeg**（开源，LGPL/GPL） | 分段录制相机流，配合天翼云盘客户端自动上传回看；同上获取 |

> 如果旧手机是 Android 11+ 且愿意折腾，可用开源 App 替代 IP Webcam（如 AssiCam），配置类似。

---

## 第一步：手机端配置

1. 安装并打开 IP Webcam
2. 底部点 `启动服务器`（会显示一个地址，如 `http://192.168.1.100:8080`）
3. 点右上角齿轮进入设置：
   - `连接检视`：设置 `登录/密码`（务必设置，防盗拉流）
   - `连接检视 → 启用 RTSP`：打开
   - `视频设置 → 分辨率/帧率`：建议 720P / 15fps，避免手机过热
   - `视频设置 → OSD 开关`：可关掉画面上的文字
   - `电源管理`：开启 `Wakelock`，屏幕可关闭
4. 回到主页，页面下方会自动列出可用地址，其中 RTSP 地址类似：
   - `rtsp://user:pass@192.168.1.100:8080/h264_ulaw.sdp`（H.264+音频，推荐）
   - `rtsp://user:pass@192.168.1.100:8080/h264_pcm.sdp`（纯画面）
5. 在**路由器**里给手机**固定内网 IP**（DHCP 静态绑定），保证重启后地址不变。

---

## 第二步：WinServer2012 部署（纯离线）

本仓库不含二进制文件。先在一台**能上外网电脑**上补齐它们（两种方式任选）：

- **方式一（自动）**：进入本目录双击运行 **`download.bat`**，会自动下载 `go2rtc.exe` 到根目录、`vendor\ZeroTier One 1.6.6.msi` 和 `vendor\ffmpeg\ffmpeg.exe` 到 `vendor\`（网络慢时 ffmpeg 约百 MB，稍候）。
- **方式二（手动）**：打开本仓库的 **Releases** 页面，下载里面附带的二进制，解压后放好（`go2rtc.exe` 在根目录；ZeroTier MSI 与 ffmpeg 在 `vendor\` 对应位置）。

补齐后把整个文件夹拷贝到服务器（例如 `D:\cam`），然后：

1. **编辑 `config.yaml`**：把 `phone1` 那行的地址换成你在 IP Webcam 里看到的 RTSP 地址（含用户名密码）。
2. **双击 `start.bat`** 前台运行，先确认能看到画面（`http://127.0.0.1:1984` 本机测试）。

> `download.bat` 以后也可以当**升级工具**用：删除旧 `go2rtc.exe` 再运行它，会从官方下载最新版 go2rtc（仅当你日后想升新版时才需要，且那时需要能访问 github.com 的机器）。

---

## 第三步（推荐）：开机自启 + 后台运行

部署正常后，推荐用脚本装成系统服务：

| 能力 | 实现方式 |
|---|---|
| **开机自启** | Windows 计划任务（`go2rtc-cam`），开机即运行，无需登录 |
| **后台运行** | 以 SYSTEM 账户运行，无窗口、无进程依赖你的登录会话 |
| **重复运行安全** | 每个启动脚本都会先结束已存在的 go2rtc 再启动，重复双击不会报“端口被占用” |

操作：

1. 右键 **`install-autostart.bat`** → **以管理员身份运行**（它会：创建计划任务 → 立即启动 → 打印任务状态）。
2. 以后调整摄像头（改 `config.yaml` 的 RTSP 地址、加相机等），保存后运行一次 **`restart.bat`** 即生效（后台重启，只断 1~2 秒）。

日志位置：`logs\` 目录 —— `go2rtc.log`（go2rtc 全部输出）。查看请双击 **`view-log.bat`**（自动正确换行；可带参数如 `view-log.bat rec.log`），不要用 Server 2012 老记事本——它只认 CRLF 换行，而 go2rtc/ffmpeg 日志用的是 LF，记事本打开会挤成一堆（并非日志损坏）。

- 想停掉并卸载：运行 **`uninstall-autostart.bat`**（停止 go2rtc 并删除计划任务）。
- 只临时测试：用 `start.bat`（手动前台运行，关窗口即停，不装任务，每次启动也会先清理旧进程）。

> 原理说明：`run-hidden.bat` 被计划任务在开机时以 SYSTEM 调用，它在后台启动 go2rtc。四个启动/重启脚本都内建了 `taskkill` 先杀旧进程再启动的步骤，所以**无论怎么重复运行都不会端口冲突**，配置也总能加载到最新。

---

## 第四步：观看

| 位置 | 方法 |
|---|---|
| 局域网内 | 浏览器打开 `http://Win2012的IP:1984`（网页里点相机即看，WebRTC 低延迟约 0.5s；iPhone 用 Safari 直接看） |
| 本机测试 | `http://127.0.0.1:1984` |
| 手持设备 | 无 App，直接用手机浏览器打开上面的地址即可；改用以下 ZeroTier 地址即可异地看 |
| 任何 RTSP 播放器 | VLC：`媒体 → 打开网络串流 → rtsp://服务器IP:8554/phone1`（go2rtc 默认端口） |
| 支持 RTMP 的播放器 | `rtmp://服务器IP:1935/phone1`（如电视端、OBS、部分监控录像机） |

> **关于 RTMP**：go2rtc 默认已开启 RTMP 输出（`rtmp://服务器IP:1935/phone1`）。注意 RTMP 只支持 **H.264 + AAC** 编码：画面一定有；想带声音，需在 IP Webcam 设置里把音频编码改成 **AAC**（否则默认的 G.711 语音 RTMP 客户端收不到）。

---

## 第五步（可选）：异地观看 —— ZeroTier

> **注意**：Tailscale 新版不支持 Windows Server 2012（要求 Server 2016+），所以这里用 **ZeroTier 1.6.6** —— 它是官方为 Win7 / Server 2012 指定的最后一个版本，安装包在离线包里的 `vendor\` 目录（仓库不收录，获取方式见「第二步」）。
>
> 只看局域网不需要装它。老版本组网工具存在安全风险（2018 年产物，不再被官方更新），仅建议在信任的局域网中使用。

1. **服务器**：运行 `vendor\ZeroTier One 1.6.6.msi` 安装（默认全装）。若在**远程桌面**下安装后虚拟网卡没出现，先以管理员身份执行下面的开关（禁用 Windows Installer 的 RDS 兼容协调，ZeroTier 官方 issue #780 提供的解决方案），再重装一次 MSI：
   ```
   reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\TSAppSrv\TSMSI" /v Enable /t REG_DWORD /d 0 /f
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\TSAppSrv\TSMSI" /v Enable /t REG_DWORD /d 0 /f
   ```
2. 手机装 **ZeroTier One** App：iPhone 从 App Store 装「Zerotier One」；安卓从 Play Store 装同名 App。
3. 浏览器打开 **ZeroTier Central 控制台**（`https://central.zerotier.com`）注册账号 → 创建一个网络（Network）→ 记下你的 **16 位网络 ID**。
4. 服务器上右键左下角 ZeroTier 图标 → `Join Network` → 填入网络 ID；手机 App 里同样操作。
5. 回到控制台，把这个网络的 `Managed Routes` 里给手机和服务器各自打勾授权（Auth）。
6. 这样服务器会获得一个 ZeroTier 内网 IP（如 `10.147.17.x`），在**任何地方**用手机浏览器打开 `http://该ZeroTierIP:1984` 即可异地看。你的手机和服务器都登录同一个账号、加入同一个网络即可互相访问。

> 备选方案：如果你在别处的云 Ubuntu 有公网 IP，也可以在云上跑 `frp` 服务端、服务器上跑客户端，用 `http://云IP:端口` 观看，效果类似且无需老版本软件，但需要一定的云服务器配置，属于进阶玩法。

---

## 第六步（可选）：录像存云盘（手机随时回看）

在服务器上把相机流**全天分段录像**，再用**天翼云盘 PC 客户端**的「自动备份」把录像文件夹同步上云，你在手机上用天翼 App 就能回看任意时间的画面（推荐保留 30 天）。

```
IP Webcam →(RTSP)→ ffmpeg → 每5分钟1个mp4 → record\ → 天翼"自动备份" → 云盘(≥30天)
```

### 6.1 先装录像组件

前置：`vendor\ffmpeg\ffmpeg.exe` 已存在（没有就按「第二步」跑一次 `download.bat`）。

右键 **`install-record.bat`** → **以管理员身份运行**。它会：

1. 创建计划任务 **`go2rtc-rec`**（开机运行 + 每 30 分钟复查一次，ffmpeg 挂了会自动拉活）；
2. 立即开始录像，输出到 `record\` 目录（固定每 5 分钟生成一个 mp4，文件名如 `20260922_143500.mp4`）。

录像内容、时长、切片大小都不需要你配——脚本自动从 `config.yaml` 读取 `phone1` 的 RTSP 地址。改地址后保存，等下一次计划任务复查即可生效。

想停止并卸载：运行 **`uninstall-record.bat`**。想确认有没有在录：任务计划程序里看 `go2rtc-rec`，或看 `logs\rec.log`（用 `view-log.bat rec.log`）。

> 运行完 `install-record.bat`，`record\` 目录应**立刻出现**、`logs\rec.log` 应有 `recorder start` 记录；两种都没有说明任务没跑起来，用 `view-log.bat rec.log` 看错误原因。两个安装脚本都会在结尾打印任务的 `Task To Run` 实际值，核对它指向的确实是本项目文件夹里的脚本。

### 6.2 装天翼云盘客户端并开启自动备份

1. 服务器浏览器打开 **`https://cloud.189.cn`** → 下载 **Windows 客户端**（手机上天翼云盘 App 也可）并登录你的天翼账号（会员空间大，至少 450GB 起步，见下方估算）。
2. 客户端设置里找到 **「自动备份」**（不同版本叫「自动备份」/「同步文件」），让我把 `record\` 文件夹**添加为自动备份目录**。
3. 之后每次 ffmpeg 写完一个 mp4，客户端就会把它上传到云端，手机上随时回看。

> Server 2012 若拒绝安装最新客户端：改用其 7.x 旧版安装包，或退而求其次用 `alist`+WebDAV 空间（进阶方案，见常见问题）。自动备份的目录一旦建好，新增 mp4 会自动同步，**删服务器文件不会反向删云端文件**——想腾本地空间时直接删 `record\` 里旧文件即可，云端录像不受影响。

### 6.3 空间与码率估算（决定保留几天）

| 设置 | 约占用/天 | 30 天合计 |
|---|---|---|
| 720P / 15fps 带声音 | 15–30 GB | 450–900 GB |
| 720P / 15fps 纯画面 | 8–16 GB | 240–480 GB |
| 480P / 10fps 纯画面 | 4–8 GB | 120–240 GB |

- 空间不够时优先做两件事：**降分辨率/帧率**（手机端 IP Webcam 设置，也省手机发热）、**只录纯画面**（改 `config.yaml` 里用 `h264_pcm.sdp` 结尾的地址）。
- 本地磁盘也会有 30 天的占用（约等于云端空间），记得服务器硬盘留够，或定期清理 `record\`。

### 6.4 原理（为什么用 FFmpeg 而不是 go2rtc 录像）

go2rtc 官方版（v1.9.14）**不含录像（rec）模块**（需要自己加 ffmpeg 编译，属进阶折腾），所以我们直接让独立的 **ffmpeg** 从 go2rtc 的 RTSP 输出拉流、`-c copy` 不解码直录成 mp4，零转码开销，5 分钟一段正好保证：任何已关闭的 mp4 都能被云盘完整上传（正在写的那一段不会上传，写完才传）。凌晨录像也是同一套，无需任何定时——ffmpeg 挂着就一直在录。

---

## 安全提醒

- **不要在路由器上给 8080 / 1984 / 8554 / 1935 / 8555 做公网端口映射**，远程访问一律走 ZeroTier 内网。
- IP Webcam 一定设置密码。
- 摄像头 App 长期在线会发热，建议：调低分辨率和帧率、拆电池直插电源、保持通风。
- ZeroTier 1.6.6 是给 Server 2012 的兼容版本，仅限你自己信任的网络使用，勿暴露到公网。

---

## 常见问题

- **网页黑屏/打不开**：确认手机 IP、用户名密码、`/h264_ulaw.sdp` 路径是否与 IP Webcam 页面上显示的一致。
- **拖影/发热**：把分辨率降到 720P、帧率降到 15 或 10fps。
- **go2rtc 首次访问**：WebUI 打开后若提示，直接点浏览器访问即可。
- **改配置后如何生效**：运行一次 `restart.bat`（后台重启）或重新运行 `start.bat`（前台）即可，脚本会自动先结束旧进程，不会端口冲突。装过开机自启的，也可以在计划任务里右键 `go2rtc-cam` 选“运行”。
- **录像没在自动生成/ ffmpeg 缺失**：确认 `vendor\ffmpeg\ffmpeg.exe` 存在（跑 `download.bat` 补齐），再以管理员运行 `install-record.bat`；看 `logs\rec.log`（`view-log.bat rec.log`）或 `logs\rec-ffmpeg.log` 排障。
- **重装过任务仍不录像**：先看 `install-record.bat` 结尾打印的 `Task To Run` 是否指向你文件夹里的 `rec-loop.bat`（可能因为拷文件夹移动了位置，重新运行一次安装脚本即可）。
- **记事本打开日志挤成一堆/不换行**：正常现象——Server 2012 老记事本只认 CRLF，go2rtc/ffmpeg 日志用的是 LF。双击 **`view-log.bat`** 查看（可带参数：`view-log.bat rec.log` / `view-log.bat rec-ffmpeg.log`）。
- **录像文件是 0 字节/`rec-ffmpeg.log` 报错**：多数是 RTSP 地址或网络问题，与观看端同源——`config.yaml` 的 `phone1` 必须能被服务器访问（本机测试可用 `http://127.0.0.1:1984` 确认流在线）。
- **Server 2012 装不上天翼客户端**：改走 `alist + WebDAV`（云盘空间转 WebDAV 给服务器上传），属于进阶玩法，需要能在浏览器里登录的天翼 API/第三方工具支持，参考 alist 文档。

---

## 拷贝清单（整个文件夹拷到服务器）

```
oldphone-cam-monitor\
├─ go2rtc.exe              # go2rtc 1.9.14 (win64) —— 从 Releases / download.bat 获取
├─ config.yaml             # 相机配置，部署时改成你手机的 RTSP 地址
├─ start.bat               # 手动前台启动（测试用）
├─ restart.bat             # 【改配置后运行】后台重启 go2rtc，加载最新配置
├─ install-autostart.bat   # 【推荐】一键装开机自启+后台（以管理员运行）
├─ uninstall-autostart.bat # 停止并卸载开机自启
├─ run-hidden.bat          # 计划任务入口（内部用，不用手动点）
├─ install-record.bat      # 【推荐·可选】装录像计划任务（以管理员运行）
├─ uninstall-record.bat    # 停止录像并卸载录像任务
├─ rec-loop.bat            # 录像计划任务入口（内部用，不用手动点）
├─ rec-loop.ps1            # 录像核心逻辑（内部用）
├─ view-log.bat            # 【推荐】查看运行日志（兼容 LF，自动换行；可带参数指定文件）
├─ download.bat            # 【部署前运行】从官方自动补齐全部二进制
├─ README.md               # 本说明
├─ logs\                   # 运行日志（装自启/录像后自动生成）
├─ record\                 # 录像输出目录（每次 ffmpeg 生成 5 分钟 mp4，天翼"自动备份"指向这里）
└─ vendor\
   ├─ ZeroTier One 1.6.6.msi   # 同上获取，Server 2012 专用，异地观看可选
   ├─ ffmpeg\ffmpeg.exe        # 录像用（可选功能），同上获取
   └─ ... (下载解压残留可自行删除)
```

---

## 后续升级（现在不用做）

- 需要**录像 + AI 人形检测**时，把服务迁到云 Ubuntu / 树莓派上跑 **Frigate**（开源 NVR）。手机端、视频地址都不用改，Frigate 会直接拉 go2rtc 转好的流。
- 想接入米家生态联动（如检测到人 → 小爱播报）时，再加 **Home Assistant + MIOT Auto 集成**，把手机摄像头的检测结果联动到米家设备。