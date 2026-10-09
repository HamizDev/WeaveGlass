#import "WGSettingsController.h"
#import "WGConfigBrowserController.h"
#import "WGConfiguration.h"
#import "WGGlassEffect.h"
#import "WGGlassSupport.h"
#import "WGEnvironment.h"
#import "WGPreviewController.h"
#import "WGWatermarkController.h"
#import "WGClassInspectorController.h"
#import "WGClassResolver.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface WGSettingsController () <UIDocumentPickerDelegate, UIColorPickerViewControllerDelegate>
@end

@implementation WGSettingsController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"WeaveGlass";
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self action:@selector(closePanel)];
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 128)];
    UIVisualEffectView *glass = [WGGlassEffect newGlassViewClear:NO];
    if (glass) {
        glass.frame = CGRectMake(22, 14, 276, 102);
        glass.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        glass.layer.cornerRadius = 24;
        glass.clipsToBounds = YES;
        [header addSubview:glass];
    }
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(28, 34, 264, 40)];
    title.text = @"WEAVEGLASS";
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont systemFontOfSize:25 weight:UIFontWeightSemibold];
    title.textColor = UIColor.labelColor;
    title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:title];
    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(28, 78, 264, 25)];
    subtitle.text = @"iOS 26+ · Native Liquid Glass";
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    subtitle.textColor = UIColor.secondaryLabelColor;
    subtitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:subtitle];
    self.tableView.tableHeaderView = header;
}
- (void)closePanel { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView; return 4; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return section == 0 ? 9 : section == 1 ? 5 : section == 2 ? 3 : 5;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return @[@"视觉模块 · 已接线", @"高级外观与宿主适配", @"交接配置与备份", @"预览与诊断"][section];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if (section == 0) return @"默认使用系统玻璃，新增变形底栏与聊天标题胶囊均默认关闭；可在此独立开启。";
    if (section == 1) return @"默认使用指定类名精确匹配；开启候选类识别后也只检查类名，不调用微信未知选择器。";
    if (section == 2) return @"交接文档中的 1,067 个参考键与新 MD 的 1,050 个键有重合，但并不自动驱动功能；仅保存和导入。";
    return @"未连接真机或微信具体版本，无法保证适配。发生异常可关闭开关或卸载插件。";
}
- (UITableViewCell *)switchCell:(UITableView *)table title:(NSString *)title detail:(NSString *)detail key:(NSString *)key fallback:(BOOL)fallback {
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"switch"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"switch"];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = detail;
    cell.detailTextLabel.numberOfLines = 2;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UISwitch *toggle = [UISwitch new];
    toggle.on = [WGConfiguration.shared boolForKeyName:key defaultValue:fallback];
    toggle.accessibilityLabel = title;
    toggle.accessibilityIdentifier = key;
    [toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    return cell;
}
- (UITableViewCell *)detailCell:(UITableView *)table title:(NSString *)title detail:(NSString *)detail accessory:(BOOL)accessory {
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"detail"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"detail"];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = detail;
    cell.detailTextLabel.numberOfLines = 2;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryView = nil;
    cell.accessoryType = accessory ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    return cell;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    if (path.section == 0) {
        NSArray *titles = @[@"启用 WeaveGlass", @"实验：额外玻璃底栏", @"清透玻璃材质", @"实验：分段胶囊导航",
                            @"实验：变形切换动画", @"实验：聊天标题胶囊", @"聊天输入区玻璃化", @"首页搜索框玻璃化", @"导航栏主题色"];
        NSArray *details = @[@"关闭时恢复已改动的界面", @"系统已自带玻璃时无需开启", @"用于自定义组件", @"标准 UIKit 底栏，2–6 项，未知结构自动跳过",
                             @"带弹性过渡的选中胶囊；同时启用分段底栏", @"仅替换无自定义 titleView 的聊天标题，不伪造头像", @"限定匹配的聊天页面可编辑输入框", @"限定匹配首页的搜索框", @"限定聊天或首页导航栏"];
        NSArray *keys = @[WGPreferenceEnabled, WGPreferenceNativeGlass, WGPreferenceClearGlass, WGPreferenceCapsuleDock,
                          WGPreferenceMorphDock, WGPreferenceChatTitleCapsule, WGPreferenceChatComposer,
                          WGPreferenceHomeSearch, WGPreferenceNavigationTint];
        return [self switchCell:tableView title:titles[path.row] detail:details[path.row] key:keys[path.row] fallback:path.row == 0];
    }
    if (path.section == 1) {
        NSString *chatName = [WGConfiguration.shared valueForKeyName:WGPreferenceChatHostClass];
        NSString *homeName = [WGConfiguration.shared valueForKeyName:WGPreferenceHomeHostClass];
        switch (path.row) {
            case 0: return [self detailCell:tableView title:@"强调色" detail:[WGConfiguration.shared valueForKeyName:WGPreferenceAccentHex] ?: @"系统青色" accessory:YES];
            case 1: return [self detailCell:tableView title:@"聊天页面类名" detail:[chatName isKindOfClass:NSString.class] ? chatName : @"未设置" accessory:YES];
            case 2: return [self detailCell:tableView title:@"首页页面类名" detail:[homeName isKindOfClass:NSString.class] ? homeName : @"未设置" accessory:YES];
            case 3: return [self switchCell:tableView title:@"实验：自动匹配候选页面类" detail:@"从重建 MD 读取候选列表；跳过未知类，不调用微信私有选择器" key:WGPreferenceAutoClassMatch fallback:NO];
            default: return [self detailCell:tableView title:@"重置本版外观" detail:@"恢复 0.3.0 默认开关，不清除原 1,067 配置键" accessory:NO];
        }
    }
    if (path.section == 2) {
        NSArray *titles = @[@"原始配置浏览器", @"导出配置", @"导入配置"];
        NSArray *details = @[@"14 组 · 1,067 项参考键（未接入旧功能）", @"仅导出 com.weaveglass.settings 下的已知键", @"导入本插件导出的 plist，限制 2 MB"];
        return [self detailCell:tableView title:titles[path.row] detail:details[path.row] accessory:YES];
    }
    NSArray *titles = @[@"界面模块预览", @"截图水印工具", @"微信页面类名诊断", @"环境诊断", @"关于与兼容状态"];
    NSArray *details = @[@"预览标题胶囊、合并卡片、底栏与玻璃输入框", @"从相册选图、拖动和捏合文字图层、导出分享", @"查看当前 UIViewController 层级并复制类名", @"查看 Bundle、系统和 UIKit 原生材质可用性", @"查看交付范围和真机测试限制"];
    return [self detailCell:tableView title:titles[path.row] detail:details[path.row] accessory:YES];
}
- (void)toggleChanged:(UISwitch *)toggle {
    [WGConfiguration.shared setValue:@(toggle.on) forKeyName:toggle.accessibilityIdentifier];
}
- (void)editClassForKey:(NSString *)key title:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                  message:@"仅在类名完全匹配时应用。需通过微信真机运行时日志确认正确的 UIViewController 名称。"
           preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = [WGConfiguration.shared valueForKeyName:key] ?: @"";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.placeholder = @"UIViewController 类名";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *value = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (value.length > 100 || !value.length) { [weakSelf showMessage:@"类名必须为 1–100 个字符" title:@"无效输入"]; return; }
        [WGConfiguration.shared setValue:value forKeyName:key];
        [weakSelf.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)selectColor {
    UIColorPickerViewController *picker = [UIColorPickerViewController new];
    picker.delegate = self;
    picker.supportsAlpha = NO;
    picker.selectedColor = WGGlassSupport.accentColor;
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)controller {
    [WGConfiguration.shared setValue:[WGGlassSupport hexFromColor:controller.selectedColor] forKeyName:WGPreferenceAccentHex];
    [self.tableView reloadData];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    if (path.section == 1) {
        if (path.row == 0) [self selectColor];
        if (path.row == 1) [self editClassForKey:WGPreferenceChatHostClass title:@"聊天控制器类名"];
        if (path.row == 2) [self editClassForKey:WGPreferenceHomeHostClass title:@"首页控制器类名"];
        if (path.row == 4) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重置本版外观" message:@"将恢复所有新版外观偏好为默认值；不删除 WCGlass 参考配置键。" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            __weak typeof(self) weakSelf = self;
            [alert addAction:[UIAlertAction actionWithTitle:@"确定重置" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
                [WGConfiguration.shared resetActiveAppearancePreferences];
                [weakSelf.tableView reloadData];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else if (path.section == 2) {
        if (path.row == 0) {
            [self.navigationController pushViewController:[[WGConfigBrowserController alloc] initWithStyle:UITableViewStyleInsetGrouped] animated:YES];
        } else if (path.row == 1) [self exportPreferencesFromTable:tableView indexPath:path];
        else {
            UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypePropertyList] asCopy:YES];
            picker.delegate = self;
            [self presentViewController:picker animated:YES completion:nil];
        }
    } else if (path.section == 3) {
        if (path.row == 0) {
            [self.navigationController pushViewController:[WGPreviewController new] animated:YES];
        } else if (path.row == 1) {
            [self.navigationController pushViewController:[WGWatermarkController new] animated:YES];
        } else if (path.row == 2) {
            [self.navigationController pushViewController:[[WGClassInspectorController alloc] initWithStyle:UITableViewStyleInsetGrouped] animated:YES];
        } else if (path.row == 3) [self showMessage:[NSString stringWithFormat:@"%@\n\n%@", WGEnvironment.diagnosticSummary, WGClassResolver.diagnosticSummary] title:@"环境与候选类诊断"];
        else [self showMessage:@"WeaveGlass 0.3.0 Alpha\niOS 26+ · 微信 Rootless 插件\n根据 WCGlass_REBUILD_SPEC.md 重新实现，未采用原账户或消息处理 Hook。\n已接线：标题胶囊、变形底栏、输入区/搜索样式、水印图层编辑。\n合并卡片目前仅为独立组件和预览。\n未经过 iOS SDK 编译或微信真机验证。" title:@"关于 WeaveGlass"];
    }
}
- (void)exportPreferencesFromTable:(UITableView *)table indexPath:(NSIndexPath *)path {
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:WGConfiguration.shared.exportKnownValues
                                                              format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if (!data) { [self showMessage:error.localizedDescription ?: @"导出失败" title:@"错误"]; return; }
    NSString *file = [NSTemporaryDirectory() stringByAppendingPathComponent:@"WeaveGlass-settings.plist"];
    if (![data writeToFile:file atomically:YES]) { [self showMessage:@"无法写入临时文件" title:@"错误"]; return; }
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:file]] applicationActivities:nil];
    if (share.popoverPresentationController) {
        share.popoverPresentationController.sourceView = table;
        share.popoverPresentationController.sourceRect = [table rectForRowAtIndexPath:path];
    }
    [self presentViewController:share animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    (void)controller;
    NSURL *url = urls.firstObject;
    if (!url) return;
    NSError *error = nil;
    BOOL scoped = [url startAccessingSecurityScopedResource];
    NSNumber *size = nil;
    [url getResourceValue:&size forKey:NSURLFileSizeKey error:&error];
    if (size.unsignedLongLongValue > 2 * 1024 * 1024) {
        if (scoped) [url stopAccessingSecurityScopedResource];
        [self showMessage:@"文件超过 2 MB" title:@"导入失败"];
        return;
    }
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (scoped) [url stopAccessingSecurityScopedResource];
    if (data.length > 2 * 1024 * 1024) { [self showMessage:@"文件超过 2 MB" title:@"导入失败"]; return; }
    id plist = data ? [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error] : nil;
    if ([plist isKindOfClass:NSDictionary.class] && [WGConfiguration.shared importKnownValues:plist error:&error]) {
        [self.tableView reloadData];
        [self showMessage:@"配置已导入；可在上方逐项检查功能开关。" title:@"导入完成"];
    } else [self showMessage:error.localizedDescription ?: @"配置格式不受支持" title:@"导入失败"];
}
- (void)showMessage:(NSString *)message title:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
