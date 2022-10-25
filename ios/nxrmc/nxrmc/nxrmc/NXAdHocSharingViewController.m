//
//  NXAdHocSharingViewController.m
//  nxrmc
//
//  Created by Kevin on 16/6/13.
//  Copyright © 2016年 nextlabs. All rights reserved.
//

#import "NXAdHocSharingViewController.h"

#import <AddressBookUI/AddressBookUI.h>
#import <AddressBook/AddressBook.h>
#import <MessageUI/MessageUI.h>

#import "CheckBoxView.h"
#import "CLTokenInputView.h"
#import "NXFileLabel.h"
#import "MBProgressHUD.h"

#import "AppDelegate.h"
#import "NXServiceOperation.h"
#import "NXCommonUtils.h"
#import "NXRights.h"
#import "NXMetaData.h"
#import "NXPolicyEngineWrapper.h"
#import "NXSharingAPI.h"
#import "NXLogAPI.h"
#import "NSString+Codec.h"
#import "NXSyncHelper.h"
#import "NXCacheManager.h"
#import "NXLogAPI.h"

#define kControlSpace 8
#define kLabelHeight 30

@interface NXAdHocSharingViewController()<UIGestureRecognizerDelegate, UIDocumentInteractionControllerDelegate, ABPeoplePickerNavigationControllerDelegate,UITableViewDataSource, UITableViewDelegate,MFMailComposeViewControllerDelegate, UIScrollViewDelegate, CLTokenInputViewDelegate, NXServiceOperationDelegate>
@property (strong, nonatomic) id<NXServiceOperation> serviceOperation;
@property (weak, nonatomic) MBProgressHUD *progressView;

@property (weak, nonatomic) CLTokenInputView *tokenView;
@property (weak, nonatomic) CheckBoxView *checkBoxView;
@property (weak, nonatomic) UITableView *tableView;
@property (weak, nonatomic) UIScrollView *scrollView;

@property (weak, nonatomic) UIBarButtonItem *rightButtonItem;

@property (weak, nonatomic) UILabel *fileTitleLabel;
@property (weak, nonatomic) UILabel *filePathLabel;
@property (weak, nonatomic) UILabel *peopleLabel;
@property (weak, nonatomic) UILabel *canLabel;

@property(nonatomic,strong) UIView *shareOptionsView;
//@property (strong, nonatomic) NSLayoutConstraint *checkBoxViewHeightConstraint;
@property (strong, nonatomic) UIButton *addButton;
@property (strong, nonatomic) UIDocumentInteractionController *documentController;

//email address related property
@property (strong, nonatomic) NSArray *filteredNames;
@property (strong, nonatomic) NSMutableArray *promptNames;
@property (strong, nonatomic) NSMutableArray *selectedNames;

@property(nonatomic, strong) NSMutableArray *rightsArray;

@property(nonatomic) BOOL isNXLFile;

@property(nonatomic, strong) NSMutableArray *recipArr;
@property(nonatomic, strong) NSString *attachedFile;

//KeyBoard related issue
@property(nonatomic) float keyboardHeight; //0 means keyboard not show
@property(nonatomic, strong) NSLayoutConstraint *scrollViewBottomConstraint;
@property(nonatomic, strong) NSLayoutConstraint *tableViewBottomConstraint;

@end

@implementation NXAdHocSharingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self commitInit];
    [self initData];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectOrientation:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.checkBoxView.frame = CGRectMake(self.checkBoxView.frame.origin.x, self.checkBoxView.frame.origin.y, self.checkBoxView.frame.size.width, self.checkBoxView.contentSize.height);
    [self updateScrollViews];
}

