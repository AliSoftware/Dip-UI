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

  /**
   Resolves dependencies of passed in instance.
   Use this method to resolve dependencies of object created by storyboard.
   The type of the instance should be registered in the container.
   
   You should call this method only when you override default implementation of
   `didInstantiateFromStoryboard(withTag:container:)` of `StoryboardInstantiatable` protocol.

   This method will do the same as `resolve(tag:)`, but instead of creating new intance
   it will use passed in instance as resolved instance.
   
   - parameters:
      - instance: The object which dependencies should be resolved
      - tag: An optional tag used to register the type (`T`) in the container
   
   **Example**:
   
   ```swift
   class ViewController: UIViewController, ServiceDelegate {
     var service: Service?
   }
   
   container.register(tag: "vc") { ViewController() }
     .resolveDependencies { container, controller in
       controller.service = try container.resolve() as Service
       controller.service.delegate = controller
   }

   class ServiceImp: Service {
     weak var delegate: ServiceDelegate?
   }

   container.register { ServiceImp() as Service }
   
   let controller = ...
   container.resolveDependencies(controller, forTag: "vc")
   //controller.service?.delegate === controller
   ```
   
   - seealso: `register(tag:_:factory:)`, `didInstantiateFromStoryboard(withTag:container:)`
   
   */
  public func resolveDependenciesOf<T>(instance: T, forTag tag: Tag? = nil) throws {
    try resolve(tag: tag) { (factory: () throws -> T) in instance }
  }
  
}

public protocol StoryboardInstantiatable {
  
  /**
   This method will be called if you set a `dipTag` attirbute on the object in a storyboard.
   
   - parameters:
      - tag: The tag value, that was set on the object in a storyboard
      - container: The `DependencyContainer` associated with storyboards

   The type that implements this protocol should be registered in `UIStoryboard.container`.
   Default implementation of that method calls `resolveDependenciesOf(_:forTag:)`
   and pass it `self` instance and the tag.

   Usually you will not need to override the default implementation of this method
   if you registered the type of the instance as a concret type in the container.
   Then you only need to add conformance to `StoryboardInstantiatable`.

   You may want to override it if you want to add custom logic before/after resolving dependencies
   or you want to resolve the instance as implementation of some protocol which it conforms to.
   
   - warning: This method will be called after `init?(coder:)` but before `awakeFromNib` method.
              Thus the instance may be not completely setup yet.

   **Example**:
   
   ```swift
   extension MyViewController: SomeProtocol { ... }
   
   extension MyViewController: StoryboardInstantiatable {
     func didInstantiateFromStoryboard(withTag tag: DependencyContainer.Tag, container: DependencyContainer) {
       //resolve dependencies of the instance as SomeProtocol type
       try! container.resolveDependenciesOf(self as SomeProtocol, forTag: tag)
       //do some additional setup here
     }
   }
   ```
   
  */
  func didInstantiateFromStoryboard(withTag tag: DependencyContainer.Tag, container: DependencyContainer)
}

extension StoryboardInstantiatable {
  public func didInstantiateFromStoryboard(withTag tag: DependencyContainer.Tag, container: DependencyContainer) {
    do {
      try container.resolveDependenciesOf(self, forTag: tag)
    }
    catch {
      print(error)
    }
  }
}

extension DependencyContainer {
  ///A container that will be used to resolve dependencies of instances, created by stroyboards.
  static public var uiContainer: DependencyContainer?
}

let DipTagAssociatedObjectKey = UnsafeMutablePointer<Int8>.alloc(1)

extension NSObject {
  
  ///A string tag that will be used to resolve dependencies of this instance
  ///if it implements `StoryboardInstantiatable` protocol.
  @IBInspectable private(set) public var dipTag: String? {
    get {
      return objc_getAssociatedObject(self, DipTagAssociatedObjectKey) as? String
    }
    set {
      objc_setAssociatedObject(self, DipTagAssociatedObjectKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
      
      if let key = newValue, container = DependencyContainer.uiContainer {
        let tag = DependencyContainer.Tag.String(key)
        if let instantiatable = self as? StoryboardInstantiatable {
          instantiatable.didInstantiateFromStoryboard(withTag: tag, container: container)
        }
      }
    }
  }
  
}

