# WCGlass 配置键兼容性 — 0.3.0

当前项目含两个不同来源的配置清单：

- `reference/CONFIG_KEYS.md`：`handoff.zip` 的 1,067 个旧键，按原 14 类存放，作为可编辑**参考目录**。
- `reference/rebuild-spec/Sources/Core/WGKeys.h`：新交接 MD 中的 1,050 个键常量，仅保留配置键定义在**参考区，不参与编译**。
- 交集 **1,048 个键**。新文档独有两项 `com.wcglass.hot-update-pipeline-did-settle` 和 `com.wclg.content-corners.changed`，更像通知/运行时状态，不直接作为用户配置写入。
- 旧目录独有 19 个键，形态多为动作/内部方法名，不自动激活。

运行设置继续只保存在 `NSUserDefaults(suiteName: "com.weaveglass.settings")` 中。不会迁移、清除或导出微信的 `standardUserDefaults` 或原插件账户/授权状态。参考键只能存储/备份，**不自动驱动尚未实现的业务功能**。

新实现统一使用 `wg_*` 独立键：`wg_chat_title_capsule`、`wg_morph_dock`、`wg_auto_class_match` 等。未来如需把旧偏好映射到新模块，必须逐键核对类型、默认值及退出恢复行为，不能一次性无条件迁移。
