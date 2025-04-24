//
//  DigitalHumanDriven.m
//  Digital
//
//  Created by cunzhi on 2023/11/9.
//

#import "DigitalHumanDriven.h"
#import <UIKit/UIKit.h>

#import "gjdigit.h"
#include <stdio.h>
#include "jmat.h"

//#import "MHCVPixelBuffer.h"
static DigitalHumanDriven *manager = nil;
static dispatch_once_t onceToken;

@interface DigitalHumanDriven () {
    gjdigit_t* gjdigit;
}


@end
@implementation DigitalHumanDriven


+ (instancetype)manager {
    dispatch_once(&onceToken, ^{
        manager = [[DigitalHumanDriven alloc] init];
       // [manager initGJDigital];
    });
    return manager;
}
-(id)init
{
    self=[super init];
    if(self)
    {
        self.configModel=[[DigitalConfigModel alloc] init];
        self.metal_type=0;
        self.back_type=0;
//        self.mat_type=0;
    }
    return self;
}
- (int)initGJDigital {
//    self.isStop=YES;
    // 在这里实现对应的功能
    gjdigit_t* gd = NULL;
    int rst = 0;
    rst = gjdigit_alloc(&gd);
    gjdigit = gd;
    return rst;
}
  
- (int)initWenetWithPath:(NSString*)path {
    
    int rst = 0;
    const char *cStr = [path UTF8String];
    char *charStr = (char *)cStr;
    rst = gjdigit_initWenet(gjdigit,charStr);
    return rst;
}
  
- (int)initMunetWithParamPath:(NSString*)paramPath binPath:(NSString*)binPath binPath2:(NSString*)binPath2 {
    
    int rst = 0;
    const char *cParamPath = [paramPath UTF8String];
    char *paramPathStr = (char *)cParamPath;
    
    const char *cBinPath = [binPath UTF8String];
    char *binPathStr = (char *)cBinPath;
    
    const char *cBinPath2 = [binPath2 UTF8String];
    char *binPathStr2 = (char *)cBinPath2;
    
    rst = gjdigit_initMunet(gjdigit,paramPathStr,binPathStr,binPathStr2);
    return rst;
}

- (int)initAlphaWithParamPath:(NSString*)paramPath binPath:(NSString*)binPath {
    
    int rst = 0;
    const char *cParamPath = [paramPath UTF8String];
    char *paramPathStr = (char *)cParamPath;
    
    const char *cBinPath = [binPath UTF8String];
    char *binPathStr = (char *)cBinPath;

    
    rst = gjdigit_initMalpha(gjdigit,paramPathStr,binPathStr);
    return rst;
}
  
- (AVURLAsset*)onewavWithPath:(NSString*)path
{
    

    const char *cStr = [path UTF8String];
//    char *charStr = (char *)cStr;
    AVURLAsset *audioAsset = nil;
  //  NSDictionary *dic = @{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
//    double time1=[[NSDate date] timeIntervalSince1970];
    if ([path hasPrefix:@"http://"]) {
        audioAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:path] options:nil];
    }else {
        audioAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    }

    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    float duration=audioDurationSeconds;
//    double time2=[[NSDate date] timeIntervalSince1970];
  //  NSLog(@"加载音频:%f",time2-time1);
    
    int wavframe = gjdigit_onewav(gjdigit,cStr,duration);
    self.wavframe = wavframe;
    return audioAsset;
   


//    NSLog(@"time2%f",time2-time);
  
}

- (int)matrstWithData:(uint8_t*)data width:(int)width height:(int)height boxs: (int*)boxs index: (int)index {
    
    int rst = 0;
    rst = gjdigit_matrst(gjdigit,data,width,height,boxs,index);
    return rst;
}

- (void)matrstWithPath:(NSString *)imagePath index:(int)index array:(NSArray *)array {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        double time1=[[NSDate date] timeIntervalSince1970];
      
//        char *charStr = (char *) [imagePath UTF8String];
//        std::string fn = charStr;
        JMat mat;
        int mat_result=mat.load([imagePath UTF8String]);
        int boxs[4];
        if (array.count == 4) {
            boxs[0]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:0]] intValue];
            boxs[2]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:1]] intValue];
            boxs[1]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:2]] intValue];
            boxs[3]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:3]] intValue];
        }
        
        int rst = gjdigit_matrst(self->gjdigit,mat.udata(),mat.width(),mat.height(),boxs,index);
        double time2=[[NSDate date] timeIntervalSince1970];
