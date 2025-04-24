//
//  ViewController.m
//  GJLocalDigitalDemo
//
//  Created by guiji on 2023/12/12.
//

#import "ViewController.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "HttpClient.h"
#import "SVProgressHUD.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Security/Security.h>
#import <GJLocalDigitalSDK/GJLocalDigitalSDK.h>

//#import <CoreTelephony/CTCellularData.h>
#import "GJCheckNetwork.h"
#import "SSZipArchive.h"
#import "GJDownWavTool.h"
#import "GYAccess.h"


//基础模型
#define BASEMODELURL   @"https://digital-public.obs.cn-east-3.myhuaweicloud.com/duix/location/gj_dh_res.zip"
//////数字人模型
#define DIGITALMODELURL @"https://digital-public.obs.cn-east-3.myhuaweicloud.com/duix/digital/model/1716034688/bendi3_20240518.zip"






@interface ViewController ()<GJDownWavToolDelegate>
@property(nonatomic,strong)UIView *showView;
@property(nonatomic,strong)NSString * basePath;
@property(nonatomic,strong)NSString * digitalPath;
@property (nonatomic, assign) BOOL isRequest;


//答案数组
@property (nonatomic, strong) NSMutableArray *answerArr;

//录音中
@property (nonatomic, assign) BOOL recording;


//多个音频开始和结束 当前播放音频状态 0 结束 1播放中
@property (nonatomic, assign) NSInteger playCurrentState;

//// 单个音频 0结束播放  1开始播放 2播放中 3播放暂停
//@property (nonatomic, assign) NSInteger playState;

/*
 * playAudioIndex 播放到第几个音频
 */
@property(nonatomic,assign)NSInteger playAudioIndex;




@property (nonatomic, strong)UILabel * questionLabel;

@property (nonatomic, strong)UILabel * answerLabel;


@property (nonatomic, strong) UIImageView * imageView;

@property (nonatomic, assign) BOOL isStop;

@property (nonatomic, strong) NSString *qaSessionId;

@end

@implementation ViewController
-(UIView*)showView
{
    if(nil==_showView)
    {
        _showView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        _showView.backgroundColor=[UIColor clearColor];
    }
    return _showView;
}
-(UIImageView*)imageView
{
    if(nil==_imageView)
    {
        _imageView=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        NSString *bgpath =[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] bundlePath],@"bg2.jpg"];
        _imageView.contentMode=UIViewContentModeScaleAspectFill;
        _imageView.image=[UIImage imageWithContentsOfFile:bgpath];
        
    }
    return _imageView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor greenColor];
    
    [self.view addSubview:self.imageView];
 
    [self.view addSubview:self.showView];
    

    
    
    [self.view addSubview:self.questionLabel];
    
    [self.view addSubview:self.answerLabel];
    
    
