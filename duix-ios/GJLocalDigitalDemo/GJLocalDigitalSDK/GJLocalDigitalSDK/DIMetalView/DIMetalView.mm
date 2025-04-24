//
//  DIMetalView.m
//  Digital
//
//  Created by guiji on 2023/11/17.
//

#import "DIMetalView.h"
//#import "SSZipArchive.h"
#include <opencv2/opencv.hpp>
#import <MetalKit/MetalKit.h>
#import "LYShaderTypes.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "DigitalHumanDriven.h"
// 渲染画面填充模式。
typedef NS_ENUM(NSInteger, JPMetalViewContentMode) {
    // 自动填充满，可能会变形。
    JPMetalViewContentModeStretch = 0,
    // 按比例适配，可能会有黑边。
    JPMetalViewContentModeFit = 1,
    // 根据比例裁剪后填充满。
    JPMetalViewContentModeFill = 2
};
@interface DIMetalView ()<MTKViewDelegate>

// view
@property (nonatomic, strong) MTKView *mtkView;

// data
@property (nonatomic, assign) vector_uint2 viewportSize;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, assign) NSUInteger numVertices;
@property (nonatomic, assign) JPMetalViewContentMode fillMode; // 画面填充模式。


@property (nonatomic, strong) id<MTLTexture> maskTexture;
@property (nonatomic, strong) id<MTLTexture> backTexture;
@property (nonatomic, strong) id<MTLTexture> bfgTexture;
@property (nonatomic, assign)GLuint frame_blending_mode_uniform;
@end
@implementation DIMetalView
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.fillMode=JPMetalViewContentModeFill;
        float height=self.frame.size.height;
        if(self.fillMode==JPMetalViewContentModeStretch || self.fillMode==JPMetalViewContentModeFit)
        {
            height=frame.size.width*16/9;
        }
        self.mtkView = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, height)];
        self.mtkView.device = MTLCreateSystemDefaultDevice(); // 获取默认的device
        NSString *version = [UIDevice currentDevice].systemVersion;
        if(version.doubleValue>=15.0&&version.doubleValue<16.0)
        {
            self.mtkView.preferredFramesPerSecond = 30;
        }
        else
        {
            self.mtkView.preferredFramesPerSecond = 25;
        }
 
        if([DigitalHumanDriven manager].back_type==0)
        {
            self.mtkView.backgroundColor=[UIColor clearColor];
        }
        self.mtkView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0);
        self.mtkView.sampleCount = 1;
        self.mtkView.framebufferOnly = NO;
  
        [self addSubview:self.mtkView];
        self.mtkView.delegate = self;
        self.viewportSize = (vector_uint2){static_cast<unsigned int>(self.mtkView.drawableSize.width), static_cast<unsigned int>(self.mtkView.drawableSize.height)};
        NSLog(@"mtkView=drawableSize==%f,%f",  self.mtkView.drawableSize.width,self.mtkView.drawableSize.height);
        //         CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
        [self customInit];
    }
    return self;
}
-(float)getMetalHeight
{
    return  self.mtkView.frame.size.height;
}
- (void)customInit {
    [self setupPipeline];
    [self setupVertex];
    [self setupTexture];
}
// 设置渲染管道
-(void)setupPipeline {
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"default" ofType:@"metallib"];
    NSLog(@"filePath:%@",filePath);
    NSError *error = nil;
    id<MTLLibrary> defaultLibrary = [self.mtkView.device newLibraryWithFile:filePath error:&error];
 //   id<MTLLibrary> defaultLibrary = [self.mtkView.device newDefaultLibrary]; // .metal
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"]; // 顶点shader，vertexShader是函数名
    NSString * sampleName=@"samplingShader";
    if([DigitalHumanDriven manager].back_type==1)
    {
        sampleName=@"samplingShader2";
    }
    if([DigitalHumanDriven manager].need_png==1)
    {
        sampleName=@"samplingShader3";
    }
    id<MTLFunction> fragmentFunction= [defaultLibrary newFunctionWithName:sampleName]; // 片元shader，samplingShader是函数名
 
    

    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = NO;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation         = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
