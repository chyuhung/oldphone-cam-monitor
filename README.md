# 旧手机视频监控项目 (oldphone-cam-monitor)

把闲置安卓旧手机变成局域网 IP 摄像头，跑在旧 WinServer2012 上，任何电脑 / iPhone / 安卓手机用浏览器实时观看。

```
[旧安卓手机]  IP Webcam App ──RTSP──>  [WinServer2012]  go2rtc ──WebRTC──>  浏览器观看
                                            (可选 ZeroTier, 实现异地观看)
```

**本仓库（git 源码）不含二进制文件**：`go2rtc.exe` 和 ZeroTier 安装包请从 **GitHub Releases** 下载，或用 **`download.bat`** 一键自动获取（见「第二步」）。把这两个文件放入后，整个文件夹即为完整的「离线部署包」——服务器全程不需要联网下载。视频流也只在局域网内传输，不经过任何第三方云端。

---

## 需要准备的软件

| 组件 | 软件 | 说明 |
|---|---|---|
| 手机端 | **IP Webcam**（Play Store / 各大应用市场免费下载） | 把手机变成摄像头，输出 RTSP/MJPEG |
| 服务器端 | **go2rtc** v1.9.14（开源，MIT，单 exe） | 聚合/转发视频流，自带网页观看界面；从 Releases / `download.bat` 获取 |
| 远程观看（可选） | **ZeroTier One 1.6.6** | 免费组网，异地也能看（Server 2012 专用版）；同上获取 |

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

本仓库不含两个二进制文件。先在一台**能上外网的电脑**上补齐它们（两种方式任选）：

- **方式一（自动）**：进入本目录双击运行 **`download.bat`**，会自动下载 `go2rtc.exe` 到根目录、`vendor\ZeroTier One 1.6.6.msi` 到 `vendor\`。
- **方式二（手动）**：打开本仓库的 **Releases** 页面，下载二进制压缩包，解压后放好（`go2rtc.exe` 在根目录；`ZeroTier One 1.6.6.msi` 在 `vendor\`）。

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

日志位置：`logs\` 目录 —— `go2rtc.log`（go2rtc 全部输出）。

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
├─ download.bat            # 【部署前运行】从官方自动补齐两个二进制
├─ README.md               # 本说明
├─ logs\                   # 运行日志（安装自启后自动生成）
└─ vendor\
   └─ ZeroTier One 1.6.6.msi   # 同上获取，Server 2012 专用，异地观看可选
```

---

## 后续升级（现在不用做）

- 需要**录像 + AI 人形检测**时，把服务迁到云 Ubuntu / 树莓派上跑 **Frigate**（开源 NVR）。手机端、视频地址都不用改，Frigate 会直接拉 go2rtc 转好的流。
- 想接入米家生态联动（如检测到人 → 小爱播报）时，再加 **Home Assistant + MIOT Auto 集成**，把手机摄像头的检测结果联动到米家设备。