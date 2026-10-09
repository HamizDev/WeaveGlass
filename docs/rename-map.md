# WCGlass → WeaveGlass 映射（不是等价的二进制重命名）

| 来源 | 新工程路径 | 状态 |
|---|---|---|
| `WCGlass` v3.5.2 元数据 | `reference/SPEC_PROJECT.md` | 原样保存作为参考 |
| `CONFIG_KEYS.md` 1,067 keys | `Sources/Core/WGConfigCatalog.m` | 编译时目录 + 可搜索/编辑，旧功能未接线 |
| 微信 TabBar 分段/形态 | `Sources/Appearance/WGSegmentedDockView.*` | 从头开发的 UIKit 版本，未恢复原算法 |
| 系统玻璃背景 | `Sources/Appearance/WGGlassEffect.*` | 使用 `UIGlassEffect`，非原二进制实现 |
| 主题/页面输入栏/搜索栏 | `Sources/Appearance/WGHostAppearanceStyler.*` | 严格类名匹配、关闭可还原 |
| 备份/设置中心 | `Sources/Settings/WGSettingsController.*` | 新实现，不复用原授权 |
| 截图水印 | `Sources/Utilities/WGWatermarkController.*` | 新的独立文字水印工具，少于原编辑器功能 |
| 原账户、云授权、AI/支付/反撤回 | 无 | 不接入 |
