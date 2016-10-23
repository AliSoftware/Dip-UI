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

import Dip

extension DependencyContainer {
  ///Containers that will be used to resolve dependencies of instances, created by stroyboards.
  static public var uiContainers: [DependencyContainer] = []
  
  #if swift(>=3.0)
  /**
   Resolves dependencies of passed in instance.
   Use this method to resolve dependencies of object created by storyboard.
   The type of the instance should be registered in the container.
   
   You should call this method only from implementation of `didInstantiateFromStoryboard(_:tag:)`
   of `StoryboardInstantiatable` protocol if you override its default implementation.
   
   This method will do the same as `resolve(tag:) as T`, but instead of creating 
   a new intance with a registered factory it will use passed in instance as a resolved instance.
   
   - parameters:
      - instance: The object which dependencies should be resolved
      - tag: An optional tag used to register the type (`T`) in the container
   
   **Example**:
   
   ```swift
   class ViewController: UIViewController, ServiceDelegate, StoryboardInstantiatable {
     var service: Service?

     func didInstantiateFromStoryboard(_ container: DependencyContainer, tag: DependencyContainer.Tag?) throws {
       try container.resolveDependencies(of: self as ServiceDelegate, tag: "vc")
     }
   }
   
   class ServiceImp: Service {
     weak var delegate: ServiceDelegate?
   }
   
   container.register(tag: "vc") { ViewController() }
     .resolvingProperties { container, controller in
       controller.service = try container.resolve() as Service
       controller.service.delegate = controller
     }
   
   container.register { ServiceImp() as Service }
   ```
   
   - seealso: `register(_:type:tag:factory:)`, `didInstantiateFromStoryboard(_:tag:)`
   
   */
  public func resolveDependencies<T>(of instance: T, tag: Tag? = nil) throws {
    _ = try resolve(tag: tag) { (_: () throws -> T) in instance }
  }
  #else
  
  /**
   Resolves dependencies of passed in instance.
   Use this method to resolve dependencies of object created by storyboard.
   The type of the instance should be registered in the container.
   
   You should call this method only from implementation of `didInstantiateFromStoryboard(_:tag:)`
   of `StoryboardInstantiatable` protocol if you override its default implementation.
   
   This method will do the same as `resolve(tag:) as T`, but instead of creating
   a new intance with a registered factory it will use passed in instance as a resolved instance.
   
   - parameters:
      - instance: The object which dependencies should be resolved
      - tag: An optional tag used to register the type (`T`) in the container
   
   **Example**:
   
   ```swift
   class ViewController: UIViewController, ServiceDelegate, StoryboardInstantiatable {
     var service: Service?
     
     func didInstantiateFromStoryboard(container: DependencyContainer, tag: DependencyContainer.Tag?) throws {
       try container.resolveDependenciesOf(self as ServiceDelegate, tag: "vc")
     }
   }
   
   class ServiceImp: Service {
     weak var delegate: ServiceDelegate?
   }
   
   container.register(tag: "vc") { ViewController() }
     .resolvingProperties { container, controller in
       controller.service = try container.resolve() as Service
       controller.service.delegate = controller
   }
   
   container.register { ServiceImp() as Service }
   ```
   
   - seealso: `register(_:type:tag:factory:)`, `didInstantiateFromStoryboard(_:tag:)`
   
   */
  public func resolveDependenciesOf<T>(instance: T, tag: Tag? = nil) throws {
    _ = try resolve(tag: tag) { (_: () throws -> T) in instance }
  }
  #endif
}

#if os(watchOS)
  public protocol StoryboardInstantiatableType {}
#else
  public typealias StoryboardInstantiatableType = NSObjectProtocol
#endif

public protocol StoryboardInstantiatable: StoryboardInstantiatableType {
  #if swift(>=3.0)

  /**
   This method will be called if you set a `dipTag` attirbute on the object in a storyboard
   that conforms to `StoryboardInstantiatable` protocol.
   
   - parameters:
      - tag: The tag value, that was set on the object in a storyboard
      - container: The `DependencyContainer` associated with storyboards
   
   The type that implements `StoryboardInstantiatable` protocol should be registered in `UIStoryboard.container`.
   Default implementation of that method calls `resolveDependenciesOf(_:tag:)`
   and pass it `self` instance and the tag.
   
   Usually you will not need to override the default implementation of this method
   if you registered the type of the instance as a concrete type in the container.
   Then you only need to add conformance to `StoryboardInstantiatable`.
   
   You may want to override it if you want to add custom logic before/after resolving dependencies
   or you want to resolve the instance as implementation of some protocol which it conforms to.
   
   - warning: This method will be called after `init?(coder:)` but before `awakeFromNib` method of `NSObject`.
              On watchOS this method will be called before `awakeWithContext(_:)`.
   
   **Example**:
   
   ```swift
   extension MyViewController: SomeProtocol { ... }
   
   extension MyViewController: StoryboardInstantiatable {
     func didInstantiateFromStoryboard(_ container: DependencyContainer, tag: DependencyContainer.Tag) throws {
       //resolve dependencies of the instance as SomeProtocol type
       try container.resolveDependencies(of: self as SomeProtocol, tag: tag)
       //do some additional setup here
     }
   }
   ```
  */
  func didInstantiateFromStoryboard(_ container: DependencyContainer, tag: DependencyContainer.Tag?) throws
  