//    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorSourceColor;
//    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationReverseSubtract;
//    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorBlendAlpha;
//    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorSourceColor;
    self.pipelineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                             error:NULL]; // 创建图形渲染管道，耗性能操作不宜频繁调用
    self.commandQueue = [self.mtkView.device newCommandQueue]; // CommandQueue是渲染指令队列，保证渲染指令有序地提交到GPU
}

- (void)setupVertex
{
    float heightScaling = 1.0;
    float widthScaling = 1.0;
    CGSize currentViewSize=CGSizeMake(self.mtkView.frame.size.width,  self.mtkView.frame.size.height);
    
    CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake([DigitalHumanDriven manager].configModel.width, [DigitalHumanDriven manager].configModel.height), CGRectMake(0, 0, currentViewSize.width, currentViewSize.height));
    switch (_fillMode) {
        case JPMetalViewContentModeStretch: {
            widthScaling = 1.0;
            heightScaling = 1.0;
            break;
        }
        case JPMetalViewContentModeFit: {
            widthScaling = insetRect.size.width / currentViewSize.width;
            heightScaling = insetRect.size.height / currentViewSize.height;
            break;
        }
        case JPMetalViewContentModeFill: {
            widthScaling = currentViewSize.height / insetRect.size.height;
            heightScaling = currentViewSize.width / insetRect.size.width;
            break;
        }
    }
    static const LYVertex quadVertices[] =
    {   // 顶点坐标，分别是x、y、z、w；    纹理坐标，x、y；
        { {  widthScaling, -heightScaling, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -widthScaling, -heightScaling, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -widthScaling,  heightScaling, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  widthScaling, -heightScaling, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -widthScaling,  heightScaling, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  widthScaling,  heightScaling, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    
    self.vertices = [self.mtkView.device newBufferWithBytes:quadVertices
                                                     length:sizeof(quadVertices)
                                                    options:MTLResourceStorageModeShared]; // 创建顶点缓存
    self.numVertices = sizeof(quadVertices) / sizeof(LYVertex); // 顶点个数
}

- (void)setupTexture {
    
    // 纹理描述符
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    NSLog(@"width111:%ld",[DigitalHumanDriven manager].configModel.width);
    textureDescriptor.width =[DigitalHumanDriven manager].configModel.width;
    textureDescriptor.height = [DigitalHumanDriven manager].configModel.height;
    
//    self.texture = [self.mtkView.device newTextureWithDescriptor:textureDescriptor]; // 创建纹理
    
    
    self.maskTexture = [self.mtkView.device newTextureWithDescriptor:textureDescriptor]; // 创建纹理
    
    self.backTexture= [self.mtkView.device newTextureWithDescriptor:textureDescriptor]; // 创建纹理
    
    self.bfgTexture=[self.mtkView.device newTextureWithDescriptor:textureDescriptor]; // 创建纹理
    
}

#pragma mark - delegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewportSize = (vector_uint2){static_cast<unsigned int>(size.width), static_cast<unsigned int>(size.height)};
    
}

- (void)drawInMTKView:(MTKView *)view {
    // 每次渲染都要单独创建一个CommandBuffer
//    MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:MTLCreateSystemDefaultDevice()];
//    NSError* error = nil;
//    id<MTLTexture> backgroundTexture = [textureLoader newTextureWithName:@"background" scaleFactor:1.0 bundle:nil options:nil error:&error];
//    if (error) {
//        NSLog(@"Error loading background texture: %@", error.localizedDescription);
//        return;
//    }
    if(![DigitalHumanDriven manager].isStartSuscess)
    {
        return;
    }
    @autoreleasepool
    {
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    // MTLRenderPassDescriptor描述一系列attachments的值，类似GL的FrameBuffer；同时也用来创建MTLRenderCommandEncoder
    if(renderPassDescriptor != nil)
    {
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0, 0, 0.0f); // 设置默认颜色
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //编码绘制指令的Encoder
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, static_cast<double>(self.viewportSize.x), static_cast<double>(self.viewportSize.y), -1.0, 1.0 }]; // 设置显示区域
        [renderEncoder setRenderPipelineState:self.pipelineState]; // 设置渲染管道，以保证顶点和片元两个shader会被调用
        
        [renderEncoder setVertexBuffer:self.vertices
                                offset:0
                               atIndex:0]; // 设置顶点缓存
        if([DigitalHumanDriven manager].back_type==1)
        {
            [renderEncoder setFragmentTexture:self.backTexture
                                atIndex:LYFragmentTextureIndexGreenTextureY]; // 设置纹理
        }
       
        
//        [renderEncoder setFragmentTexture:self.texture
//                            atIndex:LYFragmentTextureIndexGreenTextureUV]; // 设置纹理
        
        [renderEncoder setFragmentTexture:self.maskTexture
                            atIndex:LYFragmentTextureIndexNormalTextureY]; // 设置纹理
        
        [renderEncoder setFragmentTexture:self.bfgTexture
                            atIndex:LYFragmentTextureIndexNormalTextureUV]; // 设置纹理
//        [renderEncoder setFragmentTexture:self.texture
//                                  atIndex:0]; // 设置纹理
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:self.numVertices]; // 绘制
        
