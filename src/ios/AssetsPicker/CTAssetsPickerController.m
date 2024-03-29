/*
 CTAssetsPickerController.m
 
 The MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "CTAssetsPickerConstants.h"
#import "CTAssetsPickerController.h"
#import "CTAssetsGroupViewController.h"
#import "CTAssetsViewController.h"
#import "CTAssetsViewController.h"
#import "SVProgressHUD.h"



NSString * const CTAssetsPickerSelectedAssetsChangedNotification = @"CTAssetsPickerSelectedAssetsChangedNotification";



@interface CTAssetsPickerController () {
    
}

@property (nonatomic, strong) UIBarButtonItem *titleButton;
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;


- (void)setActionForTitleButton:(BOOL)bSet;

@end





@implementation CTAssetsPickerController

- (id)init:(BOOL)isDateBookmark
{
    
    if (isDateBookmark)
    {
        CTAssetsViewController *viewController = [[CTAssetsViewController alloc] initWithType:CTAssetsViewTypeBookmarks withPicker:self];
        
        //self = [super initWithRootViewController:viewController];
        self = [super init];
        self.isDateBookmark = isDateBookmark;
        
        
        [self setViewControllers:@[viewController] animated:NO];
    }
    else
    {
        CTAssetsGroupViewController *groupViewController = [[CTAssetsGroupViewController alloc] init];

        self = [super initWithRootViewController:groupViewController];
    }
    
    if (self)
    {
        _isDateBookmark     = isDateBookmark;
        _assetsLibrary      = [self.class defaultAssetsLibrary];
        _assetsFilter       = [ALAssetsFilter allAssets];
        _selectedAssets     = [[NSMutableArray alloc] init];
        _prevOverlayAssetIds = [[NSMutableDictionary alloc] init];
        _overlayAssets      = [[NSMutableDictionary alloc] init];
        _showsCancelButton  = YES;
        _previousAssets     = [[NSMutableDictionary alloc] init];

        self.preferredContentSize = kPopoverContentSize;
        
        [self addKeyValueObserver];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (NSString *overlayName in [self.prevOverlayAssetIds allKeys]) {
        NSArray *assetIds = [self.prevOverlayAssetIds objectForKey:overlayName];
        for (int i = 0; i < assetIds.count; i++)
        {
            NSString *url = [assetIds objectAtIndex:i];
            [[CTAssetsPickerController defaultAssetsLibrary] assetForURL:[NSURL URLWithString:url] resultBlock:^(ALAsset *asset) {
                //[self performSelector:@selector(selectAsset:) withObject:asset afterDelay:NO];
                [self performSelector:@selector(overlayAsset:) withObject:@{@"overlayName": overlayName, @"asset":asset} afterDelay:NO];
            } failureBlock:^(NSError *error) {
            }];
        }
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
 /*
    if (self.isDateBookmark)
    {
        [SVProgressHUD showWithStatus:@"Loading"];
        CTAssetsViewController *vc = [self.viewControllers objectAtIndex:0];
        [vc setupWholeAssetsWithCompletion:^(){
            [SVProgressHUD dismiss];
        }];
    }
  */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [self removeKeyValueObserver];
}


#pragma mark - ALAssetsLibrary

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred,^
                  {
                      library = [[ALAssetsLibrary alloc] init];
                  });
    return library;
}


#pragma mark - Key-Value Observers

- (void)addKeyValueObserver
{
    [self addObserver:self
           forKeyPath:@"selectedAssets"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
              context:nil];
}

- (void)removeKeyValueObserver
{
    [self removeObserver:self forKeyPath:@"selectedAssets"];
}


#pragma mark - Key-Value Changed

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"selectedAssets"])
    {
        [self toggleDoneButton];
        [self postNotification:[object valueForKey:keyPath]];
    }
}


#pragma mark - Toggle Button

- (void)toggleDoneButton
{
    for (UIViewController *viewController in self.viewControllers)
        viewController.navigationItem.rightBarButtonItem.enabled = (self.selectedAssets.count > 0);
}


#pragma mark - Post Notification

- (void)postNotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CTAssetsPickerSelectedAssetsChangedNotification
                                                        object:sender];
}


#pragma mark - Indexed Accessors

- (NSUInteger)countOfSelectedAssets
{
    return self.selectedAssets.count;
}

- (id)objectInSelectedAssetsAtIndex:(NSUInteger)index
{
    return [self.selectedAssets objectAtIndex:index];
}

- (void)insertObject:(id)object inSelectedAssetsAtIndex:(NSUInteger)index
{
    [self.selectedAssets insertObject:object atIndex:index];
}