- (void)viewDidLayoutSubviews {
    [self updateScrollViews];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark 

- (void)initData {
    self.promptNames = [[NSMutableArray alloc] init];
    self.filteredNames = nil;
    self.selectedNames = [[NSMutableArray alloc]init];
    
    [self initPeopleAddressData];
    
    self.isNXLFile = [NXMetaData isNxlFile:self.curFilePath];
    
    if (self.isNXLFile) {
        self.checkBoxView.userInteractionEnabled = NO;
        NSMutableDictionary *obligations;
        NSMutableArray *hitPolicies;
        if (!self.rights) {
            NXRights *rights = nil;
            [[NXPolicyEngineWrapper sharedPolicyEngine] getRights:self.curFilePath username:[NXLoginUser sharedInstance].profile.userName uid:[NXLoginUser sharedInstance].profile.userId rights:&rights obligations:&obligations hitPolicies:&hitPolicies];
            self.rights = rights;
        }
    }
    
    self.rightsArray = [[NSMutableArray alloc]init];
    
    NSMutableArray *contentRights = [NSMutableArray array];
    [[NXRights getSupportedContentRights] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary* element = (NSDictionary*)obj;
        [element enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (self.isNXLFile) {
                CheckBoxCellModel *model = [[CheckBoxCellModel alloc] initWithTitle:key value: [obj longValue] modelType:MODELTYPERIGHTS isChecked:[self.rights getRight:[obj longValue]]];
                [contentRights addObject:model];
                [self.rightsArray addObject:model];
            } else {
                CheckBoxCellModel *model = [[CheckBoxCellModel alloc] initWithTitle:key value: [obj longValue] modelType:MODELTYPERIGHTS isChecked:NO];
                [contentRights addObject:model];
                [self.rightsArray addObject:model];
            }
        }];
    }];
    
    NSMutableArray *collaboratioinRights = [NSMutableArray array];
    [[NXRights getSupportedCollaborationRights] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary* element = (NSDictionary*)obj;
        
        [element enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (self.isNXLFile) {
                CheckBoxCellModel *model = [[CheckBoxCellModel alloc] initWithTitle:key value: [obj longValue] modelType:MODELTYPERIGHTS isChecked:[self.rights getRight:[obj longValue]]];
                [collaboratioinRights addObject:model];
                [self.rightsArray addObject:model];
            } else {
                CheckBoxCellModel *model = [[CheckBoxCellModel alloc] initWithTitle:key value: [obj longValue] modelType:MODELTYPERIGHTS isChecked:NO];
                [collaboratioinRights addObject:model];
                [self.rightsArray addObject:model];
            }
        }];
    }];
    
    NSMutableArray *obsRights = [NSMutableArray array];
    [[NXRights getSupportedObs] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *element = (NSDictionary*)obj;
        
        [element enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (self.isNXLFile) {
                CheckBoxCellModel *model = [[CheckBoxCellModel alloc] initWithTitle:key value: [obj longValue] modelType:MODELTYPEOBS isChecked:[self.rights getObligation:[obj longValue]]];
                [obsRights addObject:model];
                [self.rightsArray addObject:model];
            } else {
                CheckBoxCellModel *model = [[CheckBoxCellModel alloc] initWithTitle:key value: [obj longValue] modelType:MODELTYPEOBS isChecked:NO];
                [obsRights addObject:model];
                [self.rightsArray addObject:model];
            }
        }];
    }];
    
    self.checkBoxView.dataArray = @[contentRights, collaboratioinRights, obsRights];
    self.checkBoxView.titlesArray = @[@"Content:", @"Collaboration:", @"Effect:"];
    
    self.filePathLabel.text = [self.curFile.fullPath lastPathComponent];
    [self.checkBoxView reloadData];
}

