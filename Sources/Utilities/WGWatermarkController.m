#import "WGWatermarkController.h"
#import "WGGlassSupport.h"
#import <PhotosUI/PhotosUI.h>
#import <math.h>

static CGFloat WGClamp(CGFloat value, CGFloat low, CGFloat high) {
    return MIN(MAX(value, low), high);
}

@interface WGWatermarkController () <PHPickerViewControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) UIImageView *preview;
@property (nonatomic, strong) UILabel *overlayLabel;
@property (nonatomic, strong) UITextField *watermarkField;
@property (nonatomic, strong) UIButton *selectButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, assign) CGPoint normalizedCenter;
@property (nonatomic, assign) CGFloat watermarkScale;
@end

@implementation WGWatermarkController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"水印图层编辑器";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.normalizedCenter = CGPointMake(0.78, 0.86);
    self.watermarkScale = 1.0;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"重置位置" style:UIBarButtonItemStylePlain
                                                                            target:self action:@selector(resetPlacement)];

    UILabel *description = [UILabel new];
    description.translatesAutoresizingMaskIntoConstraints = NO;
    description.text = @"仅本地处理照片。拖动水印调整位置，双指缩放；导出尺寸限制为 4096 像素。";
    description.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    description.numberOfLines = 0;
    description.textColor = UIColor.secondaryLabelColor;
    [self.view addSubview:description];

    self.preview = [UIImageView new];
    self.preview.translatesAutoresizingMaskIntoConstraints = NO;
    self.preview.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.preview.contentMode = UIViewContentModeScaleAspectFit;
    self.preview.layer.cornerRadius = 18;
    self.preview.clipsToBounds = YES;
    self.preview.userInteractionEnabled = YES;
    self.preview.accessibilityLabel = @"照片及可移动的文字水印预览";
    [self.view addSubview:self.preview];

    self.overlayLabel = [UILabel new];
    self.overlayLabel.text = @"WeaveGlass";
    self.overlayLabel.textAlignment = NSTextAlignmentCenter;
    self.overlayLabel.textColor = UIColor.whiteColor;
    self.overlayLabel.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.58];
    self.overlayLabel.layer.cornerRadius = 10;
    self.overlayLabel.clipsToBounds = YES;
    self.overlayLabel.userInteractionEnabled = YES;
    self.overlayLabel.accessibilityLabel = @"水印位置，拖动或双指捏合调整";
    self.overlayLabel.isAccessibilityElement = YES;
    [self.preview addSubview:self.overlayLabel];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveOverlay:)];
    [self.overlayLabel addGestureRecognizer:pan];
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scaleOverlay:)];
    pinch.delegate = self;
    pan.delegate = self;
    [self.overlayLabel addGestureRecognizer:pinch];

    self.watermarkField = [UITextField new];
    self.watermarkField.translatesAutoresizingMaskIntoConstraints = NO;
    self.watermarkField.placeholder = @"水印文字";
    self.watermarkField.text = @"WeaveGlass";
    self.watermarkField.borderStyle = UITextBorderStyleRoundedRect;
    self.watermarkField.returnKeyType = UIReturnKeyDone;
    self.watermarkField.delegate = self;
    [self.watermarkField addTarget:self action:@selector(updatePreviewOverlay) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.watermarkField];

    self.selectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.selectButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.selectButton setTitle:@"选择照片" forState:UIControlStateNormal];
    [self.selectButton addTarget:self action:@selector(selectPhoto) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.selectButton];

    self.shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.shareButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.shareButton setTitle:@"导出并分享" forState:UIControlStateNormal];
    self.shareButton.enabled = NO;
    [self.shareButton addTarget:self action:@selector(generateAndShare) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.shareButton];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    NSLayoutConstraint *previewHeight = [self.preview.heightAnchor constraintEqualToAnchor:guide.heightAnchor multiplier:0.46];
    previewHeight.priority = UILayoutPriorityDefaultHigh;
    [NSLayoutConstraint activateConstraints:@[
        [description.topAnchor constraintEqualToAnchor:guide.topAnchor constant:14],
        [description.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:20],
        [description.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-20],
        [self.preview.topAnchor constraintEqualToAnchor:description.bottomAnchor constant:12],
        [self.preview.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:20],
        [self.preview.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-20],
        [self.preview.heightAnchor constraintLessThanOrEqualToConstant:410],
        previewHeight,
        [self.watermarkField.topAnchor constraintEqualToAnchor:self.preview.bottomAnchor constant:14],
        [self.watermarkField.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:20],
        [self.watermarkField.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-20],
        [self.watermarkField.heightAnchor constraintEqualToConstant:46],
        [self.selectButton.topAnchor constraintEqualToAnchor:self.watermarkField.bottomAnchor constant:10],
        [self.selectButton.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:20],
        [self.selectButton.widthAnchor constraintEqualToAnchor:guide.widthAnchor multiplier:0.42],
        [self.selectButton.heightAnchor constraintEqualToConstant:46],
        [self.shareButton.topAnchor constraintEqualToAnchor:self.watermarkField.bottomAnchor constant:10],
        [self.shareButton.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-20],
        [self.shareButton.widthAnchor constraintEqualToAnchor:guide.widthAnchor multiplier:0.42],
        [self.shareButton.heightAnchor constraintEqualToConstant:46]
    ]];
}
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; [self updatePreviewOverlay]; }
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [textField resignFirstResponder]; return YES; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    (void)gestureRecognizer; (void)otherGestureRecognizer;
    return YES;
}
- (NSString *)safeWatermarkText {
    NSString *s = [self.watermarkField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!s.length) s = @"WeaveGlass";
    return s.length > 80 ? [s substringToIndex:80] : s;
}
- (CGRect)imageRectInPreview {
    UIImage *source = self.originalImage;
    CGRect box = self.preview.bounds;
    if (!source || CGRectIsEmpty(box) || source.size.width <= 0 || source.size.height <= 0) return CGRectZero;
    CGFloat fit = MIN(CGRectGetWidth(box) / source.size.width, CGRectGetHeight(box) / source.size.height);
    CGSize display = CGSizeMake(source.size.width * fit, source.size.height * fit);
    return CGRectMake(CGRectGetMidX(box) - display.width / 2, CGRectGetMidY(box) - display.height / 2, display.width, display.height);
}
- (void)updatePreviewOverlay {
    CGRect imageRect = [self imageRectInPreview];
    self.overlayLabel.hidden = CGRectIsEmpty(imageRect);
    if (self.overlayLabel.hidden) return;
    NSString *s = [self safeWatermarkText];
    self.overlayLabel.text = s;
    CGFloat fontSize = MAX(10, CGRectGetWidth(imageRect) * 0.036) * self.watermarkScale;
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold];
    self.overlayLabel.font = font;
    CGSize text = [s sizeWithAttributes:@{NSFontAttributeName: font}];
    CGFloat padding = MAX(5, fontSize * 0.45);
    CGFloat width = MIN(text.width + padding * 2, MAX(20, CGRectGetWidth(imageRect) - 6));
    CGFloat height = MIN(text.height + padding * 1.6, MAX(15, CGRectGetHeight(imageRect) - 6));
    self.overlayLabel.bounds = CGRectMake(0, 0, width, height);
    CGFloat cx = CGRectGetMinX(imageRect) + self.normalizedCenter.x * CGRectGetWidth(imageRect);
    CGFloat cy = CGRectGetMinY(imageRect) + self.normalizedCenter.y * CGRectGetHeight(imageRect);
    cx = WGClamp(cx, CGRectGetMinX(imageRect) + width/2, CGRectGetMaxX(imageRect) - width/2);
    cy = WGClamp(cy, CGRectGetMinY(imageRect) + height/2, CGRectGetMaxY(imageRect) - height/2);
    self.overlayLabel.center = CGPointMake(cx, cy);
    self.normalizedCenter = CGPointMake((cx - CGRectGetMinX(imageRect))/CGRectGetWidth(imageRect),
                                        (cy - CGRectGetMinY(imageRect))/CGRectGetHeight(imageRect));
    self.overlayLabel.layer.cornerRadius = height / 3;
}
- (void)moveOverlay:(UIPanGestureRecognizer *)pan {
    CGRect r = [self imageRectInPreview];
    if (CGRectIsEmpty(r)) return;
    CGPoint delta = [pan translationInView:self.preview];
    self.normalizedCenter = CGPointMake(self.normalizedCenter.x + delta.x / r.size.width,
                                        self.normalizedCenter.y + delta.y / r.size.height);
    [pan setTranslation:CGPointZero inView:self.preview];
    [self updatePreviewOverlay];
}
- (void)scaleOverlay:(UIPinchGestureRecognizer *)pinch {
    if (pinch.state == UIGestureRecognizerStateBegan || pinch.state == UIGestureRecognizerStateChanged) {
        self.watermarkScale = WGClamp(self.watermarkScale * pinch.scale, 0.65, 2.6);
        pinch.scale = 1;
        [self updatePreviewOverlay];
    }
}
- (void)resetPlacement {
    self.normalizedCenter = CGPointMake(0.78, 0.86);
    self.watermarkScale = 1.0;
    [self updatePreviewOverlay];
}
- (void)selectPhoto {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1;
    config.filter = PHPickerFilter.imagesFilter;
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSItemProvider *provider = results.firstObject.itemProvider;
    if (!provider || ![provider canLoadObjectOfClass:UIImage.class]) return;
    __weak typeof(self) weakSelf = self;
    [provider loadObjectOfClass:UIImage.class completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
        UIImage *image = [object isKindOfClass:UIImage.class] ? (UIImage *)object : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf) return;
            if (!image) { [weakSelf alert:error.localizedDescription ?: @"无法读取图片"]; return; }
            weakSelf.originalImage = image;
            weakSelf.preview.image = image;
            weakSelf.shareButton.enabled = YES;
            [weakSelf resetPlacement];
        });
    }];
}
- (nullable UIImage *)renderWatermark {
    UIImage *source = self.originalImage;
    if (!source || source.size.width <= 0 || source.size.height <= 0) return nil;
    // Account for UIImage.scale when bounding decoded pixels inside the host process.
    CGFloat widthPx = source.size.width * source.scale;
    CGFloat heightPx = source.size.height * source.scale;
    CGFloat ratio = MIN(1.0, 4096.0 / MAX(widthPx, heightPx));
    CGSize size = CGSizeMake(MAX(1, floor(widthPx * ratio)), MAX(1, floor(heightPx * ratio)));
    if (size.width < 64 || size.height < 64) return nil;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1;
    format.opaque = NO;
    NSString *text = [self safeWatermarkText];
    CGFloat fontSize = MAX(10, size.width * 0.036) * self.watermarkScale;
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold];
    NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.whiteColor};
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGFloat pad = MAX(5, fontSize * 0.45);
    CGFloat width = MIN(textSize.width + pad * 2, MAX(20, size.width - 6));
    CGFloat height = MIN(textSize.height + pad * 1.6, MAX(15, size.height - 6));
    CGFloat cx = WGClamp(self.normalizedCenter.x * size.width, width/2, size.width - width/2);
    CGFloat cy = WGClamp(self.normalizedCenter.y * size.height, height/2, size.height - height/2);
    CGRect box = CGRectMake(cx-width/2, cy-height/2, width, height);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(__unused UIGraphicsImageRendererContext *context) {
        [source drawInRect:CGRectMake(0, 0, size.width, size.height)];
        [[UIColor.blackColor colorWithAlphaComponent:0.58] setFill];
        [[UIBezierPath bezierPathWithRoundedRect:box cornerRadius:height/3] fill];
        [text drawInRect:CGRectInset(box, pad, pad*0.8) withAttributes:attributes];
    }];
}
- (void)generateAndShare {
    [self.watermarkField resignFirstResponder];
    UIImage *image = [self renderWatermark];
    if (!image) { [self alert:@"图片尚未准备好"]; return; }
    NSData *data = UIImagePNGRepresentation(image);
    if (!data) { [self alert:@"水印图片生成失败"]; return; }
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"WeaveGlass-watermarked.png"];
    if (![data writeToFile:path atomically:YES]) { [self alert:@"临时文件写入失败"]; return; }
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:path]] applicationActivities:nil];
    if (activity.popoverPresentationController) {
        activity.popoverPresentationController.sourceView = self.shareButton;
        activity.popoverPresentationController.sourceRect = self.shareButton.bounds;
    }
    [self presentViewController:activity animated:YES completion:nil];
}
- (void)alert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"水印" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
