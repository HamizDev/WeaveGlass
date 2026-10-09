#import "WGPreviewController.h"
#import "WGGlassEffect.h"
#import "WGGlassSupport.h"
#import "WGSegmentedDockView.h"
#import "WGChatTitleCapsuleView.h"
#import "WGMessageMergeCardView.h"

@interface WGPreviewController ()
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UILabel *intro;
@property (nonatomic, strong) WGChatTitleCapsuleView *titleCapsule;
@property (nonatomic, strong) WGMessageMergeCardView *mergeCard;
@property (nonatomic, strong) UIView *search;
@property (nonatomic, strong) UIView *incoming;
@property (nonatomic, strong) UIView *outgoing;
@property (nonatomic, strong) UIView *composer;
@property (nonatomic, strong) WGSegmentedDockView *dock;
@property (nonatomic, strong) UITabBarController *demoController;
@end

@implementation WGPreviewController
- (UIView *)glassCardWithText:(NSString *)text align:(NSTextAlignment)align {
    UIView *wrap = [UIView new];
    UIVisualEffectView *glass = [WGGlassEffect newGlassViewClear:NO];
    if (glass) {
        glass.frame = wrap.bounds;
        glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        glass.layer.cornerRadius = 23;
        glass.clipsToBounds = YES;
        [wrap addSubview:glass];
    } else wrap.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    UILabel *label = [UILabel new];
    label.text = text;
    label.textAlignment = align;
    label.textColor = UIColor.labelColor;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.numberOfLines = 0;
    label.frame = CGRectInset(wrap.bounds, 16, 8);
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [wrap addSubview:label];
    wrap.clipsToBounds = YES;
    wrap.layer.cornerRadius = 23;
    return wrap;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"玻璃界面预览";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.scroll = [UIScrollView new];
    self.scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scroll.frame = self.view.bounds;
    [self.view addSubview:self.scroll];
    self.intro = [UILabel new];
    self.intro.text = @"以下是独立演示界面，不修改微信消息或会话数据。";
    self.intro.textColor = UIColor.secondaryLabelColor;
    self.intro.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.intro.numberOfLines = 0;
    [self.scroll addSubview:self.intro];
    self.titleCapsule = [[WGChatTitleCapsuleView alloc] initWithTitle:@"示例联系人"];
    [self.scroll addSubview:self.titleCapsule];
    self.search = [self glassCardWithText:@"⌕  搜索聊天记录" align:NSTextAlignmentLeft];
    self.incoming = [self glassCardWithText:@"今天的天气不错。\n原生材质会随背景动态变化。" align:NSTextAlignmentLeft];
    self.outgoing = [self glassCardWithText:@"璃序 WeaveGlass · iOS 26+" align:NSTextAlignmentRight];
    self.composer = [self glassCardWithText:@"+  输入消息…                 ◉" align:NSTextAlignmentLeft];
    [self.scroll addSubview:self.search];
    [self.scroll addSubview:self.incoming];
    [self.scroll addSubview:self.outgoing];
    [self.scroll addSubview:self.composer];
    self.mergeCard = [[WGMessageMergeCardView alloc] initWithMessages:@[
        @{@"sender":@"演示甲", @"time":@"12:08", @"body":@"这是独立的合并卡片组件。"},
        @{@"sender":@"演示乙", @"time":@"12:09", @"body":@"尚未接入微信消息，不读取聊天记录。"}
    ]];
    [self.scroll addSubview:self.mergeCard];
    self.demoController = [UITabBarController new];
    NSMutableArray *pages = NSMutableArray.array;
    NSArray *titles = @[@"微信", @"通讯录", @"发现", @"我"];
    NSArray *icons = @[@"message.fill",@"person.crop.circle",@"safari",@"person.fill"];
    for (NSUInteger i = 0; i < titles.count; i++) {
        UIViewController *page = [UIViewController new];
        page.tabBarItem = [[UITabBarItem alloc] initWithTitle:titles[i] image:[UIImage systemImageNamed:icons[i]] tag:i];
        [pages addObject:page];
    }
    self.demoController.viewControllers = pages;
    self.demoController.selectedIndex = 0;
    self.dock = [WGSegmentedDockView new];
    self.dock.controller = self.demoController;
    [self.dock reloadFromController];
    [self.scroll addSubview:self.dock];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scroll.frame = self.view.bounds;
    CGFloat width = CGRectGetWidth(self.scroll.bounds);
    CGFloat content = MAX(width - 32, 280);
    self.intro.frame = CGRectMake(18, 16, content, 42);
    self.titleCapsule.frame = CGRectMake((width - 196)/2, 65, 196, 38);
    self.search.frame = CGRectMake(16, 126, content, 52);
    self.incoming.frame = CGRectMake(18, 218, content * 0.76, 94);
    self.outgoing.frame = CGRectMake(width - 18 - content * 0.76, 331, content * 0.76, 58);
    self.composer.frame = CGRectMake(16, 432, content, 52);
    self.dock.frame = CGRectMake(16, 526, content, 55);
    self.mergeCard.frame = CGRectMake(16, 601, content, 158);
    self.scroll.contentSize = CGSizeMake(width, 796);
}
@end