//        [renderEncoder setFragmentTexture:backgroundTexture atIndex:1];
        
        [renderEncoder endEncoding]; // 结束
        
        [commandBuffer presentDrawable:view.currentDrawable]; // 显示
    }
    
    [commandBuffer commit]; // 提交；
        
    }
}
-(cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    //获取图片的CGImageRef结构体
    CGImageRef imageRef = CGImageCreateCopy([image CGImage]);
    //获取图片尺寸
    CGSize size = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    
    //获取图片宽度
    CGFloat cols = size.width;
    //获取图高度
    CGFloat rows = size.height;
    //获取图片颜色空间，创建图片对应Mat对象，需要使用同样的颜色空间
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    
    //判断图片的通道位深及通道数 默认使用8位4通道格式
    int type = CV_8UC4;
    //获取bitmpa位数
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    //获取通道位深
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    //获取通道数
    size_t channels = bitsPerPixel/bitsPerComponent;
    if(channels == 3 || channels == 4){  // 因为quartz框架只支持处理带有alpha通道的数据，所以3通道的图片采取跟4通道的图片一样的处理方式，转化的时候alpha默认会赋最大值，归一化的数值位1.0，这样即使给图片增加了alpha通道，也并不会影响图片的展示
        if(bitsPerComponent == 8){
            //8位3通道 因为iOS端只支持
            type = CV_8UC4;
        }else if(bitsPerComponent == 16){
            //16位3通道
            type = CV_16UC4;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else{
        printf("图片格式不支持");
        abort();
    }
    
    //创建位图信息  根据通道位深及通道数判断使用的位图信息
    CGBitmapInfo bitmapInfo;
    
    if(bitsPerComponent == 8){
        if(channels == 3){
            bitmapInfo = kCGImageAlphaNone | kCGImageByteOrderDefault;
        }else  if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrderDefault;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else if(bitsPerComponent == 16){
        if(channels == 3){  //虽然是三通道，但是iOS端的CGBitmapContextCreate方法不支持16位3通道的创建，所以仍然作为4通道处理
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder16Little;
        }else  if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder16Little;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else{
        printf("图片格式不支持");
        abort();
    }
    
    
    //使用获取到的宽高创建mat对象CV_16UC4 为传入的矩阵类型
    cv::Mat cvMat(rows, cols, type); // 每通道8bit 共有4通道（RGB + Alpha通道 RGBA格式）
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // 数据源
                                                    cols,                       // 每行像素数
                                                    rows,                       // 列数（高度）
                                                    bitsPerComponent,                          // 每个通道bit数
                                                    cvMat.step[0],              // 每行字节数
                                                    colorSpace,                 // 颜色空间
                                                    bitmapInfo); // 位图信息(alpha通道信息，字节读取信息)
    //将图片绘制到上下文中mat对象中
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    //释放imageRef对象
    CGImageRelease(imageRef);
    //释放颜色空间
    CGColorSpaceRelease(colorSpace);
    //释放上下文环境
    CGContextRelease(contextRef);
    return cvMat;
}
- (Byte *)loadImage:(UIImage *)image {
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = image.CGImage;
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    Byte * spriteData = (Byte *) calloc(width * height * 4, sizeof(Byte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    return spriteData;
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
- (void)renderWithMatUInt8:(UInt8*)mat_uint8 :(int)width :(int)height
{
    

        if (mat_uint8) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
            MTLRegion mat_region = {{ 0, 0, 0 }, {static_cast<NSUInteger>(width), static_cast<NSUInteger>(height), 1}}; // 纹理上传的范围
            [self.bfgTexture replaceRegion:mat_region
                            mipmapLevel:0
                              withBytes:mat_uint8
                            bytesPerRow:4 * width];
            free(mat_uint8); // 需要释放资源
            mat_uint8 = NULL;
        }
    
  

}
- (void)renderWithUInt8:(UInt8*)mat_uint8 :(UInt8*)maskMat_uint8 :(UInt8*)bfgMat_uint8 :(UInt8*)bbgMat_unit8 :(int)width :(int)height
{
    

        if (bbgMat_unit8 &&  ([DigitalHumanDriven manager].back_type==1)) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
            MTLRegion back_region = {{ 0, 0, 0 }, {static_cast<NSUInteger>(width), static_cast<NSUInteger>(height), 1}}; // 纹理上传的范围
            [self.backTexture replaceRegion:back_region
                            mipmapLevel:0
                              withBytes:bbgMat_unit8
                            bytesPerRow:4 * width];
            free(bbgMat_unit8); // 需要释放资源
            bbgMat_unit8 = NULL;
        }
    
    if (maskMat_uint8) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
        MTLRegion mask_region = {{ 0, 0, 0 }, {static_cast<NSUInteger>(width), static_cast<NSUInteger>(height), 1}}; // 纹理上传的范围
        [self.maskTexture replaceRegion:mask_region
                        mipmapLevel:0
                          withBytes:maskMat_uint8
                        bytesPerRow:4 * width];
        free(maskMat_uint8); // 需要释放资源
        maskMat_uint8 = NULL;
    }
    if (bfgMat_uint8) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
        MTLRegion bfg_region = {{ 0, 0, 0 }, {static_cast<NSUInteger>(width), static_cast<NSUInteger>(height), 1}}; // 纹理上传的范围
        [self.bfgTexture replaceRegion:bfg_region
                        mipmapLevel:0
                          withBytes:bfgMat_uint8
                        bytesPerRow:4 * width];
        free(bfgMat_uint8); // 需要释放资源
        bfgMat_uint8 = NULL;
    }
    
    if(mat_uint8)
    {
        free(mat_uint8); // 需要释放资源
        mat_uint8 = NULL;
    }

}
- (void)renderWithSimCVMat:(cv::Mat)mat
{
  
    int width=mat.cols;
    int height = mat.rows;
//    dispatch_async(dispatch_get_main_queue(), ^{
       if(!mat.empty())
       {
           Byte *imageBytes = [self convertedRawImage:mat];

           MTLRegion mat_region = {{ 0, 0, 0 }, {static_cast<NSUInteger>(width), static_cast<NSUInteger>(height), 1}}; // 纹理上传的范围
           if (imageBytes) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
               [self.backTexture replaceRegion:mat_region
                               mipmapLevel:0
                                 withBytes:imageBytes
                               bytesPerRow:4 * width];
               free(imageBytes); // 需要释放资源
               imageBytes = NULL;
           }
       }
    mat.release();

//    //背景
  
//    NSLog(@"渲染图片:%f",time2-time1);
}
//IOSurfaceOpenGLESFBOCompatibility
- (void)renderWithCVMat:(cv::Mat)mat :(cv::Mat)maskMat :(cv::Mat)bfgMat :(cv::Mat)bbgMat
{
  
    int width=mat.cols;
    int height = mat.rows;
//    dispatch_async(dispatch_get_main_queue(), ^{
       if(!bbgMat.empty() &&  ([DigitalHumanDriven manager].back_type==1))
       {
           Byte *backimageBytes = [self convertedRawImage:bbgMat];

           MTLRegion back_region = {{ 0, 0, 0 }, {static_cast<NSUInteger>(width), static_cast<NSUInteger>(height), 1}}; // 纹理上传的范围
           if (backimageBytes) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
               [self.backTexture replaceRegion:back_region
                               mipmapLevel:0
                                 withBytes:backimageBytes
                               bytesPerRow:4 * width];
               free(backimageBytes); // 需要释放资源
               backimageBytes = NULL;
           }
       }
       
    //

    //       MTLRegion region = {{ 0, 0, 0 }, {static_cast<NSUInteger>(width), static_cast<NSUInteger>(height), 1}}; // 纹理上传的范围
    //       Byte *imageBytes = [self convertedRawImage:mat];
    //       if (imageBytes) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
    //           [self.texture replaceRegion:region
    //                           mipmapLevel:0
    //                             withBytes:imageBytes
    //                           bytesPerRow:4 * width];
    //           free(imageBytes); // 需要释放资源
    //           imageBytes = NULL;
    //       }

     if(!maskMat.empty())
     {
         //mask
//         cv::Mat dst;
//         cv::cvtColor(maskMat, dst,  cv::COLOR_RGB2GRAY);
         MTLRegion region2 = {{ 0, 0, 0 }, {static_cast<NSUInteger>(width), static_cast<NSUInteger>(height), 1}}; // 纹理上传的范围
         Byte *imageBytes2 = [self convertedRawImage:maskMat];
         if (imageBytes2) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
             [self.maskTexture replaceRegion:region2
                             mipmapLevel:0
                               withBytes:imageBytes2
                             bytesPerRow:4 * width];
             free(imageBytes2); // 需要释放资源
             imageBytes2 = NULL;
         }
     }
        


    if(!bfgMat.empty())
    {
        // 前景
        MTLRegion bfgregion= {{ 0, 0, 0 }, {static_cast<NSUInteger>(width), static_cast<NSUInteger>(height), 1}}; // 纹理上传的范围
        Byte *imageBytes_bfg = [self convertedRawImage:bfgMat];
      
      

        if (imageBytes_bfg) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
            [self.bfgTexture replaceRegion:bfgregion
                            mipmapLevel:0
                              withBytes:imageBytes_bfg
                            bytesPerRow:4 * width];
            free(imageBytes_bfg); // 需要释放资源
            imageBytes_bfg = NULL;
        
        }
    }
    //
        
    mat.release();
    maskMat.release();
    bfgMat.release();
    bbgMat.release();
