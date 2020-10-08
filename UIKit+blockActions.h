//
//  UIKit+blockActions.h
//  KBBlockActions
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBarButtonItem (blockActions)

- (instancetype) initWithImage: (UIImage *__nullable) image style: (UIBarButtonItemStyle) style blockTargetHandler: (void (^__unsafe_unretained) (void)) handler;
- (instancetype) initWithTitle: (NSString *__nullable) title style: (UIBarButtonItemStyle) style blockTargetHandler: (void (^__unsafe_unretained) (void)) handler;
- (instancetype) initWithBarButtonSystemItem: (UIBarButtonSystemItem) systemItem blockTargetHandler: (void (^__unsafe_unretained) (void)) handler;

- (id <NSObject>) setBlockTargetWithHandler: (void (^__unsafe_unretained) (void)) handler NS_REFINED_FOR_SWIFT;
- (id <NSObject>) setBlockTargetWithHandlerWithSender: (void (^__unsafe_unretained) (__kindof UIBarButtonItem *sender)) handler NS_REFINED_FOR_SWIFT;
- (id <NSObject>) setBlockTargetWithHandlerWithEvent: (void (^__unsafe_unretained) (__kindof UIBarButtonItem *sender, UIEvent *event)) handler NS_REFINED_FOR_SWIFT;

@end

@interface UIControl (blockActions)

- (id <NSObject>) addBlockTargetForControlEvents: (UIControlEvents) controlEvents handler: (void (^__unsafe_unretained) (void)) handler NS_REFINED_FOR_SWIFT;
- (id <NSObject>) addBlockTargetForControlEvents: (UIControlEvents) controlEvents handlerWithSender: (void (^__unsafe_unretained) (__kindof UIControl *sender)) handler NS_REFINED_FOR_SWIFT;
- (id <NSObject>) addBlockTargetForControlEvents: (UIControlEvents) controlEvents handlerWithEvent: (void (^__unsafe_unretained) (__kindof UIControl *sender, UIEvent *event)) handler NS_REFINED_FOR_SWIFT;

@end

@interface UIGestureRecognizer (blockActions)

- (instancetype) initWithBlockTargetHandler: (void (^__unsafe_unretained) (void)) handler;

- (id <NSObject>) addBlockTargetWithHandler: (void (^__unsafe_unretained) (void)) handler NS_REFINED_FOR_SWIFT;
- (id <NSObject>) addBlockTargetWithHandlerWithSender: (void (^__unsafe_unretained) (__kindof UIGestureRecognizer *sender)) handler NS_REFINED_FOR_SWIFT;
- (id <NSObject>) addBlockTargetWithHandlerWithEvent: (void (^__unsafe_unretained) (__kindof UIGestureRecognizer *sender, UIEvent *event)) handler NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