//        NSLog(@"处理图片:%f",time2-time1);
        if (rst >= 0) {
//            CVPixelBufferRef cvPixelBuffer=getImageBufferFromMat(mat.cvmat());
//            if(self.pixerBlock)
//            {
//                self.pixerBlock(cvPixelBuffer);
//            }
            
//            if(self.matBlock)
//                     {
//                         self.matBlock(mat.cvmat());
//                     }
        }
//        if(self.imageBlock)
//        {
//            CVPixelBufferRef cvPixelBuffer=getImageBufferFromMat(mat.cvmat());
//            UIImage *image = [self getUIImageFromCVPixelBuffer:cvPixelBuffer];
//            self.imageBlock(image);
//        }
        //usleep(40000);
    });
}
  
- (void)maskrstWithPath:(NSString *)imagePath index:(int)index array:(NSArray *)array mskPath:(NSString*)maskPath bfgPath:(NSString*)bfgPath bbgPath:(NSString*)bbgPath  {

       
          
          JMat mat;
          int mat_result=mat.load([imagePath UTF8String]);
          JMat maskMat;
          int mask_result=maskMat.load([maskPath UTF8String]);
          JMat bfgMat;
          int bfg_result=bfgMat.load([bfgPath UTF8String]);

        if(mat_result<0 || mask_result<0 || bfg_result<0 )
        {
           return;
        }
    
       JMat bbgMat;
       if(bbgPath!=nil&&bbgPath.length>0)
       {
          int bbg_result=bbgMat.load([bbgPath UTF8String]);
          if(bbg_result<0 )
          {
             return;
          }
       }
        
        int boxs[4];
        if (array.count == 4) {
            boxs[0]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:0]] intValue];
            boxs[2]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:1]] intValue];
            boxs[1]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:2]] intValue];
            boxs[3]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:3]] intValue];
        }
//        self.isStop=NO;
        
        int rst;
        if (index > 0) {
            if(self.wavframe==0)
            {
                rst=gjdigit_maskrst(self->gjdigit, mat.udata(), mat.width(), mat.height(), boxs, maskMat.udata(),bfgMat.udata(),NULL, 0);
            }
            else
            {
                if (index > self.wavframe) {
                    rst=gjdigit_maskrst(self->gjdigit, mat.udata(), mat.width(), mat.height(), boxs, maskMat.udata(),bfgMat.udata(),NULL, self.wavframe);
                } else {
               
                    rst=gjdigit_maskrst(self->gjdigit, mat.udata(), mat.width(), mat.height(), boxs, maskMat.udata(),bfgMat.udata(),NULL, index);
               
                   
                }
            }
          
        } else {
            
            rst=0;
        }
       

     
        if (rst >= 0) {

         
            if(self.metal_type==0)
            {
                
                if(self.matBlock)
                {
                   self.matBlock(mat.cvmat().clone(),maskMat.cvmat().clone(),bfgMat.cvmat().clone(),bbgMat.cvmat().clone());
                    mat.cvmat().release();
                    maskMat.cvmat().release();
                    bfgMat.cvmat().release();
                    bbgMat.cvmat().release();
                }
            }
            else
            {
               
                if(self.uint8Block)
                {
                    cv::Mat reuslt_mat=mat.cvmat().clone();
                    cv::Mat reuslt_maskMat=maskMat.cvmat().clone();
                    cv::Mat reuslt_bfgMat=bfgMat.cvmat().clone();
                    cv::Mat reuslt_bbgMat=bbgMat.cvmat().clone();
                    
                    UInt8 * reuslt_mat_uint8=nil;
                    if(!reuslt_mat.empty())
                    {
                        reuslt_mat_uint8=[self convertedRawImage:reuslt_mat];
                    }
                    
                    UInt8 * reuslt_maskMat_uint8=nil;
                    if(!reuslt_maskMat.empty())
                    {
                        reuslt_maskMat_uint8=[self convertedRawImage:reuslt_maskMat];
                    }
                  
                    
                    UInt8 * reuslt_bfgMat_uint8=nil;
                    if(!reuslt_bfgMat.empty())
                    {
                        reuslt_bfgMat_uint8=[self convertedRawImage:reuslt_bfgMat];
                    }
                  
                    UInt8 * reuslt_bbg_uint8=nil;
                    if (!reuslt_bbgMat.empty())
                    {
                        reuslt_bbg_uint8 =[self convertedRawImage:reuslt_bbgMat];
                    }
            
                    self.uint8Block(reuslt_mat_uint8, reuslt_maskMat_uint8, reuslt_bfgMat_uint8, reuslt_bbg_uint8, mat.width(), mat.height());
                    reuslt_mat.release();
                    reuslt_maskMat.release();
                    reuslt_bfgMat.release();
                    reuslt_bbgMat.release();
                    mat.cvmat().release();
                    maskMat.cvmat().release();
                    bfgMat.cvmat().release();
                    bbgMat.cvmat().release();
                }
            }
         
            
            
        }
    
  

}
- (void)simprstWithPath:(NSString *)imagePath index:(int)index array:(NSArray *)array
{

       
          
        JMat mat;
        int mat_result=mat.load([imagePath UTF8String]);
        
        if(mat_result<0)
        {
           return;
        }
    

        
        int boxs[4];
        if (array.count == 4) {
            boxs[0]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:0]] intValue];
            boxs[2]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:1]] intValue];
            boxs[1]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:2]] intValue];
            boxs[3]= [[NSString stringWithFormat:@"%@",[array objectAtIndex:3]] intValue];
        }