- (void)initPeopleAddressData {
    //get all persons's address.
    ABAddressBookRef addBook = ABAddressBookCreateWithOptions(NULL, nil);
    __block BOOL allowAccess = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    ABAddressBookRequestAccessWithCompletion(addBook, ^(bool granted, CFErrorRef error) {
        allowAccess = granted;
        dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    if (!allowAccess) {
//        [NXCommonUtils showAlertView:@"Setting" message:@"please go to setting>general>privacy for " style:UIAlertControllerStyleAlert OKActionTitle:@"O<" cancelActionTitle:@"Cancel" OKActionHandle:^(UIAlertAction *action) {
//            ;
//        } cancelActionHandle:^(UIAlertAction *action) {
//            ;
//        } inViewController:self position:self.view];
        return;
    }
    
    CFArrayRef allPeopleList = ABAddressBookCopyArrayOfAllPeople(addBook);
    CFIndex count = ABAddressBookGetPersonCount(addBook);
    
    for (NSInteger index = 0; index < count; ++index) {
        ABRecordRef people = CFArrayGetValueAtIndex(allPeopleList, index);
        CFTypeRef firstNameTypeRef = ABRecordCopyValue(people, kABPersonFirstNameProperty);
        CFTypeRef lastNameTypeRef = ABRecordCopyValue(people, kABPersonLastNameProperty);
        
        NSString *firstName = (__bridge NSString *)firstNameTypeRef;
        NSString *lastName = (__bridge NSString *)lastNameTypeRef;
        
        NSString *displayName = nil;
        if (firstName.length && lastName.length) {
            displayName = [NSString stringWithFormat:@"%@ %@",lastName, firstName];
        } else if (firstName) {
            displayName = [NSString stringWithFormat:@"%@", firstName];
        } else if (lastName) {
            displayName = [NSString stringWithFormat:@"%@", lastName];
        }
        
        ABMultiValueRef emails = ABRecordCopyValue(people, kABPersonEmailProperty);
        for (NSInteger j = 0; j < ABMultiValueGetCount(emails); j++) {
            CFTypeRef emailTypeRef =  ABMultiValueCopyValueAtIndex(emails, j);
            NSString *email = (__bridge NSString *)emailTypeRef;
            
            if (displayName.length) {
                NXInputModel *model = [[NXInputModel alloc] initWithDisplayText:displayName context:email];
                [self.promptNames addObject:model];
            } else {
                NXInputModel *model = [[NXInputModel alloc] initWithDisplayText:email context:email];
                [self.promptNames addObject:model];
            }
            if (emailTypeRef) {
                CFRelease(emailTypeRef);

            }
        }
        if (firstNameTypeRef) {
            CFRelease(firstNameTypeRef);
        }
        
        if (lastNameTypeRef) {
            CFRelease(lastNameTypeRef);
        }
        
        if (emails) {
             CFRelease(emails);
        }
        
       
    }
    if (allPeopleList) {
        CFRelease(allPeopleList);
    }
    
}

#pragma mark -

- (void)addButtonClicked:(id)sender {
    ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
    peoplePicker.peoplePickerDelegate = self;
    peoplePicker.displayedProperties = @[@(kABPersonEmailProperty)];
    peoplePicker.predicateForEnablingPerson = [NSPredicate predicateWithFormat:@"%K.@count > 0", ABPersonEmailAddressesProperty];
    [self presentViewController:peoplePicker animated:YES completion:nil];
}

- (void)backBarButtonItemClicked:(id)sender {
    [self.view endEditing:YES];
    if (self.presentingViewController) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)rightBarButtonItemClicked:(id)sender {
    [self.view endEditing:YES];
    [self.tokenView endEditing];
    
    self.rightButtonItem.enabled = NO;
    NSMutableArray *emailAddresses = [[NSMutableArray alloc]init];
    for (NXInputModel *model in self.tokenView.allTokens) {
        if ([NXCommonUtils isValidateEmail:model.context]) {
            [emailAddresses addObject:model.context];
        } else {
            [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"Adhoc_SET_EMAIL_INFO_ERROR", NULL)];
            self.rightButtonItem.enabled = YES;
            return;
        }
    }
    
    NXRights* rights = [[NXRights alloc]init];
    
    for (CheckBoxCellModel *model in self.rightsArray) {
        //view edit ...
        if (model.modelType == MODELTYPERIGHTS) {
            if (model.checked) {
                [rights setRight:model.value value:YES];
            } else {
                [rights setRight:model.value value:NO];
            }
        }
        //watermark obligation
        if (model.modelType == MODELTYPEOBS) {
            if (model.checked) {
                [rights setObligation:model.value value:YES];
            } else {
                [rights setObligation:model.value value:NO];
            }
        }
    }

    if ([emailAddresses count] == 0 || [rights getRights] == 0) {

        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"Adhoc_SET_EMAIL_INFO_ERROR", NULL)];
        self.rightButtonItem.enabled = YES;
        return;
    }
    
    if ([NXMetaData isNxlFile: _curFilePath]) {
        __block NSString* owner = nil;
        [NXMetaData getOwner:self.curFilePath complete:^(NSString *ownerId, NSError *error) {
            if (error) {
                NSLog(@"getOwner %@", error);
            }
            owner = ownerId;
        }];
        BOOL isStward = [NXCommonUtils isStewardUser:owner];
        if (isStward || (self.rights && [self.rights SharingRight])) {
            NSDictionary *token = nil;
            NSError* err = nil;
            [NXMetaData getFileToken:self.curFilePath tokenDict:&token error: &err];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (token) {
                    [self shareFile:self.curFilePath emails:emailAddresses token:token permission:[rights getRights]];
                } else {
                    [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:@"Adhoc_GET_NXL_INFO_FAILED"];
                    self.rightButtonItem.enabled = YES;
                    return;
                }
            });
        }
    }
    else
    {  // not nxl file, do encrypt first, and then handle nxl header, like ad-hoc policy
        NSString *tmpPath = [self createNewNxlTempFile:[_curFilePath lastPathComponent]];
        
        UIView *waitingView = [NXCommonUtils createWaitingViewInView:self.view];
        
        [NXMetaData encrypt:_curFilePath destPath:tmpPath complete:^(NSError *error, id appendInfo) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [waitingView removeFromSuperview];
                    [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"Adhoc_ENCRYPT_FILE_FAILED", NULL)];
                    self.rightButtonItem.enabled = YES;
                });
            } else {
                
                // encryption successfully, then try to add ad-hoc sharing policy
                [NXMetaData addAdHocSharingPolicy:tmpPath issuer:[NXLoginUser sharedInstance].profile.defaultMembership.ID rights:rights timeCondition: nil complete:^(NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error == nil) {
                            if (appendInfo && [appendInfo isKindOfClass:[NSDictionary class]]) {
                                [self shareFile:tmpPath emails:emailAddresses token:appendInfo permission:[rights getRights]];
                            }
                        }else {
                            [waitingView removeFromSuperview];
                            [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"Adhoc_ENCRYPT_FILE_FAILED", NULL)];
                            self.rightButtonItem.enabled = YES;
                        }
                    });
                }];
            }
        }];
    }
}