- (void)removeObjectFromSelectedAssetsAtIndex:(NSUInteger)index
{
    [self.selectedAssets removeObjectAtIndex:index];
}

- (void)replaceObjectInSelectedAssetsAtIndex:(NSUInteger)index withObject:(ALAsset *)object
{
    [self.selectedAssets replaceObjectAtIndex:index withObject:object];
}

- (void)insertOverlay:(NSDictionary *)dic
{
    NSMutableArray *assets = [self.overlayAssets objectForKey:[dic objectForKey:@"overlayName"]];
    if (assets == nil)
    {
        assets = [[NSMutableArray alloc] init];
        [self.overlayAssets setObject:assets forKey:[dic objectForKey:@"overlayName"]];
    }
    [assets addObject:[dic objectForKey:@"asset"]];
}

#pragma mark - Select / Deselect Asset

- (void)selectAsset:(ALAsset *)asset
{
    [self insertObject:asset inSelectedAssetsAtIndex:self.countOfSelectedAssets];
}

- (void)deselectAsset:(ALAsset *)asset
{
    int index = [self.selectedAssets indexOfObject:asset];
    if (index > self.selectedAssets.count)
        return;
    
    [self removeObjectFromSelectedAssetsAtIndex:[self.selectedAssets indexOfObject:asset]];
}

#pragma mark - Overlay Asset
- (void)overlayAsset:(NSDictionary *)dic
{
    [self insertOverlay:dic];
}


#pragma mark - Not Allowed / No Assets Views

- (NSString *)deviceModel
{
    return [[UIDevice currentDevice] model];
}

