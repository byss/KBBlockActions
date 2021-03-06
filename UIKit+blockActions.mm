//
//  UIKit+blockActions.m
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

#import "UIKit+blockActions.h"
#import "ARCOverride.h"

#import <array>
#import <memory>
#import <string>
#import <objc/runtime.h>

template <typename BlockType>
struct HandlerInvocation {
	template <typename ...Args>
	static void invoke (id self, SEL _cmd, Args ...args) {
		((BlockType) self) (args...);
	}
};

template <size_t N>
struct HandlerMethodTypes {
private:
	static constexpr auto getValue () {
		auto const &prevResult = HandlerMethodTypes <N - 1>::value;
		std::array <char, N + 3> result { };
		for (size_t i = 0; i < N + 1; i++) {
			result [i] = prevResult [i];
		}
		result [N + 1] = _C_ID;
		result [N + 2] = '\0';
		return result;
	}

public:
	static std::array <char, N + 3> constexpr value = HandlerMethodTypes::getValue ();
};

template <>
struct HandlerMethodTypes <0> {
public:
	static std::array <char, 3> constexpr value { _C_ID, _C_SEL, '\0' };
};

template <typename ...Args>
struct HandlerMethodInfo {
	SEL const selector = sel_getUid (selectorName ());
	std::array <char, sizeof... (Args) + 3> const &methodTypes = HandlerMethodTypes <sizeof... (Args)>::value;

private:
	static constexpr auto methodTypesArray () {
		std::array <char, sizeof... (Args) + 3> result { _C_ID, _C_SEL };
		
		for (auto it = result.begin () + 2; it < result.end () - 1; it++) {
			*it = _C_ID;
		}
		result [sizeof... (Args) + 2] = '\0';
		return result;
	}
	
	static constexpr auto selectorName () {
		constexpr std::array <char const *, 3> selectorNames = {
			"$handleAction",
			"$handleActionForSender:",
			"$handleActionForSender:withEvent:",
		};
		return std::get <sizeof... (Args)> (selectorNames);
	}
};

template <typename Sender, typename AssociatedActions>
struct SenderWrapper {
	SenderWrapper (Sender *const self): self (self) {}
	
protected:
	template <typename ...Args>
	using BlockType = void (^) (Args...);

	struct Swizzler {
		inline Swizzler (SEL const selector) {
			SEL const swizzledSelector = sel_getUid ((std::string ("_kb_swizzled_") + sel_getName (selector)).c_str ());
			Method const originalMethod = class_getInstanceMethod ([Sender class], selector);
			Method const swizzledMethod = class_getInstanceMethod ([Sender class], swizzledSelector);
			method_exchangeImplementations (originalMethod, swizzledMethod);
		}
	};
	
	template <typename ...Args>
	id <NSObject> makeBlockTarget (BlockType <Args...> __unsafe_unretained handler, std::function <void (id const target, SEL const selector)> resultHandler) const {
		using Invocation = HandlerInvocation <BlockType <Args...>>;
		using MethodInfo = HandlerMethodInfo <Args...>;

		__unsafe_unretained Class const handlerClass = [handler class];
		MethodInfo const methodInfo;
		SEL const selector = methodInfo.selector;
		if (!class_respondsToSelector (handlerClass, selector)) {
			void (*invokeImp) (id, SEL, Args...) = &Invocation::invoke;
			class_addMethod (handlerClass, selector, (IMP) invokeImp, methodInfo.methodTypes.data ());
		}
		
		__unsafe_unretained id const target = kb_block_copy (handler);
		resultHandler (target, selector);
		kb_objc_release (target);
		return target;
	}
	
	AssociatedActions const assocciatedActions () const {
		return objc_getAssociatedObject (self, associationKey);
	}
	
