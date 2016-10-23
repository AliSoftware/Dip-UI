[![CI Status](http://img.shields.io/travis/AliSoftware/Dip-UI.svg?branch=develop)](https://travis-ci.org/AliSoftware/Dip-UI)
[![Version](https://img.shields.io/cocoapods/v/Dip-UI.svg?style=flat)](http://cocoapods.org/pods/Dip-UI)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Dip-UI.svg?style=flat)](http://cocoapods.org/pods/Dip-UI)
[![Platform](https://img.shields.io/cocoapods/p/Dip-UI.svg?style=flat)](http://cocoapods.org/pods/Dip-UI)

# Dip-UI

Dip-UI is an extension for [Dip](https://github.com/AliSoftware/Dip) that provides support for dependency injection using Dip in applications that utilize storyboards and nib files.

## Installation

You can install Dip-UI using your favorite dependency manager:

<details>
<summary>CocoaPods</summary>

`pod "Dip-UI"`

To build for Swift 2.3 add this code to the bottom of your Podfile

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end
```

> You need at least 1.1.0.rc.2 version of CocoaPods.

</details>

<details>
<summary>Carthage</summary>

```
github "AliSoftware/Dip-UI"
```

To build for Swift 2.3 run Carthage with `--toolchain com.apple.dt.toolchain.Swift_2_3` option.

</details>

## Usage

Dip-UI provides a unified and simple pattern to resolve dependencies of view controllers (or any other `NSObject`'s) created by storyboards.

Let's say you want to use Dip to inject dependencies in `MyViewController` class defined like this:

```swift
class MyViewController: UIViewController {
  var logger: Logger?
  var tracker: Tracker?
  var router: Router?
  var presenter: MyViewControllerPresenter?
  var service: MyViewControllerService?
  
  /*...*/
}

```
> Note 1: Though constructor injection is a preferred way to inject dependencies, in this case we can not use it - we can not make storyboards to use custom constructor. We could do it using subclass of UI(NS)Storyboard and method-swizzling, but you don't expect such things in a Swift framework.   

> Note 2: Implicitly unwrapped optionals are used here to indicate that these dependencies are required for this class. You don't have to follow this pattern and are free to use plain optionals if you prefer.

To injecte dependencies in this view controller when it is instantiated from storyboard you need to follow next steps:

- Register the dependencies in the `DependencyContainer`, as well as `MyViewController`:

```swift
import Dip

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  let container = DependencyContainer { container in
    container.register(.Singleton) { LoggerImp() as Logger }
    container.register(.Singleton) { TrackerImp() as Tracker }
    container.register(.Singleton) { RouterImp() as Router }
    container.register { MyViewControllerPresenterImp() as MyViewControllerPresenter }
    container.register { MyViewControllerServiceImp() as MyViewControllerService }
    
    container.register(tag: "myVC") { MyViewController() }
      .resolvingProperties { container, controller in
        container.logger    = try container.resolve() as Logger
        container.tracker   = try container.resolve() as Tracker
        container.router 	= try container.resolve() as Router
        container.presenter = try container.resolve() as MyViewControllerPresenter
        container.service 	= try container.resolve() as MyViewControllerService
      }
      
      DependencyContainer.uiContainers = [container]
  }
}
```
 
> Note: All the depdencies are registered as implementations of abstractions (protocols). `MyViewController` is registered as concrete type. But you can also make your view controller conform to some protocols and register them as implementations of these protocols.
 
- Set the container as one that will be used to inject dependencies in objects created by storyboards. You do it by setting static `uiContainers` property of `DependencyContainer ` class: 

```swift
DependencyContainer.uiContainers = [container]
```

- Make your view controller class conform to `StoryboardInstantiatable` protocol:

```swift
extension MyViewController: StoryboardInstantiatable { }
```

 > Tip: Do that in the Composition Root to avoid coupling your view controller's code with Dip.

- In a storyboard (or in a nib file) set _Dip Tag_ attribute on your view controller. This value will be used to lookup definition for view controller, so it should be the same value that you used to register view controller in the container.

![img](adding-dip-tag-in-ib.png?raw=true)

> Note: remember that `DependencyContainer` fallbacks to not-tagged definition if it does not find tagged definition, so you may register your view controller without tag, but you still need to set it in a storyboard. In this case you can use `Nil` attribute type instead of `String`.

Now when view controller will be loaded from a storyboard Dip-UI will intercept the setter of `dipTag` property and will ask `DependencyContainer.uiContainer` to resolve its dependencies.

### StoryboardInstantiatable

`StoryboardInstantiatable` protocol defines single method `didInstantiateFromStoryboard(_:tag:)` and provides its default implementation. In most cases you will not need to override it. But if you register your view controller as an impementation of some protocol instead of concrete type, or want to perform some pre/post actions, you will need to override it like this:
 
```swift
container.register { MyViewController() as MyScene }
extension MyViewController: StoryboardInstantiatable {
  func didInstantiateFromStoryboard(container: DependencyContainer, tag: DependencyContainer.Tag?) throws {
    try container.resolveDependenciesOf(self as MyScene, tag: tag)
  }
}
```
 

## License

**Dip-UI** is available under the **MIT license**. See the `LICENSE` file for more info.
