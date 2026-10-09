# WeaveGlass 0.3.0 Alpha

iOS 26+ 微信 Liquid Glass 视觉增强插件，Theos rootless Objective-C/Logos 工程。

> **这是独立重建的实验源码，不是 WCGlass 原项目的完整可运行源码、越狱包或真机适配认证。** 当前环境没有 Apple iOS SDK、Xcode、Theos 和 iOS 26 注入设备，尚未完成编译、链接、打包和微信真机回归。

## 本版进度

依据新交接文件 `WCGlass_REBUILD_SPEC.md` 的第 7 节继续开发，新增以下可审查实现：

| 功能 | 状态 | 默认 | 适配限制 |
|---|---|---|---|
| 原生 Liquid Glass 工厂 | 实现 | 系统优先 | UIKit `UIGlassEffect effectWithStyle:`；降低透明度时用实底 |
| 独立配置、颜色与导入导出 | 实现 | 开启 | 只写入 `com.weaveglass.settings`，不更改微信偏好域 |
| 标准 UIKit 底栏玻璃/胶囊 | 实验性宿主适配 | 关闭 | 严格快照与原生按钮恢复；不支持无法识别的微信自绘底栏 |
| 底栏变形选中动画 | 实验性宿主适配 | 关闭 | 弹性位移动画，关闭减少动态效果后才播放；从属胶囊模式 |
| 聊天顶部标题胶囊 | **新增部分宿主接入** | 关闭 | 仅用实际导航标题，宿主已有自定义 titleView 时跳过，不生成真实头像/群人数 |
| 聊天输入区、首页搜索区玻璃化 | 实验性宿主适配 | 关闭 | 仅匹配验证类名和 UIKit 控件；关闭恢复 |
| 候选类名解析与诊断 | **新增** | 自动匹配关闭 | 支持从 MD 提供的多个候选名中匹配，**不调用微信私有选择器** |
| 消息合并卡片 UIView | **新增独立 UI 组件** | 仅演示 | 仅渲染调用方提供的示例数据；未与真实微信消息绑定 |
| 离线水印编辑器 | **增强可用的独立工具** | 手动调用 | 相册选图、拖动、双指缩放、位置重置、4096px 封顶、系统分享 |
| 微信内设置及预览、键浏览器 | 实现 | 常驻入口 | 长按标准底栏 0.85 秒或窗口三指连点三次 |

**不能认定已经完成：** 聊天多头像/群人数读取、合并真实微信消息、流光通话、全局字体替换、微信相册布局、会话主页重排、完整搜索胶囊、钱包与消息行为增强。这些需要版本化的宿主结构/接口签名和设备验证。没有用占位通知冒充实际业务逻辑。

## 两份交接资料的使用方式

- `reference/`：原 `handoff.zip` 的类索引与 1,067 个配置键（291 份逆向头文件不提交到 GitHub）。
- 原始 `WCGlass_REBUILD_SPEC.md`：仅保存在用户私有资料中，不公开提交；其实现作为参考，公开仓库仅保留非实现性的配置键对照。
- `reference/rebuild-spec/Sources/Core/WGKeys.h`：交接文档中的配置键清单（**不参与编译**）。
- `docs/03-key-compatibility.md`：旧新两个键集合的对照，交集为 1,048。
- `docs/03-module-coverage.md`：新交接文档第 7 节的逐项完成度与真机验收清单。

原 MD 中 `WGConfig` 与原插件账户模块不直接迁移：部分实现缺失宏、使用了错误的玻璃 style，读写宿主 `standardUserDefaults` 有混入微信数据的风险；现有 WeaveGlass 继续使用独立偏好域，并且只启用经过明确接线的外观开关。

## 工程结构

```
Tweak.xm                              # 仅 UIViewController / UITabBarController 公开 UIKit 生命周期 Hook
Sources/Core/                        # iOS 26+ 和目标 bundle 判断，配置与候选类解析
Sources/Appearance/                  # 原生玻璃、标题胶囊、合并卡片、胶囊底栏、外观样式器
Sources/Integration/                 # 手势开启设置页
Sources/Settings/                    # 可选模块开关、类名诊断、静态预览、配置浏览
Sources/Utilities/                   # 离线水印图层编辑器
reference/                            # 原交接/新 MD 参考材料（不编译）
tests/                                # 静态一致性测试
```

## 编译、测试与调试

在 macOS 安装 Xcode（iOS 26+ SDK）和 Theos，采用兼容的 rootless 注入方案，并确保微信进程 bundle 为 `com.tencent.xin`。

```bash
cd WeaveGlass
python3 -m unittest discover -s tests -v
export THEOS="$HOME/theos"
make clean package FINALPACKAGE=1
# 成功后才会在 packages/ 里生成 deb。请先在测试设备独立验证。
```

`control` 使用独立包 ID `com.weaveglass.tweak`，`WeaveGlass.plist` 只筛选 `com.tencent.xin`，`Makefile` 设定 iOS 26 最低版本和 arm64 rootless。**iOS 26 是否具有可用注入环境，不由 SDK/本工程保证**。安装前勿与旧 WCGlass 同时启用，并备份微信数据；禁用插件后再排查崩溃。

运行时只有明确匹配页面时才注入界面变更。高级选项默认关闭。要验证类名，在微信中三指连点三次进入设置，打开「微信页面类名诊断」，填入实际控制器类名或明确开启候选识别，再逐项测试。系统 TabBar 保持默认外观通常最安全；自定义胶囊视图可能与微信自绘导航不兼容。

## GitHub Actions 自动构建

`main` 分支提交、Pull Request 和手动触发 `workflow_dispatch` 会启动 `.github/workflows/build.yml`。先运行 Python 静态测试；然后在 GitHub 托管的 `macos-26` 上检查 Xcode 的 iOS 26+ SDK、安装 Theos 并执行 `make clean package FINALPACKAGE=1`。构建成功时，Actions Artifacts 提供 `.deb` 下载。**CI 编译通过仍不代表微信真机适配验证通过**。

仓库为公开仓库；原交接资料中的完整 Markdown 源代码、逆向头文件、接口总表及其他未验证文件不推送到仓库。完整参考资料保留在原始 0.3.0 源码 ZIP 中。首次 Actions 可能因工具链/源码编译错误失败，请在 Actions 日志中查看第一条实际编译错误。

## 测试状态

- 24 项源码结构/接线静态测试通过（`tests/`）。
- 没有 Xcode/iOS SDK 的类型检查结果；没有 Theos 编译或 iOS 26 真机 UI 测试。
- 必测点参见 `docs/03-module-coverage.md`。源码接线不等于可靠真实微信运行支持。

## 使用限制

仅实现非数据侵入式的 UI 与本地图片工具；不修改登录/支付/消息数据库，不读取聊天内容，不迁移原版订阅、授权、用户令牌，不尝试未经校验的方法 Hook。原交接材料可能包含专有信息，如对外开源请先审查分发权限。