	void setAssocciatedActions (AssociatedActions const newActions) const {
		objc_setAssociatedObject (self, associationKey, newActions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	Sender *const self;

private:
	static constexpr void const *const associationKey = "actions";
};

template <typename Sender>
struct MultiTargetsSenderWrapper: public SenderWrapper <Sender, NSMutableSet *> {
	MultiTargetsSenderWrapper (Sender *const self): SenderWrapper <Sender, NSMutableSet *> (self) {}
	
protected:
	void storeBlockTarget (CF_CONSUMED id const target) const {
		NSMutableSet *blockActions = this->assocciatedActions ();
		if (blockActions) {
			[blockActions addObject:target];
		} else {
			blockActions = [[NSMutableSet alloc] initWithObjects:&target count:1];
			this->setAssocciatedActions (blockActions);
		}
	}
	
	void removeBlockTargetIfNeeded (id const target, NSSet *allTargets = nil) const {
		if (!target) {
			return;
		}
		NSMutableSet *blockTargets = this->assocciatedActions ();
		if ([blockTargets containsObject:target] && ![allTargets containsObject:target]) {
			[blockTargets removeObject:target];
		}
	}
};

struct UIBarButtonItemWrapper: public SenderWrapper <UIBarButtonItem, id> {
	UIBarButtonItemWrapper (UIBarButtonItem *self): SenderWrapper (self) {}
	
	template <typename ...Args>
	id <NSObject> addTarget (BlockType <Args...> __unsafe_unretained handler) const {
		static auto const __used swizzler = Swizzler (@selector (setTarget:));
		
		return this->makeBlockTarget (handler, [&] (id const target, SEL const selector) {
			this->setAssocciatedActions (target);
			
			self.target = target;
			self.action = selector;
		});
	}

	void removeBlockTargetIfNeeded (id const target) const {
		id const blockTarget = this->assocciatedActions ();
		if (blockTarget != self.target) {
			this->setAssocciatedActions (nil);
		}
	}
};

@implementation UIBarButtonItem (blockAction)

- (instancetype) initWithImage: (UIImage *__nullable) image style: (UIBarButtonItemStyle) style blockTargetHandler: (void (^__unsafe_unretained) (void)) handler {
	if (self = [self initWithImage:image style:style target:nil action:NULL]) {
		[self setBlockTargetWithHandler:handler];
	}
	return self;
}

- (instancetype) initWithTitle: (NSString *__nullable) title style: (UIBarButtonItemStyle) style blockTargetHandler: (void (^__unsafe_unretained) (void)) handler {
	if (self = [self initWithTitle:title style:style target:nil action:NULL]) {
		[self setBlockTargetWithHandler:handler];
	}
	return self;
}

- (instancetype) initWithBarButtonSystemItem: (UIBarButtonSystemItem) systemItem blockTargetHandler: (void (^__unsafe_unretained) (void)) handler {
	if (self = [self initWithBarButtonSystemItem:systemItem target:nil action:NULL]) {
		[self setBlockTargetWithHandler:handler];
	}
	return self;
}

- (id <NSObject>) setBlockTargetWithHandler: (void (^__unsafe_unretained) (void)) handler {
	return UIBarButtonItemWrapper (self).addTarget (handler);
}

- (id <NSObject>) setBlockTargetWithHandlerWithSender: (void (^__unsafe_unretained) (__kindof UIBarButtonItem *sender)) handler {
	return UIBarButtonItemWrapper (self).addTarget (handler);
}

- (id <NSObject>) setBlockTargetWithHandlerWithEvent: (void (^__unsafe_unretained) (__kindof UIBarButtonItem *sender, UIEvent *event)) handler {
	return UIBarButtonItemWrapper (self).addTarget (handler);
}

- (void) _kb_swizzled_setTarget: (id) target {
	[self _kb_swizzled_setTarget:target];
	UIBarButtonItemWrapper (self).removeBlockTargetIfNeeded (target);
}

@end


struct UIControlWrapper: public MultiTargetsSenderWrapper <UIControl> {
	UIControlWrapper (UIControl *self): MultiTargetsSenderWrapper (self) {}
	
	template <typename ...Args>
	id <NSObject> addTarget (BlockType <Args...> __unsafe_unretained handler, UIControlEvents controlEvents) const {
		static auto const __used swizzler = Swizzler (@selector (removeTarget:action:forControlEvents:));

		return this->makeBlockTarget (handler, [&] (id const target, SEL const selector) {
			[self addTarget:target action:selector forControlEvents:controlEvents];
			this->storeBlockTarget (target);
		});
	}
	
	void removeBlockTargetIfNeeded (id const target) const {
		MultiTargetsSenderWrapper::removeBlockTargetIfNeeded (target, self.allTargets);
	}
};

@implementation UIControl (blockActions)

- (id <NSObject>) addBlockTargetForControlEvents: (UIControlEvents) controlEvents handler: (void (^__unsafe_unretained)(void)) handler {
	return UIControlWrapper (self).addTarget (handler, std::move (controlEvents));
}

- (id <NSObject>) addBlockTargetForControlEvents: (UIControlEvents) controlEvents handlerWithSender: (void (^__unsafe_unretained)(__kindof UIControl *)) handler {
	return UIControlWrapper (self).addTarget (handler, std::move (controlEvents));
}

- (id <NSObject>) addBlockTargetForControlEvents: (UIControlEvents) controlEvents handlerWithEvent: (void (^__unsafe_unretained)(__kindof UIControl *, UIEvent *)) handler {
	return UIControlWrapper (self).addTarget (handler, std::move (controlEvents));
}

- (void) _kb_swizzled_removeTarget: (id) target action: (SEL) action forControlEvents: (UIControlEvents) controlEvents {
	[self _kb_swizzled_removeTarget:target action:action forControlEvents:controlEvents];
	return UIControlWrapper (self).removeBlockTargetIfNeeded (target);
}

@end

struct UIGestureRecognizerWrapper: public MultiTargetsSenderWrapper <UIGestureRecognizer> {
	UIGestureRecognizerWrapper (UIGestureRecognizer *self): MultiTargetsSenderWrapper (self) {}
	
	template <typename ...Args>
	id <NSObject> addTarget (BlockType <Args...> __unsafe_unretained handler) const {
		static auto const __used swizzler = Swizzler (@selector (removeTarget:action:));

		return this->makeBlockTarget (handler, [&] (id const target, SEL const selector) {
			[self addTarget:target action:selector];
			this->storeBlockTarget (target);
		});
	}
	
	void removeBlockTargetIfNeeded (id const target) const {
		MultiTargetsSenderWrapper::removeBlockTargetIfNeeded (target);
	}
};

@implementation UIGestureRecognizer (blockActions)

- (instancetype) initWithBlockTargetHandler: (void (^__unsafe_unretained) (void)) handler {
	if (self = [self init]) {
		[self addBlockTargetWithHandler:handler];
	}
	return self;
}

- (id <NSObject>) addBlockTargetWithHandler: (void (^__unsafe_unretained) (void)) handler {
	return UIGestureRecognizerWrapper (self).addTarget (handler);
}

- (id <NSObject>) addBlockTargetWithHandlerWithSender: (void (^__unsafe_unretained) (__kindof UIGestureRecognizer *sender)) handler {
	return UIGestureRecognizerWrapper (self).addTarget (handler);
}

- (id <NSObject>) addBlockTargetWithHandlerWithEvent: (void (^__unsafe_unretained) (__kindof UIGestureRecognizer *sender, UIEvent *event)) handler {
	return UIGestureRecognizerWrapper (self).addTarget (handler);
}

- (void) _kb_swizzled_removeTarget: (id) target action: (SEL) action {
	[self _kb_swizzled_removeTarget:target action:action];
	return UIGestureRecognizerWrapper (self).removeBlockTargetIfNeeded (target);
}

@end