- (void)protectButtonClicked:(id)sender {
    
    if (self.progressView || [NXCommonUtils waitingViewExistInView:self.view]) {
        return;
    }
    self.rightButtonItem.enabled = NO;
    //1, get rights data from UI
    NXRights* rights = [[NXRights alloc]init];
    for (CheckBoxCellModel *model in self.rightsArray) {
        //view edit ...
        if (model.modelType == MODELTYPERIGHTS) {
            if (model.checked) {
                [rights setRight:model.value value:YES];
            } else {
                [rights setRight:model.value value:NO];
            }
        }
        //watermark obligation
        if (model.modelType == MODELTYPEOBS) {
            if (model.checked) {
                [rights setObligation:model.value value:YES];
            } else {
                [rights setObligation:model.value value:NO];
            }
        }
    }
    if ([rights getRights] == 0) {
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"Adhoc_SET_RIGHT_INFO_ERROR", NULL)];
        self.rightButtonItem.enabled = YES;
        return;
    }
    
    //creaet new file name
    NSString *tmpPath = [self createNewNxlTempFile:[_curFilePath lastPathComponent]];
    
    UIView *waitingView = [NXCommonUtils createWaitingViewInView:self.view];
    [NXMetaData encrypt:_curFilePath destPath:tmpPath complete:^(NSError *error, id appendInfo) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [waitingView removeFromSuperview];
                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"Adhoc_ENCRYPT_FILE_FAILED", NULL)];
                self.rightButtonItem.enabled = YES;
            });
        } else {
            // encryption successfully, then try to add ad-hoc sharing policy
            [NXMetaData addAdHocSharingPolicy:tmpPath issuer:[NXLoginUser sharedInstance].profile.defaultMembership.ID rights:rights timeCondition: nil complete:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [waitingView removeFromSuperview];
                    if (error) {
                        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"Adhoc_ENCRYPT_FILE_FAILED", NULL)];
                        self.rightButtonItem.enabled = YES;
                    } else {
                        if (self.isProtectThirdPartyAPPFile) {
                            [self sendToOtherAPP:[NSURL fileURLWithPath:tmpPath]];
                            self.rightButtonItem.enabled = YES;
                        } else {
                            _serviceOperation = [NXCommonUtils createServiceOperation:_curService];
                            [_serviceOperation setDelegate:self];
                            BOOL bRet = [_serviceOperation uploadFile:[tmpPath lastPathComponent] toPath:self.curFile.parent fromPath:tmpPath uploadType:NXUploadTypeNormal overWriteFile:nil];
                            if (!bRet) {
                                self.rightButtonItem.enabled = YES;
                                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"PROTECTERROR_UPLOAD_FAILED", NULL)];
                            } else {
                                [self showProgressView];
                            }
                        }
                    }
                });
            }];
        }
    }];
}

#pragma mark

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    self.keyboardHeight = keyboardRect.size.height;
    
    CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
    [self.scrollView setContentOffset:bottomOffset animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardHeight = 0;
    
    CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
    [self.scrollView setContentOffset:bottomOffset animated:YES];
}

- (void)detectOrientation:(NSNotification *)notifcation {
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        self.tableView.hidden = YES;
    }
    //when protect and upload, the setKeyboardwill not called, so using this method to layoutsubview.
    if (self.type == NXProtectTypeNormal) {
        [self updateScrollViews];
    }
}


- (void)setKeyboardHeight:(float)keyboardHeight {
    _keyboardHeight = keyboardHeight;
    
    [self.view removeConstraint:self.scrollViewBottomConstraint];
    self.scrollViewBottomConstraint.constant = -(self.keyboardHeight + kControlSpace);
    [self.view addConstraint:self.scrollViewBottomConstraint];
    
    [self.view removeConstraint:self.tableViewBottomConstraint];
    self.tableViewBottomConstraint.constant = - (self.keyboardHeight + kControlSpace);
    [self.view addConstraint:self.tableViewBottomConstraint];
    
    [self updateScrollViews];
}

#pragma mark - setting/getting

- (UIButton *)addButton {
    if (_addButton == nil) {
        _addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [_addButton addTarget:self action:@selector(addButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _addButton;
}

- (UIDocumentInteractionController *)documentController {
    if(_documentController == nil)
    {
        _documentController = [[UIDocumentInteractionController alloc]init];
        _documentController.delegate = self;
    }
    return _documentController;
}

- (NSMutableArray *)recipArr {
    if (_recipArr == nil) {
        _recipArr=[NSMutableArray array];
    }
    return _recipArr;
}

#pragma mark - private method.

- (void)updateScrollViews {
    NSLog(@"frame %@",NSStringFromCGRect(self.tokenView.frame));
    float contentHeight = kControlSpace + CGRectGetHeight(self.fileTitleLabel.frame) + kControlSpace + CGRectGetHeight(self.filePathLabel.frame) + kControlSpace + CGRectGetHeight(self.checkBoxView.frame) + kControlSpace + CGRectGetHeight(self.canLabel.frame) + kControlSpace + CGRectGetHeight(self.peopleLabel.frame) + kControlSpace + CGRectGetHeight(self.tokenView.frame);
    if (self.keyboardHeight > 1) {
        float offset = CGRectGetHeight(self.scrollView.frame) - (CGRectGetHeight(self.peopleLabel.frame)  + kControlSpace + CGRectGetHeight(self.tokenView.frame));
        contentHeight = contentHeight + (offset? offset : -offset);
    }
    
    if (contentHeight < CGRectGetHeight(self.scrollView.frame)) {
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame) + 1);
    } else {
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), contentHeight);
    }
}