//        self.isStop=NO;
        
        int rst;
        if (index > 0) {
            if(self.wavframe==0)
            {
                rst=gjdigit_simprst(self->gjdigit, mat.udata(), mat.width(), mat.height(), boxs, 0);
            }
            else
            {
                if (index > self.wavframe) {
                    rst=gjdigit_simprst(self->gjdigit, mat.udata(), mat.width(), mat.height(), boxs, self.wavframe);
                } else {
               
                    rst=gjdigit_simprst(self->gjdigit, mat.udata(), mat.width(), mat.height(), boxs, index);
               
                   
                }
            }
          
        } else {
            
            rst=0;
        }
       

     
        if (rst >= 0) {

         
            if(self.metal_type==0)
            {
                
                if(self.matBlock2)
                {
            
                    self.matBlock2(mat.cvmat().clone());
                    mat.cvmat().release();
                }
            }
            else
            {
               
                if(self.uint8Block2)
                {
             
                    cv::Mat reuslt_mat=mat.cvmat().clone();
                
                    
                    UInt8 * reuslt_mat_uint8=nil;
                    if(!reuslt_mat.empty())
                    {
                        reuslt_mat_uint8=[self convertedRawImage:reuslt_mat];
                    }
                    
                   
            
                    self.uint8Block2(reuslt_mat_uint8, mat.width(), mat.height());
                    reuslt_mat.release();
                    mat.cvmat().release();
                }
            }
         
            
            
        }
    
  

}
- (UInt8 *)convertedRawImage:(cv::Mat)image {
  //  double time1=[[NSDate date] timeIntervalSince1970];
    cv::Mat dst;
    cv::cvtColor(image, dst,  cv::COLOR_BGR2BGRA);

    int   m_bit =1;
    int  m_width = dst.cols;
    int m_height = dst.rows;
    int m_channel = 4;//image.channels();
    //printf("===channels %d\n",m_channel);
    int m_stride = m_width*m_channel;
    int   m_size = m_bit*m_stride*m_height;
    UInt8 *convertedRawImage = (UInt8*)calloc(m_size, sizeof(UInt8));
    //int m_ref = 0;
    memcpy(convertedRawImage,dst.data,m_size);
    image.release();
    dst.release();
   // double time2=[[NSDate date] timeIntervalSince1970];
//    NSLog(@"cvtColor:%f",time2-time1);
    return convertedRawImage;
    

}
-(int)processmd5WithPath:(NSString*)inputPath outPath:(NSString*)outPath
{
    //(self->gjdigit,mat.udata(),mat.width(),mat.height(),boxs,index);
    int rst = gjdigit_processmd5(self->gjdigit,0,[inputPath UTF8String],[outPath UTF8String]);
    
    return rst;
    
}
- (void)free {
    if(gjdigit!=nil)
    {
        gjdigit_free(&gjdigit);
    }

}








@end