  #else

  /**
   This method will be called if you set a `dipTag` attirbute on the object in a storyboard
   that conforms to `StoryboardInstantiatable` protocol.
   
   - parameters:
      - tag: The tag value, that was set on the object in a storyboard
      - container: The `DependencyContainer` associated with storyboards
   
   The type that implements `StoryboardInstantiatable` protocol should be registered in `UIStoryboard.container`.
   Default implementation of that method calls `resolveDependenciesOf(_:tag:)`
   and pass it `self` instance and the tag.
   
   Usually you will not need to override the default implementation of this method
   if you registered the type of the instance as a concrete type in the container.
   Then you only need to add conformance to `StoryboardInstantiatable`.
   
   You may want to override it if you want to add custom logic before/after resolving dependencies
   or you want to resolve the instance as implementation of some protocol which it conforms to.
   
   - warning: This method will be called after `init?(coder:)` but before `awakeFromNib` method of `NSObject`.
              On watchOS this method will be called before `awakeWithContext(_:)`.
   
   **Example**:
   
   ```swift
   extension MyViewController: SomeProtocol { ... }
   
   extension MyViewController: StoryboardInstantiatable {
     func didInstantiateFromStoryboard(container: DependencyContainer, tag: DependencyContainer.Tag) throws {
       //resolve dependencies of the instance as SomeProtocol type
       try container.resolveDependenciesOf(self as SomeProtocol, tag: tag)
       //do some additional setup here
     }
   }
   ```
   */
  func didInstantiateFromStoryboard(container: DependencyContainer, tag: DependencyContainer.Tag?) throws
  #endif
}

extension StoryboardInstantiatable {
  #if swift(>=3.0)
  public func didInstantiateFromStoryboard(_ container: DependencyContainer, tag: DependencyContainer.Tag?) throws {
    try container.resolveDependencies(of: self, tag: tag)
  }
  #else
  public func didInstantiateFromStoryboard(container: DependencyContainer, tag: DependencyContainer.Tag?) throws {
    try container.resolveDependenciesOf(self, tag: tag)
  }
  #endif
}

#if os(iOS) || os(tvOS) || os(OSX)
  
#if os(iOS) || os(tvOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif
  
#if swift(>=3.0)
let DipTagAssociatedObjectKey = UnsafeMutablePointer<Int8>.allocate(capacity: 1)
#else
let DipTagAssociatedObjectKey = UnsafeMutablePointer<Int8>.alloc(1)
#endif

extension NSObject {
  
  ///A string tag that will be used to resolve dependencies of this instance
  ///if it implements `StoryboardInstantiatable` protocol.
  private(set) public var dipTag: String? {
    get {
      return objc_getAssociatedObject(self, DipTagAssociatedObjectKey) as? String
    }
    set {
      objc_setAssociatedObject(self, DipTagAssociatedObjectKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
      guard let instantiatable = self as? StoryboardInstantiatable else { return }
      
      let tag = dipTag.map(DependencyContainer.Tag.String)
      
      for container in DependencyContainer.uiContainers {
        do {
          try instantiatable.didInstantiateFromStoryboard(container, tag: tag)
          break
        } catch {
          print(error)
        }
      }
    }
  }
  
}
  
#else
import WatchKit
  
let swizzleAwakeWithContext: Void = {
  #if swift(>=3.0)
    let originalSelector = #selector(WKInterfaceController.awake(withContext:))
    let swizzledSelector = #selector(WKInterfaceController.dip_awake(withContext:))
  #else
    let originalSelector = #selector(WKInterfaceController.awakeWithContext(_:))
    let swizzledSelector = #selector(WKInterfaceController.dip_awakeWithContext(_:))
  #endif
  
  let originalMethod = class_getInstanceMethod(WKInterfaceController.self, originalSelector)
  let swizzledMethod = class_getInstanceMethod(WKInterfaceController.self, swizzledSelector)
  
  let didAddMethod = class_addMethod(WKInterfaceController.self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
  
  if didAddMethod {
    class_replaceMethod(WKInterfaceController.self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod)
  }
}()
  
extension WKInterfaceController: StoryboardInstantiatableType {
  #if swift(>=3.0)
  open override class func initialize() {
    // make sure this isn't a subclass
    guard self == WKInterfaceController.self else { return }
    swizzleAwakeWithContext
  }

  func dip_awake(withContext context: AnyObject?) {
    defer { self.dip_awake(withContext: context) }
    guard let instantiatable = self as? StoryboardInstantiatable else { return }
    
    for container in DependencyContainer.uiContainers {
      guard let _ = try? instantiatable.didInstantiateFromStoryboard(container, tag: nil) else { continue }
      break
    }
  }
  #else
  override class func initialize() {
    // make sure this isn't a subclass
    guard self == WKInterfaceController.self else { return }
    swizzleAwakeWithContext
  }
  
  func dip_awakeWithContext(context: AnyObject?) {
    defer { self.dip_awakeWithContext(context) }
    guard let instantiatable = self as? StoryboardInstantiatable else { return }
    
    for container in DependencyContainer.uiContainers {
      guard let _ = try? instantiatable.didInstantiateFromStoryboard(container, tag: nil) else { continue }
      break
    }
  }
  #endif
}

#endif
