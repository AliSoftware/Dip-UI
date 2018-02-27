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
  typealias ViewController = UIViewController
  typealias StoryboardName = String
  
  extension UIStoryboard {
    @nonobjc
    @discardableResult func instantiateViewControllerWithIdentifier(_ identifier: String) -> UIViewController {
      return instantiateViewController(withIdentifier: identifier)
    }
  }

#else
  import AppKit
  typealias Storyboard = NSStoryboard
  typealias ViewController = NSViewController
  typealias StoryboardName = NSStoryboard.Name
  
  extension NSStoryboard {
    @discardableResult func instantiateViewControllerWithIdentifier(_ identifier: String) -> NSViewController {
      return instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(identifier)) as! NSViewController
    }
  }
  
#endif

#if os(iOS)
  let storyboardName = "UIStoryboard"
#elseif os(tvOS)
  let storyboardName = "TVStoryboard"
#else
  let storyboardName = "NSStoryboard"
#endif

class DipViewController: ViewController, StoryboardInstantiatable {}
class NilTagViewController: ViewController, StoryboardInstantiatable {}

class DipUITests: XCTestCase {
  
  let storyboard: Storyboard = {
    let bundle = Bundle(for: DipUITests.self)
    return Storyboard(name: StoryboardName(storyboardName), bundle: bundle)
  }()
  
  func testThatViewControllerHasDipTagProperty() {
    let viewController = storyboard.instantiateViewControllerWithIdentifier("DipViewController")
    XCTAssertEqual(viewController.dipTag, "vc")
  }
  
  func testThatItDoesNotResolveIfContainerIsNotSet() {
    let container = DependencyContainer()
    container.register(tag: "vc") { ViewController() }
      .resolvingProperties { _, _ in
        XCTFail("Should not resolve when container is not set.")
    }
    
    storyboard.instantiateViewControllerWithIdentifier("DipViewController")
  }
  
  func testThatItDoesNotResolveIfTagIsNotSet() {
    let container = DependencyContainer()
    container.register(tag: "vc") { ViewController() }
      .resolvingProperties { _, _ in
        XCTFail("Should not resolve when container is not set.")
    }
    
    DependencyContainer.uiContainers = [container]
    storyboard.instantiateViewControllerWithIdentifier("ViewController")
  }

  func testThatItResolvesIfContainerAndStringTagAreSet() {
    var resolved = false
    let container = DependencyContainer()
    container.register(storyboardType: DipViewController.self, tag: "vc")
      .resolvingProperties { _, _ in
        resolved = true
    }
    
    DependencyContainer.uiContainers = [container]
    storyboard.instantiateViewControllerWithIdentifier("DipViewController")
    XCTAssertTrue(resolved, "Should resolve when container and tag are set.")
  }

  func testThatItResolvesIfContainerAndNilTagAreSet() {
    var resolved = false
    let container = DependencyContainer()
    container.register(storyboardType: NilTagViewController.self)
      .resolvingProperties { _, _ in
        resolved = true
    }
    
    DependencyContainer.uiContainers = [container]
    storyboard.instantiateViewControllerWithIdentifier("NilTagViewController")
    XCTAssertTrue(resolved, "Should resolve when container and nil tag are set.")
  }

  func testThatItDoesNotResolveIfTagDoesNotMatch() {
    let container = DependencyContainer()
    container.register(storyboardType: DipViewController.self, tag: "wrong tag")
      .resolvingProperties { _, _ in
        XCTFail("Should not resolve when container is not set.")
    }
    
    DependencyContainer.uiContainers = [container]
    storyboard.instantiateViewControllerWithIdentifier("DipViewController")
  }
  
  func testThatItResolvesWithDefinitionWithNoTag() {
    var resolved = false
    let container = DependencyContainer()
    container.register(storyboardType: DipViewController.self)
      .resolvingProperties { _, _ in
        resolved = true
    }
    
    DependencyContainer.uiContainers = [container]
    storyboard.instantiateViewControllerWithIdentifier("DipViewController")
    XCTAssertTrue(resolved, "Should fallback to definition with no tag.")
  }
  
