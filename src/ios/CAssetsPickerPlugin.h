//
//  CAssetsPickerPlugin.h
//  AssetsPlugin
//
//  Created by Donald Pae on 4/22/14.
//
//

#import <Cordova/CDVPlugin.h>
#import "CTAssetsPickerController.h"

typedef enum {
    DestinationTypeDataURL = 0,
    DestinationTypeFileURI = 1
}DestinationType;

typedef enum {
    EncodingTypeJPEG = 0,
    EncodingTypePNG = 1
}EncodingType;

// return value
#define kIdKey      @"id"
#define kUuidKey    @"uuid"
#define kOrigExtKey @"orig_ext"
#define kLabelKey   @"label"
#define kDataKey    @"data"
#define kExifKey    @"exif"
#define kDateTimeOriginalKey    @"DateTimeOriginal"
#define kPixelXDimensionKey      @"PixelXDimension"
#define kPixelYDimensionKey     @"PixelYDimension"
#define kOrientationKey         @"Orientation"
#define kCorrectOrientation     @"correctOrientation"
#define kBookmarks              @"bookmarks"
#define kBookmarksDate          @"date"
#define kPluckKey               @"pluck"
#define kFromDateKey            @"fromDate"
#define kToDateKey              @"toDate"
#define kLastDateKey            @"lastDate"
#define kAssetsKey              @"assets"

#define DATETIME_FORMAT @"yyyy-MM-dd HH:mm:ss"
#define DATE_FORMAT @"yyyy-MM-dd"

#define DATETIME_JSON_FORMAT @"yyyy-MM-dd'T'HH:mm:ss.SSS"

// parameter
#define kQualityKey         @"quality"
#define kDestinationTypeKey @"destinationType"
#define kEncodingTypeKey    @"encodingType"
#define kTargetWidth        @"targetWidth"
#define kTargetHeight       @"targetHeight"
#define kOverlayKey         @"overlay"

#define kPreviousSelectedName   @"previousSelected"


@interface CAssetsPickerPlugin : CDVPlugin <UINavigationControllerDelegate, CTAssetsPickerControllerDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) CTAssetsPickerController *picker;
@property (strong, nonatomic) CDVInvokedUrlCommand* latestCommand;
@property (readwrite, assign) BOOL hasPendingOperation;
@property (nonatomic, strong) UIPopoverController *popover;

- (void)getPicture:(CDVInvokedUrlCommand *)command;
- (void)getById:(CDVInvokedUrlCommand *)command;
- (void)setOverlay:(CDVInvokedUrlCommand *)command;
- (void)getPreviousAlbums:(CDVInvokedUrlCommand *)command;
- (void)mapAssetsLibrary:(CDVInvokedUrlCommand *)command;



+ (NSString *)date2str:(NSDate *)convertDate withFormat:(NSString *)formatString;
+ (UIImage *)scaleImage:(UIImage *)image scale:(CGFloat)scale;
+ (NSString *)getAppPath;
+ (NSString *)getFilePath:(NSString *)uuidString ext:(NSString *)ext;
+ (NSURL *)getUrlFromUrlString:(NSString *)urlString;
+ (NSString *)getUrlStringWithUuid:(NSString *)uuid ext:(NSString *)ext;
@end
