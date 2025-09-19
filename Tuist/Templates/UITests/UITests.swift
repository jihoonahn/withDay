import ProjectDescription

private let layer = Template.Attribute.required("layer")
private let name = Template.Attribute.required("name")

private let template = Template(
    description: "A template for a new module's uitests target",
    attributes: [
        layer,
        name
    ],
    items: [
        .file(
            path: "Projects/\(layer)/\(name)/UITests/UITestsLaunchTests.swift",
            templatePath: "UITestsLaunchTests.stencil"
        ),
        .file(
            path: "Projects/\(layer)/\(name)/UITests/UITests.swift",
            templatePath: "UITests.stencil"
        )
    ]
)

