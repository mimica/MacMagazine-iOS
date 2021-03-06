#import <SDWebImage/UIImageView+WebCache.h>

#import "MMMPostPresenter.h"
#import "GTMNSString+HTML.h"
#import "MMMFeaturedPostTableViewCell.h"
#import "MMMPost.h"
#import "MMMPostTableViewCell.h"
#import "NSDate+Formatters.h"
#import "NSString+HTMLSafe.h"

#pragma mark MMMPostPresenter

@implementation MMMPostPresenter

#pragma mark - Gettes/Setters

- (MMMPost *)post {
    return self.object;
}

#pragma mark - Instance Methods

- (void)downloadImageForImageView:(UIImageView *)imageView {
    NSURL *URL = [self thumbnailURLForImageView:imageView];
    [imageView sd_setImageWithURL:URL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        // hack to disable SDWebImage's GIF support (SD GIF implementation is basically broken):
        // https://github.com/rs/SDWebImage/issues/501
        // this avoids a fork ¯\_(ツ)_/¯
        if (image.images) {
            image = [UIImage imageWithCGImage:[image.images.firstObject CGImage]];
            imageView.image = image;
        }
        NSTimeInterval duration = (cacheType != SDImageCacheTypeMemory) ? 0.25 : 0;
        UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseInOut;
        [UIView animateWithDuration:duration delay:0 options:options animations:^{
            imageView.alpha = 1;
        } completion:nil];
    }];
}

- (void)setupMMMFeaturedPostTableViewCell:(MMMFeaturedPostTableViewCell *)cell {
    cell.headlineLabel.text = self.post.title;
    cell.subheadlineLabel.text = self.descriptionText;
    cell.thumbnailImageView.alpha = 0;
    [self downloadImageForImageView:cell.thumbnailImageView];
}

- (void)setupMMMPostTableViewCell:(MMMPostTableViewCell *)cell {
    cell.imageVisible = (self.post.thumbnail.length > 0);
    cell.headlineLabel.text = self.post.title;
    cell.subheadlineLabel.text = self.descriptionText;
    cell.thumbnailImageView.alpha = 0;
    [self downloadImageForImageView:cell.thumbnailImageView];
}

#pragma mark - Attributes

- (NSString *)descriptionText {
    return [self.post.descriptionText.mmm_htmlSafe gtm_stringByUnescapingFromHTML];
}

- (NSURL *)thumbnailURLForImageView:(UIImageView *)imageView {
    NSString *thumbnail = self.post.thumbnail;
    if (!thumbnail) {
        return nil;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat width = CGRectGetWidth(imageView.frame) * scale;
    
    if (![thumbnail containsString:@"wp.com"] || width == 0) {
        return [NSURL URLWithString:thumbnail];
    }
    
    thumbnail = [thumbnail stringByAppendingFormat:@"?w=%.f", width * scale];
    return [NSURL URLWithString:thumbnail];
}

- (nullable NSString *)sectionTitle {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    if ([calendar isDateInToday:self.post.pubDate]) {
        return NSLocalizedString(@"Date.Today", @"").uppercaseString;
    } else if ([calendar isDateInYesterday:self.post.pubDate]) {
        return NSLocalizedString(@"Date.Yesterday", @"").uppercaseString;
    } else {
        return [self.post.pubDate mmm_stringFromTemplate:@"EEEEddMMMM"].uppercaseString;
    }
}

@end