- (void)showProgressView {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"PROTECT_UPLOADING", NULL);
    hud.mode = MBProgressHUDModeDeterminate;
    hud.removeFromSuperViewOnHide = YES;
    self.progressView = hud;
}

- (void)hiddenProgressView {
    [self.progressView hide:YES];
    self.progressView = nil;
}

#pragma mark  shareOptionsView

- (void) createShareOptionsView {
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)  message:nil preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *emailAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Adhoc_EmailItem", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendEmail];
          }];

    UIAlertAction *moreAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Adhoc_MoreItem", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.documentController.URL = [[NSURL alloc]initFileURLWithPath:self.attachedFile];
        NSString *uti = [NXCommonUtils getUTIForFile:self.attachedFile];
        self.documentController.UTI = uti ? uti : @"public.content";
        [self.documentController presentOptionsMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Adhoc_CancelItem", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       
    }];
    [alertVC addAction:emailAction];
    [alertVC addAction:moreAction];
    [alertVC addAction:cancelAction];
    [self presentViewController:alertVC animated:YES completion:^{
        
    }];
}

#pragma mark send other app
- (NSString *)createNewNxlTempFile:(NSString *)filename {
    NSString *tmpPath = NSTemporaryDirectory();
    tmpPath = [tmpPath stringByAppendingPathComponent:filename];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"-yyyy-MM-dd-hh-mm-ss"];
    
    NSString *datestr = [NSString stringWithString:[dateFormatter stringFromDate:[NSDate date]]];
    NSString *extension = [tmpPath pathExtension];
    
    tmpPath = [[tmpPath stringByDeletingPathExtension] stringByAppendingString:datestr];
    tmpPath = [NSString stringWithFormat:@"%@.%@%@", tmpPath, extension, @".nxl"];
    return tmpPath;
}

