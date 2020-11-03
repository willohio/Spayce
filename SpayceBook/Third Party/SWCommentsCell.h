//
//  SWCommentsCell.h
//  Spayce
//
//  Created by Christopher Taylor on 6/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SWTableViewCell.h"
#import "Comment.h"
#import "STTweetLabel.h"

@class Asset;

@interface SWCommentsCell : SWTableViewCell
{
    int starCount;
}

@property (nonatomic,retain) UILabel *commenterNameLbl;
@property (nonatomic,retain) UILabel *timeLbl;
@property (nonatomic, retain) STTweetLabel *commentLbl;
@property (nonatomic,retain) UIView *separatorLine;
@property (nonatomic, strong) UIButton *starBtn;
@property (nonatomic, strong) UIImageView *starIcon;
@property (nonatomic, strong) UILabel *starLbl;
@property (nonatomic, assign) BOOL userHasStarred;
@property (nonatomic, assign) NSInteger commentId;
@property (nonatomic, strong) Comment *currComment;
@property (nonatomic, strong) NSArray *taggedUserNames;
@property (nonatomic, strong) NSArray *taggedUserTokens;
@property (nonatomic, strong) NSArray *taggedUserIDs;
@property (nonatomic, copy) void (^taggedUserTappedBlock)(NSString *userToken);
@property (nonatomic, copy) void (^hashTagTappedBlock)(NSString *hashTag);
@property (nonatomic, strong) UIButton *imageButton;


- (void)configureWithCleanComment:(Comment *)comment tag:(NSInteger)tag isCurrentUser:(BOOL)isCurrentUser;

+ (CGFloat)cellHeightForCommentText:(NSString *)commentText;

@end
