//
//  XBLauchMovieViewController.m
//  XBLaunchMovieDemo
//
//  Created by coderPoo on 16/6/21.
//  Copyright © 2016年 coderPoo. All rights reserved.
//

#import "XBLauchMovieViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"

#define kIsFirstLauchApp @"kIsFirstLauchApp"

@interface XBLauchMovieViewController ()

/**
 *  以下两个imageView都是为了 控制器切换时 界面无缝衔接 防止空白页闪过
 */
@property (nonatomic, strong) UIImageView *startPlayerImageView; //播放开始之前imageView
@property (nonatomic, strong) UIImageView *overPlayerImageView;  //播放完成之后的imageView

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UIButton *enterMainButton;

@end

@implementation XBLauchMovieViewController

#pragma mark - init
-(BOOL)shouldAutorotate
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //设置界面
    [self setupview];

    //添加监听
    [self addNotification];
    
    //设置播放器
    [self prepareMovie];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.timer invalidate];
    self.timer = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.moviePlayer  play];
    NSLog(@"lauchMovieView will appear");
    
    [UIApplication sharedApplication].statusBarHidden = NO;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewWillEnterForeground
{
    /* Set the movie object settings (control mode, background color, and so on)
     in case these changed. */
    NSLog(@"app enter foreground");
    if (!self.moviePlayer) {
        [self prepareMovie];
    }
    
    [self.moviePlayer play];
}

- (void)viewWillEnterBackground //没有调用过
{
    /* Set the movie object settings (control mode, background color, and so on)
     in case these changed. */
    [self.moviePlayer pause];
    NSLog(@"app enter background");
}

#pragma mark - setup view
- (void)setupview
{
    //这个 操作很关键, 关系到app转场效果
    //第一次启动 以为视频是轮播 需要点击 “进入”按钮才能进入app, 为了防止启动视频结束后 闪动空白页, 所以会调用视频截图操作("movieThumbnailLoadComplete:"), 截取你点击“进入”按钮时 视频正在播放的那一帧图片,来让moviePlayer不会显示黑色
    //第一次启动之后 用的是短视频的 最后一帧 图片
    UIImageView *overPlayerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"longtail_0915"]];
    overPlayerImageView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    //添加位置很关键，否则会遇到bug
    [self.moviePlayer.backgroundView addSubview:overPlayerImageView];
    self.overPlayerImageView = overPlayerImageView;
    
    // movieplayer播放之前放上启动页图片 防止闪动黑色
    UIImageView *startPlayerImageView;
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        startPlayerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iphone4s"]];
    } else {
        startPlayerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lauch"]];
    }
    startPlayerImageView.frame = [UIScreen mainScreen].bounds;
    [self.moviePlayer.view addSubview:startPlayerImageView];
    self.startPlayerImageView = startPlayerImageView;
    
    
    //第一次安装 添加进入 app按钮
    if (![self isFirstLauchApp]) {
        [self setupEnterMainButton];
    }
}

#pragma mark setup enter Main Button
- (void)setupEnterMainButton
{
    //进入按钮
    self.enterMainButton = [[UIButton alloc] init];
    self.enterMainButton.frame = CGRectMake(24, [UIScreen mainScreen].bounds.size.height - 32 - 48, [UIScreen mainScreen].bounds.size.width - 48, 48);
    self.enterMainButton.layer.borderWidth = 1;
    self.enterMainButton.layer.cornerRadius = 24;
    self.enterMainButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.enterMainButton setTitle:@"进入应用" forState:UIControlStateNormal];
    self.enterMainButton.hidden = YES;
    [self.view addSubview:_enterMainButton];
    [self.enterMainButton addTarget:self action:@selector(enterMainAction:) forControlEvents:UIControlEventTouchUpInside];
    
    //设置定时 当视频播放 是第三秒时 展示进入应用按钮
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(showEnterMainButton) userInfo:nil repeats:YES];
}

#pragma mark enter main button
//视频播放三秒时显示按钮
- (void)showEnterMainButton
{
    NSInteger currentPlayBackTime = (NSInteger)self.moviePlayer.currentPlaybackTime;
    if (currentPlayBackTime == 3) {
        self.enterMainButton.hidden = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self.enterMainButton.alpha = 0;
            [UIView animateWithDuration:0.5 animations:^{
                self.enterMainButton.alpha = 1;
            } completion:nil];
        });
    }
    
    if (currentPlayBackTime > 5) {//防止没有显示出来
        self.enterMainButton.hidden = NO;
        [self.timer invalidate];
        self.timer = nil;
    }
}