- (BOOL)isCameraDeviceAvailable
{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (UIImageView *)padlockImageView
{
    UIImageView *padlock = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CTAssetsPickerLocked"]];
    padlock.translatesAutoresizingMaskIntoConstraints = NO;
    
    return padlock;
}

- (NSString *)noAssetsMessage
{
    NSString *format;
    
    if ([self isCameraDeviceAvailable])
        format = NSLocalizedString(@"You can take photos and videos using the camera, or sync photos and videos onto your %@\nusing iTunes.", nil);
    else
        format = NSLocalizedString(@"You can sync photos and videos onto your %@ using iTunes.", nil);
    
    return [NSString stringWithFormat:format, self.deviceModel];
}

- (UILabel *)specialViewLabelWithFont:(UIFont *)font color:(UIColor *)color text:(NSString *)text
{
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.preferredMaxLayoutWidth = 304.0f;
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 5;
    label.font          = font;
    label.textColor     = color;
    label.text          = text;
    
    [label sizeToFit];
    
    return label;
}

- (UIView *)centerViewWithViews:(NSArray *)views
{
    UIView *centerView = [[UIView alloc] init];
    centerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    for (UIView *view in views)
    {
        [centerView addSubview:view];
        [centerView addConstraint:[self horizontallyAlignedConstraintWithItem:view toItem:centerView]];
    }
    
    return centerView;
}

- (UIView *)specialViewWithCenterView:(UIView *)centerView
{
    UIView *view = [[UIView alloc] init];
    [view addSubview:centerView];
    
    [view addConstraint:[self horizontallyAlignedConstraintWithItem:centerView toItem:view]];
    [view addConstraint:[self verticallyAlignedConstraintWithItem:centerView toItem:view]];
    
    return view;
}

- (NSLayoutConstraint *)horizontallyAlignedConstraintWithItem:(id)view1 toItem:(id)view2
{
    return [NSLayoutConstraint constraintWithItem:view1
                                        attribute:NSLayoutAttributeCenterX
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:view2
                                        attribute:NSLayoutAttributeCenterX
                                       multiplier:1.0f
                                         constant:0.0f];
}

- (NSLayoutConstraint *)verticallyAlignedConstraintWithItem:(id)view1 toItem:(id)view2
{
    return [NSLayoutConstraint constraintWithItem:view1
                                        attribute:NSLayoutAttributeCenterY
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:view2
                                        attribute:NSLayoutAttributeCenterY
                                       multiplier:1.0f
                                         constant:0.0f];
}

- (UIView *)notAllowedView
{
    UIImageView *padlock = [self padlockImageView];
    
    UILabel *title =
    [self specialViewLabelWithFont:[UIFont boldSystemFontOfSize:17.0]
                             color:[UIColor colorWithRed:129.0/255.0 green:136.0/255.0 blue:148.0/255.0 alpha:1]
                              text:NSLocalizedString(@"This app does not have access to your photos or videos.", nil)];
    UILabel *message =
    [self specialViewLabelWithFont:[UIFont systemFontOfSize:14.0]
                             color:[UIColor colorWithRed:129.0/255.0 green:136.0/255.0 blue:148.0/255.0 alpha:1]
                              text:NSLocalizedString(@"You can enable access in Privacy Settings.", nil)];
    
    UIView *centerView = [self centerViewWithViews:@[padlock, title, message]];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(padlock, title, message);
    [centerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[padlock]-20-[title]-[message]|" options:0 metrics:nil views:viewsDictionary]];
    
    return [self specialViewWithCenterView:centerView];
}

- (UIView *)noAssetsView
{
    UILabel *title =
    [self specialViewLabelWithFont:[UIFont systemFontOfSize:26.0]
                             color:[UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1]
                              text:NSLocalizedString(@"No Photos or Videos", nil)];
    
    UILabel *message =
    [self specialViewLabelWithFont:[UIFont systemFontOfSize:18.0]
                             color:[UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1]
                              text:[self noAssetsMessage]];
    
    UIView *centerView = [self centerViewWithViews:@[title, message]];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(title, message);
    [centerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title]-[message]|" options:0 metrics:nil views:viewsDictionary]];

    return [self specialViewWithCenterView:centerView];
}


#pragma mark - Toolbar Title

- (NSPredicate *)predicateOfAssetType:(NSString *)type
{
    return [NSPredicate predicateWithBlock:^BOOL(ALAsset *asset, NSDictionary *bindings) {
        return [[asset valueForProperty:ALAssetPropertyType] isEqual:type];
    }];
}

- (NSString *)toolbarTitle
{
    if (self.selectedAssets.count == 0)
        return nil;
    
    NSPredicate *photoPredicate = [self predicateOfAssetType:ALAssetTypePhoto];
    NSPredicate *videoPredicate = [self predicateOfAssetType:ALAssetTypeVideo];
    
    BOOL photoSelected = ([self.selectedAssets filteredArrayUsingPredicate:photoPredicate].count > 0);
    BOOL videoSelected = ([self.selectedAssets filteredArrayUsingPredicate:videoPredicate].count > 0);
    
    NSString *format;
    
    if (photoSelected && videoSelected)
        format = NSLocalizedString(@"%ld Items Selected", nil);
    
    else if (photoSelected)
        format = (self.selectedAssets.count > 1) ? NSLocalizedString(@"%ld Photos Selected", nil) : NSLocalizedString(@"%ld Photo Selected", nil);
    
    else if (videoSelected)
        format = (self.selectedAssets.count > 1) ? NSLocalizedString(@"%ld Videos Selected", nil) : NSLocalizedString(@"%ld Video Selected", nil);
    
    return [NSString stringWithFormat:format, (long)self.selectedAssets.count];
}


#pragma mark - Toolbar Items

- (UIBarButtonItem *)titleButtonItem
{
    if (_titleButton != nil)
        return _titleButton;
    
    _titleButton =
    [[UIBarButtonItem alloc] initWithTitle:self.toolbarTitle
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(showSelected:)];
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
    
    [_titleButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [_titleButton setTitleTextAttributes:attributes forState:UIControlStateDisabled];
    [_titleButton setEnabled:YES];
    
    return _titleButton;
}

- (UIBarButtonItem *)spaceButtonItem
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

- (NSArray *)toolbarItems
{
    UIBarButtonItem *title = [self titleButtonItem];
    UIBarButtonItem *space = [self spaceButtonItem];
    
    return @[space, title, space];
}


- (void)setActionForTitleButton:(BOOL)bSet
{
    if (bSet == NO)
    {
        _titleButton.action = nil;
        _titleButton.target = nil;
    }
    else
    {
        _titleButton.action = @selector(showSelected:);
        _titleButton.target = self;
    }
}

#pragma mark - Actions

- (void)dismiss:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(assetsPickerControllerDidCancel:)])
        [self.delegate assetsPickerControllerDidCancel:self];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)finishPickingAssets:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(assetsPickerController:didFinishPickingAssets:)])
        [self.delegate assetsPickerController:self didFinishPickingAssets:self.selectedAssets];
}

- (void)showSelected:(id)sender
{
    CTAssetsViewController *vc = [[CTAssetsViewController alloc] initWithType:CTAssetsViewTypeFiltered withPicker:self];
    [vc setupSelectedAssetsWithCompletion:^(){
        //[SVProgressHUD dismiss];
        [self pushViewController:vc animated:YES];
    }];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
}
#if false
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationMaskPortrait;
}
#endif


@end