//    //背景
  
//    NSLog(@"渲染图片:%f",time2-time1);
}
//- (id<MTLTexture>)textureFromMat:(cv::Mat)image {
//
//    int imageCols = image.cols;
//    int imageRows = image.rows;
//
//    UInt8 *convertedRawImage = (UInt8*)calloc(imageRows * image.step * 4, sizeof(UInt8));
//
//    int bytesPerPixel = sizeof(UInt8);
//    int bytesPerRow = (int)(bytesPerPixel * image.step);
//
//    UInt8 b, g, r, a;
//
//    for (int currRow = 0; currRow < imageRows; currRow++) {
//
//        int currRowOffset = (int)image.step.buf[0] * currRow;
//        int convertedRowOffset = bytesPerRow * currRow;
//
//        UInt8* currRowPtr = (UInt8*)(image.data + currRowOffset);
//
//        for (int currCol = 0; currCol < imageCols; currCol++) {
//            b = (UInt8)(currRowPtr[4 * currCol]);
//            g = (UInt8)(currRowPtr[4 * currCol + 1]);
//            r = (UInt8)(currRowPtr[4 * currCol + 2]);
//            a = (UInt8)(currRowPtr[4 * currCol + 3]);
//
//            convertedRawImage[convertedRowOffset + (4 * currCol)] = b;
//            convertedRawImage[convertedRowOffset + (4 * currCol + 1)] = g;
//            convertedRawImage[convertedRowOffset + (4 * currCol + 2)] = r;
//            convertedRawImage[convertedRowOffset + (4 * currCol + 3)] = a;
//        }
//    }
//
//    id<MTLTexture> texture;
//
//    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
//                                                                                          width:imageCols
//                                                                                         height:imageRows
//                                                                                      mipmapped:NO];
//
//    texture = [self.mtkView.device newTextureWithDescriptor:descriptor];
//
//    MTLRegion region = MTLRegionMake2D(0, 0, imageCols, imageRows);
//
//    [texture replaceRegion:region mipmapLevel:0 withBytes:convertedRawImage bytesPerRow:bytesPerRow];
//
//    free(convertedRawImage);
//
//    return texture;
//}
@end
