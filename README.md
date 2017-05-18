# XBLauchMovieViewController
## APP启动 播放启动视频
* 第一：最主要是解决 视频播放 前后 转场衔接流畅问题，防止闪黑！
* 第二：当视频在播放中，进入后台视频暂停，在进入APP视频继续播放

</br>
</br>
 
## 关键的3个点

1. 在moviePlayer 的view和backgroundView 分别加上启动图片和结束播放图片空间，为什么这么放 有兴趣可以研究一下

 ``` /*****  第一个重点 关键设置   这个 操作很关键, 关系到app转场效果****/
    // 播放之前设置启动页图片 防止闪黑，图片 最好 是视频第一帧，转场效果更好
    [self.moviePlayer.view addSubview:_startPlayMovieImageView];
    //首次使用app， 需要点击 “进入”按钮才能进入app, 为了防止启动视频结束后 闪动空白页, 所以会调用视频截图操作("movieThumbnailLoadComplete:"), 截取 视频 当前帧,来让moviePlayer不会显示黑色
    //第二次启动app之后 用的是短视频的 最后一帧 图片
    [self.moviePlayer.backgroundView addSubview:_stopPlayMovieImageView];
    //为什么加启动图片加载到 self.moviePlayer.view上,结束之后为什么加载self.moviePlayer.backgroundView上，有兴趣的同学可以研究一下(当初也是遇见各种坑)'''
 ```
</br>
2. 移除UIApplicationDidEnterBackgroundNotification通知，防止其进入后台异常（具体忘了，好像是在iOS8遇见的问题）
</br>

 ```
  /***** 第二个重点 在iOS8不移除有问题 *****/
    /**
     *  MPMoviePlayerController 在程序置到后台 之后会自动结束播放视频，移除监听之后才能置到后台之后暂停
     *  这个很关键，否则可能遇到未知问题
     */
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    //添加通知
    //进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    if ([self isFirstLauchApp]) {//第一次启动视频
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stopPlayMovie)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:nil];//播放结束
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startPlayMovie)
                                                 name:MPMoviePlayerNowPlayingMovieDidChangeNotification
                                               object:nil];//开始播放
 ```
 </br>
3. 点击 “进入应用”首先暂停视频，获取当前帧设置 图片
</br>

``` 
    [self.moviePlayer pause];
    /*****  第三重点 关键位置    ****/
    // 截取当前暂停时的图片,放到stopPlayMovieImageView,防止闪黑
    CGFloat currentPlayBackTime = self.moviePlayer.currentPlaybackTime;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieThumbnailLoadComplete:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:self.moviePlayer];
    [self.moviePlayer requestThumbnailImagesAtTimes:@[[NSNumber numberWithFloat:currentPlayBackTime]] timeOption:MPMovieTimeOptionExact];
 ```
 
 
 更新文档 一是因为有空闲时间了，二是看到别人拿我的项目 放到自己的github上然后有 100多个star。心里边... 如果有更好方法 可以联系QQ469926011
 如果转载 希望加上原地址谢谢！！
 
 
