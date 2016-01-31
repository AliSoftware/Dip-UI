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

import XCTest
@testable import DipUI

#if os(iOS) || os(tvOS)
  import UIKit
  typealias Storyboard = UIStoryboard
  typealias Responder = UIResponder
  typealias ViewController = UIViewController
#else
  import AppKit
  typealias Storyboard = NSStoryboard
  typealias Responder = NSResponder
  typealias ViewController = NSViewController
  
  extension NSStoryboard {
    func instantiateViewControllerWithIdentifier(identifier: String) -> NSViewController {
      return instantiateControllerWithIdentifier(identifier) as! NSViewController
    }
  }
  
#endif

class DipViewController: ViewController, StoryboardInstantiatable { }

class DipUITests: XCTestCase {
  
  let storyboard: Storyboard = {
    let bundle = NSBundle(forClass: DipUITests.self)
    return Storyboard(name: String(Storyboard.self), bundle: bundle)
  }()
  
  func testThatViewControllerHasDipTagProperty() {
    let viewController = storyboard.instantiateViewControllerWithIdentifier("DipViewController")
    XCTAssertEqual(viewController.dipTag, "vc")
  }
  
  func testThatItDoesNotResolveIfContainerIsNotSet() {
    let container = DependencyContainer()
    container.register(tag: "vc") { ViewController() }
      .resolveDependencies { _, _ in
        XCTFail("Should not resolve when container is not set.")
    }
    
    storyboard.instantiateViewControllerWithIdentifier("DipViewController")
  }
  
  func testThatItDoesNotResolveIfTagIsNotSet() {
    let container = DependencyContainer()
    container.register(tag: "vc") { ViewController() }
      .resolveDependencies { _, _ in
        XCTFail("Should not resolve when container is not set.")
    }
    
    Storyboard.container = container
    storyboard.instantiateViewControllerWithIdentifier("ViewController")
  }
  
  func testThatItResolvesIfContainerAndTagAreSet() {
    var resolved = false
    let container = DependencyContainer()
    container.register(tag: "vc") { DipViewController() }
      .resolveDependencies { _, _ in
        resolved = true
    }
    
    Storyboard.container = container
    storyboard.instantiateViewControllerWithIdentifier("DipViewController")
    XCTAssertTrue(resolved, "Should resolve when container is set.")
  }
  
}

protocol SomeService: class {
  weak var delegate: SomeServiceDelegate? { get set }
}
protocol SomeServiceDelegate: class { }
class SomeServiceImp: SomeService {
  weak var delegate: SomeServiceDelegate?
  init(delegate: SomeServiceDelegate) {
    self.delegate = delegate
  }
  init(){}
}

protocol OtherService: class {
  weak var delegate: OtherServiceDelegate? { get set }
}
protocol OtherServiceDelegate: class {}
class OtherServiceImp: OtherService {
  weak var delegate: OtherServiceDelegate?
  init(delegate: OtherServiceDelegate){
    self.delegate = delegate
  }
  init(){}
}


protocol SomeScreen: class {
  var someService: SomeService! { get set }
  var otherService: OtherService! { get set }
}

class ViewControllerImp: SomeScreen, SomeServiceDelegate, OtherServiceDelegate {
  var someService: SomeService!
  var otherService: OtherService!
  init(){}
}

extension DipUITests {
  
  func testThatItDoesNotCreateNewInstanceWhenResolvingDependenciesOfExternalInstance() {
    let container = DependencyContainer()
    
    //given
    var factoryCalled = false
    container.register(.ObjectGraph) { () -> SomeScreen in
      factoryCalled = true
      return ViewControllerImp() as SomeScreen
    }
    
    //when
    let screen = ViewControllerImp()
    try! container.resolveDependenciesOf(screen as SomeScreen)
    
    //then
    XCTAssertFalse(factoryCalled, "Container should not create new instance when resolving dependencies of external instance.")
  }
  
  func testThatItResolvesInstanceThatImplementsSeveralProtocols() {
    let container = DependencyContainer()

    //given
    container.register(.ObjectGraph) { ViewControllerImp() as SomeScreen }
      .resolveDependencies { container, resolved in
        
        //manually provide resolved instance for the delegate properties
        resolved.someService = try container.resolve() as SomeService
        resolved.someService.delegate = resolved as? SomeServiceDelegate
        resolved.otherService = try container.resolve(withArguments: resolved as! OtherServiceDelegate) as OtherService
    }
    
    container.register(.ObjectGraph) { SomeServiceImp() as SomeService }
    container.register(.ObjectGraph) { OtherServiceImp(delegate: $0) as OtherService }
    
    //when
    let screen = try! container.resolve() as SomeScreen
    
    //then
    XCTAssertNotNil(screen.someService)
    XCTAssertNotNil(screen.otherService)
    
    XCTAssertTrue(screen.someService.delegate === screen)
    XCTAssertTrue(screen.otherService.delegate === screen)
  }
  
}
