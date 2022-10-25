#import <UIKit/UIKit.h>
#import "MobileSurfaceViewDelegate.h"

typedef NS_ENUM(NSInteger, ToolbarMode)
{
    TOOLBAR_OPERATORS,
    TOOLBAR_MODES,
    TOOLBAR_USER_CODE
};

class MobileSurface;

// MobileSurfaceView is the UIView which HPS will render into.
// The MobileSurfaceView instance is passed to HPS as the window id.

@interface MobileSurfaceView : UIView

+ (id) mobileSurfaceViewWithXibFile;

- (UIImage *)snapshotImage;

// id used if we wish to create multiple surfaces
@property(nonatomic,assign) int guiSurfaceId;

// Pointer to UserMobileSurface associated with this MobileSurfaceView
@property (nonatomic,assign) MobileSurface * surfacePointer;

//delegate
@property (nonatomic,weak)id<MobileSurfaceViewDelegate>delegate;
@end
