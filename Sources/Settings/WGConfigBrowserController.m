#import "WGConfigBrowserController.h"
#import "WGConfigCatalog.h"
#import "WGConfiguration.h"

@interface WGConfigBrowserController ()
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *,NSString *> *> *filtered;
@end

@implementation WGConfigBrowserController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"参考配置目录";
    self.tableView.rowHeight = 54;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _filtered = @[];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.searchBar.placeholder = @"搜索 1,067 个原始配置键";
    self.navigationItem.searchController = _searchController;
    self.definesPresentationContext = YES;
}
- (BOOL)isFiltering { return self.searchController.searchBar.text.length > 0; }
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *term = searchController.searchBar.text ?: @"";
    NSMutableArray *results = [NSMutableArray array];
    if (term.length) {
        for (NSString *group in WGConfigCatalog.groupNames) {
            for (NSString *key in [WGConfigCatalog keysForGroup:group]) {
                if ([key localizedCaseInsensitiveContainsString:term] || [group localizedCaseInsensitiveContainsString:term])
                    [results addObject:@{@"group":group,@"key":key}];
            }
        }
    }
    self.filtered = results;
    [self.tableView reloadData];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return [self isFiltering] ? 1 : WGConfigCatalog.groupNames.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    if ([self isFiltering]) return self.filtered.count;
    return [WGConfigCatalog keysForGroup:WGConfigCatalog.groupNames[section]].count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return [self isFiltering] ? @"检索结果 · 未接入原功能" : WGConfigCatalog.groupNames[section];
}
- (NSString *)keyAtIndexPath:(NSIndexPath *)path {
    if ([self isFiltering]) return self.filtered[path.row][@"key"];
    return [WGConfigCatalog keysForGroup:WGConfigCatalog.groupNames[path.section]][path.row];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"config"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"config"];
    NSString *key = [self keyAtIndexPath:path];
    id value = [WGConfiguration.shared valueForKeyName:key];
    cell.textLabel.text = key;
    cell.textLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightMedium];
    cell.textLabel.numberOfLines = 2;
    cell.detailTextLabel.text = value ? [NSString stringWithFormat:@"已保存：%@", value] : @"未配置 · 未实现功能";
    cell.detailTextLabel.numberOfLines = 1;
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessibilityLabel = [NSString stringWithFormat:@"%@，%@",key,cell.detailTextLabel.text];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    NSString *key = [self keyAtIndexPath:path];
    id current = [WGConfiguration.shared valueForKeyName:key];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"编辑参考配置"
                                                                  message:[NSString stringWithFormat:@"%@\n仅保存原键值，不代表原功能已实现。留空会删除该键。输入 JSON 可保存数字、布尔和数组。",key]
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        if ([current isKindOfClass:NSString.class]) field.text = current;
        else if (current) {
            if ([NSJSONSerialization isValidJSONObject:current]) {
                NSData *data = [NSJSONSerialization dataWithJSONObject:current options:NSJSONWritingFragmentsAllowed error:nil];
                field.text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            } else field.text = [current description];
        }
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
        field.accessibilityLabel = key;
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *value = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        id parsed = nil;
        if (value.length) {
            NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
            parsed = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
            if (!parsed || parsed == NSNull.null) parsed = parsed == NSNull.null ? nil : value;
        }
        [WGConfiguration.shared setValue:parsed forKeyName:key];
        [weakSelf.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