  func testThatItIteratesUIContainers() {
    var resolved = false
    let container1 = DependencyContainer()
    let container2 = DependencyContainer()
    container2.register(storyboardType: DipViewController.self, tag: "vc")
      .resolvingProperties { container, _ in
        XCTAssertTrue(container === container2)
        resolved = true
    }
    
    DependencyContainer.uiContainers = [container1, container2]
    storyboard.instantiateViewControllerWithIdentifier("DipViewController")
    XCTAssertTrue(resolved, "Should resolve using second container")
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
  var someService: SomeService? { get set }
  var otherService: OtherService? { get set }
}

class ViewControllerImp: SomeScreen, SomeServiceDelegate, OtherServiceDelegate {
  var someService: SomeService?
  var otherService: OtherService?
  init(){}
}

extension DipUITests {
  
  func testThatItDoesNotCreateNewInstanceWhenResolvingDependenciesOfExternalInstance() {
    let container = DependencyContainer()
    
    //given
    var factoryCalled = false
    container.register(.shared) { () -> SomeScreen in
      factoryCalled = true
      return ViewControllerImp() as SomeScreen
    }
    
    //when
    let screen = ViewControllerImp()
    try! container.resolveDependencies(of: screen as SomeScreen)
    
    //then
    XCTAssertFalse(factoryCalled, "Container should not create new instance when resolving dependencies of external instance.")
  }
  
  func testThatItResolvesInstanceThatImplementsSeveralProtocols() {
    let container = DependencyContainer()

    //given
    container.register(.shared) { ViewControllerImp() as SomeScreen }
      .resolvingProperties { container, resolved in
        
        //manually provide resolved instance for the delegate properties
        resolved.someService = try container.resolve() as SomeService
        resolved.someService?.delegate = resolved as? SomeServiceDelegate
        resolved.otherService = try container.resolve(arguments: resolved as! OtherServiceDelegate) as OtherService
    }
    
    container.register(.shared) { SomeServiceImp() as SomeService }
    container.register(.shared) { OtherServiceImp(delegate: $0) as OtherService }
    
    //when
    let screen = try! container.resolve() as SomeScreen
    
    //then
    XCTAssertNotNil(screen.someService)
    XCTAssertNotNil(screen.otherService)
    
    XCTAssertTrue(screen.someService?.delegate === screen)
    XCTAssertTrue(screen.otherService?.delegate === screen)
  }

  func testThatSeveralUIContainersWorksWithAutoinject() {
    class BaseVC: ViewController {}

    class FooVC: BaseVC {}
    class FooOneVC: FooVC, StoryboardInstantiatable {
      private(set) var nest = Injected<Nest>()
      class Nest {}
    }
    class FooSecVC: FooOneVC {}

    class BarVC: BaseVC {}
    class BarOneVC: BarVC {
      private(set) var nest = Injected<Nest>()
      class Nest {}
    }
    class BarSecVC: BarOneVC {}

    // MARK: foo part
    let fooUICont = DependencyContainer { container in
      container.register(.shared) { FooOneVC() }
      container.register(.shared) { FooSecVC() }
    }

    let fooDataCont = DependencyContainer { container in
      container.register(.shared) { (controller: FooOneVC) -> FooOneVC.Nest in
        return FooOneVC.Nest()
      }
    }

    fooUICont.collaborate(with: fooDataCont)
    fooDataCont.collaborate(with: fooUICont)

    try! fooUICont.bootstrap()
    try! fooDataCont.bootstrap()
    DependencyContainer.uiContainers.append(fooUICont)


    // MARK: bar part
    let barUICont = DependencyContainer { container in
      container.register(.shared) { BarOneVC() }
      container.register(.shared) { BarSecVC() }
    }

    let barDataCont = DependencyContainer { container in
      container.register(.shared) { (controller: BarOneVC) -> BarOneVC.Nest in
        return BarOneVC.Nest()
      }
    }

    barUICont.collaborate(with: barDataCont)
    barDataCont.collaborate(with: barUICont)

    try! barUICont.bootstrap()
    try! barDataCont.bootstrap()
    DependencyContainer.uiContainers.append(barUICont)

    let fooSecVC = FooSecVC()
    fooSecVC.setValue(nil, forKey: "dipTag")
    XCTAssertNotNil(fooSecVC.nest.value)

    let barSecVC = BarSecVC()
    barSecVC.setValue(nil, forKey: "dipTag")
    XCTAssertNotNil(barSecVC.nest.value)
  }
  
}
