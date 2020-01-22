
//  CustomVideoCompositor.h
//  视频叠加
//
//  Created by cc on 2020/1/3.
//  Copyright © 2020 mac. All rights reserved.
//

@import  UIKit;
#import "CustomVideoCompositor.h"

@interface CustomVideoCompositor()

@end

@implementation CustomVideoCompositor

- (instancetype)init
{
    return self;
}

//异步创建一个新的像素缓冲区  以sourceTrackIDs获取对应视频资源
- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request
{
    NSMutableArray *videoArray = [[NSMutableArray alloc] init];
    CVPixelBufferRef destination = [request.renderContext newPixelBuffer];
    
    if (request.sourceTrackIDs.count > 0)
    {
        for (NSUInteger i = 0; i < [request.sourceTrackIDs count]; ++i)
        {
            //获取
            CVPixelBufferRef videoBufferRef = [request sourceFrameByTrackID:[[request.sourceTrackIDs objectAtIndex:i] intValue]];
            if (videoBufferRef)
            {
                [videoArray addObject:(__bridge id)(videoBufferRef)];
            }
        }
        
        for (NSUInteger i = 0; i < [videoArray count]; ++i)
        {
            CVPixelBufferRef video = (__bridge CVPixelBufferRef)([videoArray objectAtIndex:i]);
            CVPixelBufferLockBaseAddress(video, kCVPixelBufferLock_ReadOnly);
        }
        CVPixelBufferLockBaseAddress(destination, 0);
        
        [self renderBuffer:videoArray toBuffer:destination sourceTrackIDs:request.sourceTrackIDs];
        
        CVPixelBufferUnlockBaseAddress(destination, 0);
        for (NSUInteger i = 0; i < [videoArray count]; ++i)
        {
            CVPixelBufferRef video = (__bridge CVPixelBufferRef)([videoArray objectAtIndex:i]);
            CVPixelBufferUnlockBaseAddress(video, kCVPixelBufferLock_ReadOnly);
        }
    }
    NSLog(@"加载中");
    [request finishWithComposedVideoFrame:destination];
    CVBufferRelease(destination);
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext
{
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext
{
    return @{ (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @[ @(kCVPixelFormatType_32BGRA) ] };
}

- (NSDictionary *)sourcePixelBufferAttributes
{
    return @{ (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @[ @(kCVPixelFormatType_32BGRA) ] };
}

#pragma mark - renderBuffer
- (void)renderBuffer:(NSMutableArray *)videoBufferRefArray toBuffer:(CVPixelBufferRef)destination sourceTrackIDs:(NSArray*)sourceTrackIDs
{
    size_t width = CVPixelBufferGetWidth(destination);
    size_t height = CVPixelBufferGetHeight(destination);
    NSMutableArray *imageRefArray = [[NSMutableArray alloc] init];
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    
    for (NSUInteger i = 0; i < [videoBufferRefArray count]; ++i)
    {
        CVPixelBufferRef videoFrame = (__bridge CVPixelBufferRef)([videoBufferRefArray objectAtIndex:i]);
        CGImageRef imageRef = [self createSourceImageFromBuffer:videoFrame];
        bitmapInfo = CGImageGetBitmapInfo(imageRef);
        
        if (imageRef)
        {
            if ([self shouldRightRotate90ByTrackID:i+1])
            {
//                CFAbsoluteTime startTime =CFAbsoluteTimeGetCurrent();
                //旋转 时间在 30-40ms 建议先把竖屏的视频旋转90度 再进行合成
                // Right rotation 90
                imageRef = CGImageRotated(imageRef, videoFrame);
                
//                CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
//                NSLog(@"Linked in %f ms", linkTime *1000.0);
                
            }
            
            [imageRefArray addObject:(__bridge id)(imageRef)];
        }
        CGImageRelease(imageRef);
    }
    
    if ([imageRefArray count] < 1)
    {
        NSLog(@"imageRefArray is empty.");
        return;
    }

    CGContextRef gc = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(destination), width, height, 8, CVPixelBufferGetBytesPerRow(destination), CGColorSpaceCreateDeviceRGB(), bitmapInfo);

    CGFloat cornerRadius = 10;
    for (int i = 0; i < [imageRefArray count]; ++i)
    {
        CGRect frame = [self setVideoRectWithTrackID:[sourceTrackIDs[i] intValue]];
        
        // 以左上角为原点转换y
        frame.origin.y = height - frame.origin.y - CGRectGetHeight(frame);
        
        [self drawImage:frame withContextRef:gc withImageRef:(CGImageRef)imageRefArray[i] withCornerRadius:cornerRadius];
    }
    
    CGContextRelease(gc);
}

#pragma mark - createSourceImageFromBuffer
- (CGImageRef)createSourceImageFromBuffer:(CVPixelBufferRef)buffer
{
    size_t width = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);
    size_t stride = CVPixelBufferGetBytesPerRow(buffer);
    void *data = CVPixelBufferGetBaseAddress(buffer);
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, height * stride, NULL);
    CGImageRef image = CGImageCreate(width, height, 8, 32, stride, rgb, kCGBitmapByteOrder32Host | kCGImageAlphaNoneSkipFirst, provider, NULL, NO, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgb);
    
    return image;
}

#pragma mark - CGImageRotated
CGImageRef CGImageRotated(CGImageRef originalCGImage,CVPixelBufferRef buffer)
{
    
    size_t width = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);

    CIImage *ciimage = [CIImage imageWithCGImage:originalCGImage];
    CIImage *image = [ciimage imageByApplyingCGOrientation:kCGImagePropertyOrientationRight];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef imageRef = [context createCGImage:image fromRect:CGRectMake(0, 0, height,width)];

    return imageRef;
}

#pragma mark - drawImage
- (void)drawImage:(CGRect)frame withContextRef:(CGContextRef)contextRef withImageRef:(CGImageRef)imageRef
{
    CGFloat cornerRadius = 0;
    [self drawImage:frame withContextRef:contextRef withImageRef:imageRef withCornerRadius:cornerRadius];
}

- (void)drawImage:(CGRect)frame withContextRef:(CGContextRef)contextRef withImageRef:(CGImageRef)imageRef withCornerRadius:(CGFloat)cornerRadius
{
    if (!CGRectIsEmpty(frame)){
        CGContextDrawImage(contextRef, frame, imageRef);
    }
}

#pragma mark - NSUserDefaults
//根据旋转角度 是否旋转
- (BOOL)shouldRightRotate90ByTrackID:(NSInteger)trackID
{
    NSString* key = [NSString stringWithFormat:@"videoTrackID_transfrom_%ld",(long)trackID];
    CGAffineTransform transfrom = CGAffineTransformFromString([[NSUserDefaults standardUserDefaults] objectForKey:key]);
    
    if (transfrom.a == 0 && transfrom.b == 1.0 && transfrom.c == -1.0 && transfrom.d == 0) {
        return YES;
    }
    return NO;
}
//获取图层显示frame
- (CGRect)setVideoRectWithTrackID:(int)trackID{
    NSString* key = [NSString stringWithFormat:@"videoTrackID_videoRect_%d",trackID];
    return CGRectFromString([[NSUserDefaults standardUserDefaults] objectForKey:key]);
}


@end