//设置进入主界面按钮操作
- (void)enterMainAction:(id)sender
{
    [self.moviePlayer pause];

    self.overPlayerImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    //截取当前暂停时的图片
    CGFloat currentPlayBackTime = self.moviePlayer.currentPlaybackTime;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieThumbnailLoadComplete:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:self.moviePlayer];
    [self.moviePlayer requestThumbnailImagesAtTimes:@[[NSNumber numberWithFloat:currentPlayBackTime]] timeOption:MPMovieTimeOptionExact];
}

#pragma mark - set up moviePlayer
-(void)prepareMovie
{
    // 首次运行简介页
    NSString *filePath = nil;
    if(![self isFirstLauchApp]){ //第一次安装
        filePath = [[NSBundle mainBundle] pathForResource:@"opening_long_1080*1920" ofType:@"mp4"];
        [self setIsFirstLauchApp:YES];
    }else{
        filePath = [[NSBundle mainBundle] pathForResource:@"opening_short_1080*1920" ofType:@"mp4"];
    }
    
    //设置moviePlayer
    self.moviePlayer.movieSourceType = MPMovieSourceTypeUnknown;
    NSURL *vedioUrl= [NSURL fileURLWithPath:filePath];
    self.moviePlayer.contentURL = vedioUrl;
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer.view setFrame:[[UIScreen mainScreen] bounds]];
    if ([self isFirstLauchApp]) {
        self.moviePlayer.repeatMode = MPMovieRepeatModeNone;
    } else {
        self.moviePlayer.repeatMode = MPMovieRepeatModeOne;
    }
    self.moviePlayer.backgroundView.backgroundColor = [UIColor whiteColor];
    self.moviePlayer.view.backgroundColor = [UIColor whiteColor];
    self.moviePlayer.controlStyle = MPMovieControlStyleNone;
    self.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    self.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
}

#pragma mark request Thumbnail Images
//通知截取图片成功
-(void)movieThumbnailLoadComplete:(NSNotification *)receive
{
    // 配置的截取图片
    NSDictionary *receiveInfo = [receive userInfo];
    [receiveInfo valueForKey:MPMoviePlayerThumbnailImageKey];
    if ([receiveInfo valueForKey:MPMoviePlayerThumbnailImageKey]) {
        self.overPlayerImageView.image = [receiveInfo valueForKey:MPMoviePlayerThumbnailImageKey];
    }
    
    // 视频播放完成
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self moviePlaybackComplete];
    });
}

#pragma mark - add Notification
- (void)addNotification
{
    /**
     *  MPMoviePlayerController 在程序置到后台 之后会自动结束播放视频，移除监听之后才能置到后台之后暂停
     *  这个很关键，否则可能遇到未知问题
     */
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];//进入前台
    if ([self isFirstLauchApp]) {//第一次视频需要轮播
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlaybackComplete)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:nil];//视频播放结束
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlaybackStart)
                                                 name:MPMoviePlayerNowPlayingMovieDidChangeNotification
                                               object:nil];//开始播放
}


//开始播放
- (void)moviePlaybackStart
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.startPlayerImageView removeFromSuperview];
        self.startPlayerImageView = nil;
    });
}

//视频播放完成
- (void)moviePlaybackComplete
{
    //    [self.moviePlayer stop];
    //发送推送之后就删除  否则 界面显示有问题
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:nil];
    
    [self.startPlayerImageView removeFromSuperview];
    self.startPlayerImageView = nil;
    
    [self.overPlayerImageView removeFromSuperview];
    self.overPlayerImageView = nil;
    
    if (self.timer){
        [self.timer invalidate];
        self.timer = nil;
    }
    
    //进入主界面
    [self enterMain];
}

- (void)enterMain
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIViewController *main = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialViewController];
    //    [delegate showRootViewController];
    delegate.window.rootViewController = main;
    [delegate.window makeKeyAndVisible];
}

#pragma mark - get or set isFirstLauchApp
- (BOOL)isFirstLauchApp
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kIsFirstLauchApp];
}

- (void)setIsFirstLauchApp:(BOOL)isFirstLauchApp
{
    [[NSUserDefaults standardUserDefaults] setBool:isFirstLauchApp forKey:kIsFirstLauchApp];
}
@end
