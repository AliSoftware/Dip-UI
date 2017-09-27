import PackageDescription

let package = Package(
  name: "DipUI",
  dependencies: [
    .Package(url: "https://github.com/AliSoftware/Dip.git", majorVersion: 6)
  ]
)