- (void)sendToOtherAPP:(NSURL *)fileURL {
    self.documentController.URL = fileURL;
    NSString *uti = [NXCommonUtils getUTIForFile:self.attachedFile];
    self.documentController.UTI = uti ? uti : @"public.content";
    [self.documentController presentOptionsMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

#pragma mark  sendEmail
- (void) sendEmail {
    if (![MFMailComposeViewController canSendMail]) {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"mailto://"]];
    } else {
        MFMailComposeViewController *mailCompose = [[MFMailComposeViewController alloc] init];
        
        [mailCompose setMailComposeDelegate:self];
        NSArray *fileNameCompont = [self.attachedFile componentsSeparatedByString:@"/" ];
        
        
        NSMutableArray *array = [NSMutableArray array];
        for (NSMutableDictionary * dic in self.recipArr) {
            NSString *emailPath = [dic valueForKey:@"email"];
            [array addObject:emailPath];
        }
        
        [mailCompose setToRecipients:array];
        
        NSString *emailContent = [[NSBundle mainBundle]pathForResource:@"Share" ofType:@"html"];
        NSString *htmlPath = [NSString stringWithContentsOfFile:emailContent encoding:NSUTF8StringEncoding error:nil];
        
       
        NSString * subjectStr;
        NSString * nameStr = [NXLoginUser sharedInstance].profile.userName;
        if (!nameStr || nameStr.length == 0) {
                nameStr = [NXLoginUser sharedInstance].profile.email;
        }
        subjectStr = [NSString stringWithFormat:@"%@ has shared %@ with you",nameStr,[fileNameCompont lastObject]];
        
            [mailCompose setSubject:subjectStr];
        NSString * rmcAdress = [NXCommonUtils currentRMSAddress];
        NSString * pictureUrl = [rmcAdress stringByAppendingString:@"/rms-logo.png"];
       
           NSString *htmlStr = [NSString stringWithFormat:htmlPath,pictureUrl,nameStr,[fileNameCompont lastObject]];
        
        NSData *attachmentData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:self.attachedFile isDirectory:YES]];
        [mailCompose addAttachmentData:attachmentData mimeType:@"" fileName:[fileNameCompont lastObject]];
        
        [mailCompose setMessageBody:htmlStr isHTML:YES];
        [self presentViewController:mailCompose animated:YES completion:nil];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
        {
            [self dismissViewControllerAnimated:YES completion:^{
                if (self.navigationController.viewControllers.count == 1) {
                    //present by slide detail view in filelist.
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                } else {
                    //pushed by contentview.
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
            return;
        }
            break;
        case MFMailComposeResultFailed:
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)shareFile:(NSString *)file emails:(NSArray *)emailsAddresses token:(NSDictionary *) token permission:(long) permissions {
    // step1. generate sharing rest and store it
    NSMutableArray *recipientArray = [[NSMutableArray alloc] init];
    
    NSDictionary * recipient = nil;
    if (emailsAddresses.count) {
        for (NSInteger index = 0; index < emailsAddresses.count; ++index) {
            recipient = @{@"email":emailsAddresses[index]};
            [recipientArray addObject:recipient];
        }
    }
    
    NSString *udid = [token allKeys].firstObject;
    
    NSArray *fileNameCompont = [file componentsSeparatedByString:@"/" ];
    NSDictionary *sharedDocumentDic = @{DUID_KEY:udid, MEMBER_SHIP_ID_KEY:[NXLoginUser sharedInstance].profile.defaultMembership.ID,
                                        PERMISSIONS_KEY:[NSNumber numberWithLong:permissions],
                                        METADATA_KEY:@"{}",
                                        FILENAME_KEY:fileNameCompont.lastObject,
                                        RECIPIENTS_KEY:recipientArray};
    NSError *error = nil;
    NSData *recipientsData = [NSJSONSerialization dataWithJSONObject:sharedDocumentDic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *recipientsString = [[NSString alloc] initWithData:recipientsData encoding:NSUTF8StringEncoding];
    NSString *checkSUM = [NXMetaData hmacSha256Token:token[udid] content:recipientsData];
    
    NSDictionary *sharingDic = @{USER_ID_KEY:[NXLoginUser sharedInstance].profile.userId,
                                 TIKECT_KEY:[NXLoginUser sharedInstance].profile.ticket,
                                 DEVICE_ID_KEY:[NXCommonUtils deviceID],
                                 DEVICE_TYPE_KEY:[NXCommonUtils getPlatformId],
                                 CHECK_SUM_KEY:checkSUM,
                                 SHARED_DOC_KEY:recipientsString};
    
    NXSharingAPIRequest *sharingReq = [[NXSharingAPIRequest alloc] init];
    [sharingReq generateRequestObject:sharingDic];
    // cache it
    [[NXSyncHelper sharedInstance] cacheRESTAPI:sharingReq cacheURL:[NXCacheManager getSharingRESTCacheURL]];
    
    
    // create log mode and cache it
    __block NSString *owner = nil;
    [NXMetaData getOwner:file complete:^(NSString *ownerId, NSError *error) {
        if (error) {
            NSLog(@"getOwner %@", error);
        }
        owner = ownerId;
    }];
    
    NXLogAPIRequestModel *model = [[NXLogAPIRequestModel alloc]init];
    model.duid = [[token allKeys] firstObject];
    model.owner = owner;
    model.operation = [NSNumber numberWithInteger:kShareOperation];
    model.repositoryId = @" ";
    model.filePathId = self.curFile.fullServicePath;
    model.accessTime = [NSNumber numberWithLongLong:([[NSDate date] timeIntervalSince1970] * 1000)];
    model.accessResult = [NSNumber numberWithInteger:1];
    model.filePath = self.curFile.fullServicePath;
    model.fileName = self.curFile.name;
    model.activityData = @"";
    NXLogAPI *logAPI = [[NXLogAPI alloc]init];
    [logAPI generateRequestObject:model];
    [[NXSyncHelper sharedInstance] cacheRESTAPI:logAPI cacheURL:[NXCacheManager getLogCacheURL]];
    
    
    // step2. show sharing view
    
    [self createShareOptionsView];
    self.recipArr = recipientArray;
    self.attachedFile = file;
   
    [NXCommonUtils removeWaitingViewInView:self.view];
    
    // step3. upload all cache sharing REST
    [[NXSyncHelper sharedInstance] uploadPreviousFailedRESTRequestWithCachedURL:[NXCacheManager getSharingRESTCacheURL] mustAllSuccess:NO Complection:^(id object, NSError *error) {
        NSLog(@"upload pervious REST");
    }];
    
    [[NXSyncHelper sharedInstance] uploadPreviousFailedRESTRequestWithCachedURL:[NXCacheManager getLogCacheURL] mustAllSuccess:NO Complection:^(id object, NSError *error) {
        NSLog(@"upload log infomation");
    }];
    self.rightButtonItem.enabled = YES;
}

#pragma mark - UIDocumentInteractionControllerDelegate

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
       willBeginSendingToApplication:(NSString *)application {
    NSLog(@"willBeginSendingToApplication");
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
          didEndSendingToApplication:(NSString *)application {
    NSLog(@"didEndSendingToApplication");
}

-(void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    NSLog(@"documentInteractionControllerDidDismissOpenInMenu");
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller {
    NSLog(@"documentInteractionControllerDidDismissOptionsMenu");
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person {
    
    CFTypeRef firstNameTypeRef = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    CFTypeRef lastNameTypeRef = ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    NSString *firstName = (__bridge NSString *)firstNameTypeRef;
    NSString*lastName = (__bridge NSString *)lastNameTypeRef;
    
    NSString *displayName = nil;
    if (firstName.length && lastName.length) {
        displayName = [NSString stringWithFormat:@"%@ %@",lastName, firstName];
    } else if (firstName) {
        displayName = [NSString stringWithFormat:@"%@", firstName];
    } else if (lastName) {
        displayName = [NSString stringWithFormat:@"%@", lastName];
    }
    
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    NXInputModel *selectModel = nil;
    for (NSInteger j = 0; j < ABMultiValueGetCount(emails); j++) {
        CFTypeRef emailTypeRef = ABMultiValueCopyValueAtIndex(emails, j);
        NSString *email = (__bridge NSString *)emailTypeRef;
        
        if (displayName.length) {
            selectModel = [[NXInputModel alloc] initWithDisplayText:displayName context:email];
        } else {
            selectModel = [[NXInputModel alloc] initWithDisplayText:email context:email];
        }
        if (![self.selectedNames containsObject:selectModel]) {
            [self.tokenView addToken:selectModel]; 
        }
        CFRelease(emailTypeRef);
    }
//    CFRelease(firstNameTypeRef);
//    CFRelease(lastNameTypeRef);
    
    CFRelease(emails);
}


#pragma mark - NXServiceOperationDelegate

- (void)uploadFileFinished:(NSString *)servicePath fromPath:(NSString *)localCachePath error:(NSError *)err {
    [self hiddenProgressView];
    self.rightButtonItem.enabled = YES;
    if (err) {
        if(err.code != NXRMC_ERROR_CODE_CANCEL) {
            if (err.localizedDescription) {
                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                                     message:err.localizedDescription];
            } else {
                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                                     message:NSLocalizedString(@"PROTECTERROR_UPLOAD_FAILED", NULL)];
            }
        }
        return;
    }
    
    //do some cache in file system and file cache manager.
    NXFileBase* file;
    for (NXFileBase * child in [_curFile.parent getChildren] ) {
        if ([servicePath isEqualToString: child.fullServicePath]) {
            file = child;
            break;
        }
    }
    if (!file) {
        return;
    }
    
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    //only when this page have navigationcontroller. then open new nxl file. it not, it means it page is open in context menu, we should not open new file.
    if (self.navigationController) {
        [self.navigationController setNavigationBarHidden:NO];
        [app.fileContentVC openFile:file currentService:_curService isOpen3rdAPPFile:NO isOpenNewProtectedFile:YES];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)uploadFileProgress:(CGFloat)progress forFile:(NSString *)servicePath fromPath:(NSString *)localCachePath{
    self.progressView.progress = progress;
    if(progress >= 1.0) {
        self.progressView.labelText = NSLocalizedString(@"PROTECT_UPLOADING_SUCCESS", NULL);
    }
}

#pragma mark - CLTokenInputViewDelegate

- (void)tokenInputView:(CLTokenInputView *)view didChangeText:(NSString *)text {
    if ([text isEqualToString:@""]){
        self.filteredNames = nil;
        self.tableView.hidden = YES;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"displayText contains[cd] %@ OR context contains[cd] %@", text, text];
        self.filteredNames = [self.promptNames filteredArrayUsingPredicate:predicate];
        if (self.filteredNames.count) {
            if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
                self.tableView.hidden = NO;
            }
        } else {
            self.tableView.hidden = YES;
        }
    }
    [self.tableView reloadData];
}

- (void)tokenInputView:(CLTokenInputView *)view didAddToken:(NXInputModel *)token {
    [self.selectedNames addObject:token];
}

- (void)tokenInputView:(CLTokenInputView *)view didRemoveToken:(NXInputModel *)token {
    [self.selectedNames removeObject:token];
}

- (NXInputModel *)tokenInputView:(CLTokenInputView *)view tokenForText:(NSString *)text {
    if (self.filteredNames.count > 0) {
        NSString *matchingName = self.filteredNames[0];
        NXInputModel *match = [[NXInputModel alloc] initWithDisplayText:matchingName context:matchingName];
        return match;
    }
    
    return nil;
}

- (void)tokenInputViewDidEndEditing:(CLTokenInputView *)view {
    view.accessoryView = nil;
}

- (void)tokenInputViewDidBeginEditing:(CLTokenInputView *)view {
    view.accessoryView = self.addButton;
}

- (BOOL)tokenInputViewShouldReturn:(CLTokenInputView *)view {
    self.tableView.hidden = YES;
    return YES;
}

- (void)tokenInputView:(CLTokenInputView *)view didChangeHeightTo:(CGFloat)height {
    [self updateScrollViews];
}


#pragma mark - UITableViewDataSource UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    NXInputModel *model = self.filteredNames[indexPath.row];
    cell.textLabel.text = model.displayText;
    cell.detailTextLabel.text = (NSString *)model.context;
    if ([self.selectedNames containsObject:model]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NXInputModel *model = self.filteredNames[indexPath.row];
    if (![self.selectedNames containsObject:model]) {
         [self.tokenView addToken:model];
    }
}

#pragma mark - UITapGestureRecognizer

- (void)scrollViewClicked:(UIGestureRecognizer *)gestureRecognizer {
    [self.tokenView endEditing:YES];
}

- (void)scrollViewHandleSwipes:(UISwipeGestureRecognizer *)gestureRecoginzer {
    if (gestureRecoginzer.direction == (UISwipeGestureRecognizerDirectionDown)) {
        [self.tokenView endEditing:YES];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.tableView]) {
        return NO;
    }
    return  YES;
}

#pragma mark - UI init

- (void)commitInit {
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(backBarButtonItemClicked:)];
    self.navigationItem.leftBarButtonItem = backItem;
    
    if (self.type == NXProtectTypeNormal) {
        UIBarButtonItem *protectBarItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ACTION_PROTECT", NULL) style:UIBarButtonItemStylePlain target:self action:@selector(protectButtonClicked:)];
        self.navigationItem.rightBarButtonItem = protectBarItem;
        self.rightButtonItem = protectBarItem;
        self.navigationItem.title = NSLocalizedString(@"Adhoc_Protect_Title", NULL);
    } else {
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Adhoc_RIGHT_ITEM_TITLE", NULL) style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonItemClicked:)];
        self.navigationItem.rightBarButtonItem = rightItem;
        self.rightButtonItem = rightItem;
        self.navigationItem.title = NSLocalizedString(@"Adhoc_Sharing_Title", NULL);
    }
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:8.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-8.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:kControlSpace]];
    self.scrollViewBottomConstraint = [NSLayoutConstraint constraintWithItem:scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-(self.keyboardHeight + kControlSpace)];
    [self.view addConstraint:self.scrollViewBottomConstraint];
    
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    
    //Apply Digital Rights to Label
    UILabel *fileTitleLabel = [[UILabel alloc]init];
    fileTitleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    fileTitleLabel.text = NSLocalizedString(@"Adhoc_FilePath", NULL);
    [scrollView addSubview:fileTitleLabel];
    self.fileTitleLabel = fileTitleLabel;
    
    fileTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:fileTitleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeTop multiplier:1 constant:kControlSpace]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:fileTitleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:fileTitleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:fileTitleLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:fileTitleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:kLabelHeight]];
    
    //file path Label
    NXFileLabel *filePathLabel = [[NXFileLabel alloc]init];
    filePathLabel.font = [UIFont systemFontOfSize:14];
    filePathLabel.textAlignment = NSTextAlignmentLeft;
    filePathLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [scrollView addSubview:filePathLabel];
    self.filePathLabel = filePathLabel;
    
    filePathLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:filePathLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:fileTitleLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:kControlSpace]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:filePathLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:filePathLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:filePathLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:kLabelHeight]];
    
    CheckBoxView *checkBoxView = [[CheckBoxView alloc] init];
    [scrollView addSubview:checkBoxView];
    self.checkBoxView = checkBoxView;
    checkBoxView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:checkBoxView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:filePathLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:kControlSpace]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:checkBoxView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:checkBoxView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:checkBoxView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:225]];

    if (self.type == NXProtectTypeNormal) {
        return;
    }
    UILabel *canLabel = [[UILabel alloc] init];
    canLabel.text = NSLocalizedString(@"Adhoc_Can", NULL);
    canLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];;
    [scrollView addSubview:canLabel];
    self.canLabel = canLabel;

    canLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:canLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:checkBoxView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:kControlSpace]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:canLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:canLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:canLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:kLabelHeight]];
    
    //Share the file with Label
    UILabel *peopleLabel = [[UILabel alloc]init];
    peopleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    peopleLabel.text = NSLocalizedString(@"Adhoc_People", NULL);
    [scrollView addSubview:peopleLabel];
    self.peopleLabel = peopleLabel;
    
    peopleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:peopleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:canLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:kControlSpace]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:peopleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:peopleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:peopleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:kLabelHeight]];
    
    
    CLTokenInputView *inputView = [[CLTokenInputView alloc] initWithFrame:CGRectMake(0, 0, 0, 44)];
    [scrollView addSubview:inputView];
    inputView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    inputView.layer.borderWidth = 1;
    self.tokenView = inputView;
    
    inputView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:inputView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:peopleLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:kControlSpace]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:inputView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:inputView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [scrollView addSubview:tableView];
    self.tableView = tableView;
    
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:inputView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:tableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:tableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    self.tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-(self.keyboardHeight + kControlSpace)];
    [self.view addConstraint:self.tableViewBottomConstraint];
    
    //
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] init];
    [singleTap addTarget:self action:@selector(scrollViewClicked:)];
    singleTap.delegate = self;
    [self.scrollView addGestureRecognizer:singleTap];
    
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewHandleSwipes:)];
    swipeGesture.delegate = self;
    swipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self.scrollView addGestureRecognizer:swipeGesture];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.tableView.hidden = YES;
    
    self.tokenView.accessoryView = self.addButton;
    self.tokenView.placeholderText = NSLocalizedString(@"Adhoc_EmailInputPlaceHolder", NULL);
    self.tokenView.drawBottomBorder = YES;
    self.tokenView.delegate = self;
}

@end
