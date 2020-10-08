// swift-tools-version:5.3

import PackageDescription

private let libraryName = "KBBlockActions";

private func targetName (_ name: String) -> String { "\(libraryName)_\(name)" }

let package = Package (
	name: libraryName,
	products: [ .library (name: libraryName, targets: [targetName ("Swift")]) ],
	targets: [
		.target (
			name: targetName ("Swift"), dependencies: [.target (name: targetName ("ObjC"))], path: ".",
			exclude: ["README.md", "LICENSE", "UIKit+blockActions.mm", "ARCOverride.c"],
			sources: ["UIKit+blockActions.swift"]
		),
		.target (
			name: targetName ("ObjC"),  path: ".",
			exclude: ["README.md", "LICENSE", "UIKit+blockActions.swift"],
			sources: ["UIKit+blockActions.h", "UIKit+blockActions.mm", "ARCOverride.c"],
			publicHeadersPath: "."
		),
	],
	cxxLanguageStandard: .gnucxx1z
);
