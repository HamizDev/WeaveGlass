#import "WGClassInspectorController.h"
#import "WGEnvironment.h"

@interface WGClassInspectorController ()
@property (nonatomic, copy) NSArray<NSString *> *names;
@end

@implementation WGClassInspectorController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"微信页面诊断";
    self.tableView.rowHeight = 58;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新" style:UIBarButtonItemStylePlain target:self action:@selector(reloadSnapshot)];
    [self reloadSnapshot];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadSnapshot];
}
- (void)reloadSnapshot {
    NSMutableArray<NSString *> *classes = NSMutableArray.array;
    UIWindow *window = self.view.window;
    UIViewController *top = window.rootViewController;
    // Exclude our own settings sheet, traverse actual application hierarchy.
    for (NSUInteger i = 0; i < 20 && top; i++) {
        NSString *name = NSStringFromClass(top.class);
        if (name.length) [classes addObject:name];
        UIViewController *next = nil;
        if ([top isKindOfClass:UITabBarController.class]) next = ((UITabBarController *)top).selectedViewController;
        else if ([top isKindOfClass:UINavigationController.class]) next = ((UINavigationController *)top).visibleViewController;
        else if (top.presentedViewController && top.presentedViewController != self.navigationController) next = top.presentedViewController;
        else if (top.childViewControllers.count) next = top.childViewControllers.lastObject;
        if (!next || next == top || next == self || next == self.navigationController) break;
        top = next;
    }
    self.names = classes.copy;
    [self.tableView reloadData];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.names.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return @"前台页面层级（点按复制类名）";
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return @"这里只显示运行时页面类名，不读取聊天内容。可以把确切类名填进“高级外观与宿主适配”。如没有结果，返回后重新进入页面诊断。";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"runtime"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"runtime"];
    cell.textLabel.text = self.names[path.row];
    cell.textLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightMedium];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"第 %ld 层 · 点按复制", (long)path.row + 1];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    UIPasteboard.generalPasteboard.string = self.names[path.row];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"类名已复制");
}
@end
