//
//  UIKit+blockActions.swift
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

import UIKit

public protocol UIBarButtonItemBlockTargetProtocol {}

extension UIBarButtonItemBlockTargetProtocol where Self: UIBarButtonItem {
	public func setBlockTarget (handler: @escaping () -> ()) -> NSObjectProtocol {
		return self.__setBlockTargetWithHandler (handler);
	}

	public func setBlockTarget (handler: @escaping (Self) -> ()) -> NSObjectProtocol {
		return self.__setBlockTargetWithHandlerWithSender (Self.convertingHandler (handler));
	}

	public func setBlockTarget (handler: @escaping (Self, UIEvent) -> ()) -> NSObjectProtocol {
		return self.__setBlockTargetWithHandlerWithEvent (Self.convertingHandler (handler));
	}
}

extension UIBarButtonItem: UIBarButtonItemBlockTargetProtocol {}

public protocol UIControlBlockTargetProtocol {}

extension UIControlBlockTargetProtocol where Self: UIControl {
	@discardableResult
	public func addBlockTarget (for controlEvents: Event, handler: @escaping () -> ()) -> NSObjectProtocol {
		return self.__addBlockTarget (for: controlEvents, handler: handler);
	}

	@discardableResult
	public func addBlockTarget (for controlEvents: UIControl.Event, handler: @escaping (Self) -> ()) -> NSObjectProtocol {
		return self.__addBlockTarget (for: controlEvents, handlerWithSender: Self.convertingHandler (handler));
	}
	
	@discardableResult
	public func addBlockTarget (for controlEvents: UIControl.Event, handler: @escaping (Self, UIEvent) -> ()) -> NSObjectProtocol {
		return self.__addBlockTarget (for: controlEvents, handlerWithEvent: Self.convertingHandler (handler));
	}
}

extension UIControl: UIControlBlockTargetProtocol {}

public protocol UIIGestureRecognizerBlockTargetProtocol {}

extension UIIGestureRecognizerBlockTargetProtocol where Self: UIGestureRecognizer {
	@discardableResult
	public func addBlockTarget (handler: @escaping () -> ()) -> NSObjectProtocol {
		return self.__addBlockTarget (handler: handler);
	}
	
	@discardableResult
	public func addBlockTarget (handler: @escaping (Self) -> ()) -> NSObjectProtocol {
		return self.__addBlockTargetWithHandler (sender: Self.convertingHandler (handler));
	}
	
	@discardableResult
	public func addBlockTarget (handler: @escaping (Self, UIEvent) -> ()) -> NSObjectProtocol {
		return self.__addBlockTargetWithHandler (event: Self.convertingHandler (handler));
	}
}

extension UIGestureRecognizer: UIIGestureRecognizerBlockTargetProtocol {}

private protocol KBTargetActionBlockConverting: AnyObject {}

/* private */ extension KBTargetActionBlockConverting {
	fileprivate static func convertingHandler <T> (_ handler: @escaping (Self) -> ()) -> (T) -> () where T: AnyObject {
		return { handler (unsafeDowncast ($0, to: Self.self)) };
	}
	
	fileprivate static func convertingHandler <T> (_ handler: @escaping (Self, UIEvent) -> ()) -> (T, UIEvent) -> () where T: AnyObject {
		return { handler ($0 as! Self, $1) };
	}
}

extension UIBarButtonItem: KBTargetActionBlockConverting {}
extension UIControl: KBTargetActionBlockConverting {}
extension UIGestureRecognizer: KBTargetActionBlockConverting {}
