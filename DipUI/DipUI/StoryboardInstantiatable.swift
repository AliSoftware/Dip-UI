//
// DipUI
//
// Copyright (c) 2016 Ilya Puchka <ilyapuchka@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#if os(iOS) || os(tvOS)
  import UIKit
  typealias Storyboard = UIStoryboard
  typealias Responder = UIResponder
#else
  import AppKit
  typealias Storyboard = NSStoryboard
  typealias Responder = NSResponder
#endif

import Dip

public protocol StoryboardInstantiatable {
  func instantiatedFromStoryboard(withTag tag: DependencyContainer.Tag, container: DependencyContainer)
}

extension StoryboardInstantiatable {
  public func instantiatedFromStoryboard(withTag tag: DependencyContainer.Tag, container: DependencyContainer) {
    do {
      try container.resolveDependenciesOf(self, forTag: tag)
    }
    catch {
      print(error)
    }
  }
}

extension Storyboard {
  ///Container that will be used to resolve _dependencies of components_, created by stroyboard.
  static public var container: DependencyContainer?
}

extension NSObject {
  
  private struct AssociatedTags {
    private static var dipTag = 0
  }
  
  @IBInspectable private(set) public var dipTag: String? {
    get {
      return objc_getAssociatedObject(self, &AssociatedTags.dipTag) as? String
    }
    set {
      objc_setAssociatedObject(self, &AssociatedTags.dipTag, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
      
      if let key = newValue, container = Storyboard.container {
        let tag = DependencyContainer.Tag.String(key)
        if let instantiatable = self as? StoryboardInstantiatable {
          instantiatable.instantiatedFromStoryboard(withTag: tag, container: container)
        }
      }
    }
  }
  
}