//    UITapGestureRecognizer * tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toShowquestion)];
//    tap.numberOfTapsRequired=2;
//    [self.showView addGestureRecognizer:tap];
    
    UIButton * startbtn=[UIButton buttonWithType:UIButtonTypeCustom];
    startbtn.frame=CGRectMake(40, self.view.frame.size.height-100, 40, 40);
    [startbtn setTitle:@"开始" forState:UIControlStateNormal];
    [startbtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [startbtn addTarget:self action:@selector(toStart) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:startbtn];
    
    UIButton * playbtn=[UIButton buttonWithType:UIButtonTypeCustom];
    playbtn.frame=CGRectMake(CGRectGetMaxX(startbtn.frame)+20, self.view.frame.size.height-100, 40, 40);
    [playbtn setTitle:@"播放" forState:UIControlStateNormal];
    [playbtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [playbtn addTarget:self action:@selector(toRecord) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:playbtn];
    
    
//    UIButton * stopPlaybtn=[UIButton buttonWithType:UIButtonTypeCustom];
//    stopPlaybtn.frame=CGRectMake(CGRectGetMaxX(playbtn.frame)+20, self.view.frame.size.height-100, 40, 40);
//    [stopPlaybtn setTitle:@"停止" forState:UIControlStateNormal];
//    [stopPlaybtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//    [stopPlaybtn addTarget:self action:@selector(toPlay) forControlEvents:UIControlEventTouchDown];
//    [self.view addSubview:stopPlaybtn];

    UIButton * stopbtn=[UIButton buttonWithType:UIButtonTypeCustom];
    stopbtn.frame=CGRectMake(CGRectGetMaxX(playbtn.frame)+20, self.view.frame.size.height-100, 40, 40);
    [stopbtn setTitle:@"结束" forState:UIControlStateNormal];
    [stopbtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [stopbtn addTarget:self action:@selector(toStop) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:stopbtn];

    [[GJCheckNetwork manager] getWifiState];
    __weak typeof(self)weakSelf = self;
    [GJCheckNetwork manager].on_net = ^(NetType state) {
        if (state == Net_WWAN
            || state == Net_WiFi) {
            if (!weakSelf.isRequest) {
                weakSelf.isRequest = YES;
                //注意有网络是初始化
                [weakSelf initALL];
                [weakSelf isDownModel];
            }
        }
    };
   



  
    

}
-(void)initALL
{
    //注意有网络是初始化ASR

    //初始化下载音频
    [[GJDownWavTool sharedTool] initCachesPath];
    [GJDownWavTool sharedTool].delegate = self;
    
    //初始化数字人回调和音频回调
    [self toDigitalBlock];
}
-(void)toShowquestion
{
    self.questionLabel.hidden=!self.questionLabel.hidden;
    self.answerLabel.hidden=!self.answerLabel.hidden;
}




- (void)downloadWithModel:(GJLDigitalAnswerModel *)answerModel {
    
    [[GJDownWavTool sharedTool] downWavWithModel:answerModel];
    
}

- (void)downloadFinish:(GJLDigitalAnswerModel *)answerModel finish:(BOOL)finish {
    

  
        NSInteger index = [self.answerArr indexOfObject:answerModel];
        if (finish) {
            if (index == self.playAudioIndex&&self.playCurrentState ==0) {
    
//
                [self toSpeakWithPath:answerModel];
            }
        } else {
            if (index == self.playAudioIndex&&self.playCurrentState ==0) {
                //如果要播就直接结束到下一个
                NSLog(@"播放问题---下载失败，播放下一条--%@",answerModel.filePath);
                
                [self moviePlayDidEnd];
            }
        }
 
}
-(void)toSpeakWithPath:(GJLDigitalAnswerModel*)answerModel
{
    //
    if(self.playAudioIndex==0)
    {
        //开始动作（一段文字包含多个音频，第一个音频开始时设置）
         [[GJLDigitalManager manager] toRandomMotion];
         [[GJLDigitalManager manager] toStartMotion];
    }
    self.playCurrentState = 1;
    [[GJLDigitalManager manager] toSpeakWithPath:answerModel.localPath];
    if(answerModel.answer.length>0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
         //   DLog(@"表示一次任务生命周期结束，可以开始新的识别");
            NSLog(@"answerModel.answer:%@",answerModel.answer);
            self.answerLabel.text=[answerModel.answer stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        });
        
    }
}
- (void)moviePlayDidEnd
{
    self.playAudioIndex ++;

    self.playCurrentState = 0;
    NSLog(@" self.playAudioIndex :%ld", self.playAudioIndex );
  
    if (self.answerArr.count > self.playAudioIndex) {
     
      
            GJLDigitalAnswerModel *answerModel = [self.answerArr objectAtIndex:self.playAudioIndex];
            if (answerModel.localPath.length == 0 && answerModel.download) {
                NSLog(@"error=====moviePlayDidEnd--下载失败了");
                [self moviePlayDidEnd];
            } else {
                [self playWithModel:answerModel];
            }
      
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.questionLabel.text=@"";
            self.answerLabel.text=@"";
        });
            [[GJLDigitalManager manager] toSopMotion:YES];
       
    }
}
- (void)playWithModel:(GJLDigitalAnswerModel *)answerModel {

    //    DLog(@"播放playUrl==%ld=播放==%@\n本地路径=%@",self.playState,answerModel.filePath,answerModel.localPath);
    if (self.recording ) {
        return;
    }
    __weak typeof(self)weakSelf = self;
    if (answerModel.localPath.length > 0) {

        [self toSpeakWithPath:answerModel];
    
    
    }
}
- (NSMutableArray *)answerArr {
    
    if (nil == _answerArr) {
        _answerArr = [NSMutableArray array];
    }
    return _answerArr;
}
-(void)isDownModel
{
    NSString *unzipPath = [self getHistoryCachePath:@"unZipCache"];
    NSString * baseName=[[BASEMODELURL lastPathComponent] stringByDeletingPathExtension];
    self.basePath=[NSString stringWithFormat:@"%@/%@",unzipPath,baseName];
    
    NSString * digitalName=[[DIGITALMODELURL lastPathComponent] stringByDeletingPathExtension];
    self.digitalPath=[NSString stringWithFormat:@"%@/%@",unzipPath,digitalName];
    NSFileManager * fileManger=[NSFileManager defaultManager];
    if((![fileManger fileExistsAtPath:self.basePath])&&(![fileManger fileExistsAtPath:self.digitalPath]))
    {
        //下载基础模型和数字人模型
        [self toDownBaseModelAndDigital];

    }
   else if (![fileManger fileExistsAtPath:self.digitalPath])
    {
        //数字人模型
        [SVProgressHUD show];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
        [self toDownDigitalModel];
    }
    

}
//下载基础模型----不同的数字人模型使用同一个基础模型
-(void)toDownBaseModelAndDigital
{
    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    __weak typeof(self)weakSelf = self;
    NSString *zipPath = [self getHistoryCachePath:@"ZipCache"];
    //下载基础模型
    [[HttpClient manager] downloadWithURL:BASEMODELURL savePathURL:[NSURL fileURLWithPath:zipPath] pathExtension:nil progress:^(NSProgress * progress) {
        double down_progress=(double)progress.completedUnitCount/(double)progress.totalUnitCount*0.5;
        [SVProgressHUD showProgress:down_progress status:@"正在下载基础模型"];
    } success:^(NSURLResponse *response, NSURL *filePath) {
        NSLog(@"filePath:%@",filePath);
        
        [weakSelf toUnzip:filePath.absoluteString];
        //下载数字人模型
        [weakSelf  toDownDigitalModel];
  
    } fail:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
}
-(void)toUnzip:(NSString*)filePath
{
    filePath=[filePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSString *unzipPath = [self getHistoryCachePath:@"unZipCache"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        [SSZipArchive unzipFileAtPath:filePath toDestination:unzipPath progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
            
        } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable error) {
            NSLog(@"path:%@,%d",path,succeeded);
        
        }];
    });
 
 
}
//下载数字人模型
-(void)toDownDigitalModel
{
    __weak typeof(self)weakSelf = self;
    NSString *zipPath = [self getHistoryCachePath:@"ZipCache"];
    [[HttpClient manager] downloadWithURL:DIGITALMODELURL savePathURL:[NSURL fileURLWithPath:zipPath] pathExtension:nil progress:^(NSProgress * progress) {
        double down_progress=0.5+(double)progress.completedUnitCount/(double)progress.totalUnitCount*0.5;
        [SVProgressHUD showProgress:down_progress status:@"正在下载数字人模型"];
    } success:^(NSURLResponse *response, NSURL *filePath) {
        NSLog(@"filePath:%@",filePath);
        [weakSelf toUnzip:filePath.absoluteString];
        [SVProgressHUD showSuccessWithStatus:@"下载成功"];
    } fail:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
}
-(void)toStart
{
    __weak typeof(self)weakSelf = self;
    //授权
    self.isStop=NO;
//    [GJLDigitalManager manager].modeType=2;
//    [GJLDigitalManager manager].backType=1;
 
           NSInteger result=   [[GJLDigitalManager manager] initBaseModel:weakSelf.basePath digitalModel:self.digitalPath showView:weakSelf.showView];
            if(result==1)
            {
               //开始
//                NSString *bgpath =[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] bundlePath],@"bg2.jpg"];
//                [[GJLDigitalManager manager] toChangeBBGWithPath:bgpath];
                [[GJLDigitalManager manager] toStart:^(BOOL isSuccess, NSString *errorMsg) {
                    if(!isSuccess)
                    {
                        [SVProgressHUD showInfoWithStatus:errorMsg];
                    }
                }];
            }
   
  
}


//播放音频
-(void)toRecord
{
//    [[GJLDigitalManager manager] toRandomMotion];
//    [[GJLDigitalManager manager] toStartMotion];
     NSString * filepath=[[NSBundle mainBundle] pathForResource:@"3.wav" ofType:nil];
     [[GJLDigitalManager manager] toSpeakWithPath:filepath];


    
}

#pragma mark ------------回调----------------
-(void)toDigitalBlock
{
    
    __weak typeof(self)weakSelf = self;
    [GJLDigitalManager manager].playFailed = ^(NSInteger code, NSString *errorMsg) {

            [SVProgressHUD showInfoWithStatus:errorMsg];

      
    };
    [GJLDigitalManager manager].audioPlayEnd = ^{
        [weakSelf moviePlayDidEnd];

     
    };
    
    [GJLDigitalManager manager].audioPlayProgress = ^(float current, float total) {
        
    };
 
}

#pragma mark ------------结束所有----------------
-(void)toStop
{
    self.isStop=YES;


    //停止绘制
    [[GJLDigitalManager manager] toStop];
}

-(NSString *)getHistoryCachePath:(NSString*)pathName
{
    NSString* folderPath =[[self getFInalPath] stringByAppendingPathComponent:pathName];
    //创建文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断temp文件夹是否存在
    BOOL fileExists = [fileManager fileExistsAtPath:folderPath];
    //如果不存在说创建,因为下载时,不会自动创建文件夹
    if (!fileExists)
    {
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return folderPath;
}

- (NSString *)getFInalPath
{
    NSString* folderPath =[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"GJCache"];
    //创建文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断temp文件夹是否存在
    BOOL fileExists = [fileManager fileExistsAtPath:folderPath];
    //如果不存在说创建,因为下载时,不会自动创建文件夹
    if (!fileExists) {
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return folderPath;
}

-(UILabel*)questionLabel
{
    if(nil==_questionLabel)
    {
        _questionLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-220, self.view.frame.size.width-40, 40)];
        _questionLabel.backgroundColor=[UIColor redColor];
        _questionLabel.numberOfLines=0;
        _questionLabel.textColor=[UIColor whiteColor];
        _questionLabel.font=[UIFont systemFontOfSize:12];
        _questionLabel.textAlignment=NSTextAlignmentLeft;
        _questionLabel.hidden=YES;
    }
    return _questionLabel;
}
-(UILabel*)answerLabel
{
    if(nil==_answerLabel)
    {
        _answerLabel=[[UILabel alloc] initWithFrame:CGRectMake(40, self.view.frame.size.height-160, self.view.frame.size.width-40, 40)];
        _answerLabel.backgroundColor=[UIColor redColor];
        _answerLabel.numberOfLines=0;
        _answerLabel.textColor=[UIColor whiteColor];
        _answerLabel.font=[UIFont systemFontOfSize:12];
        _answerLabel.textAlignment=NSTextAlignmentLeft;
        _answerLabel.hidden=YES;
    }
    return _answerLabel;
}


@end
