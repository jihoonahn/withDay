import ProjectDescription

private let layer = Template.Attribute.required("layer")
private let name = Template.Attribute.required("name")

private let template = Template(
    description: "A template for a new module",
    attributes: [
        layer,
        name,
    ],
    items: [
        .file(
            path: "Projects/\(layer)/\(name)/Sources/Sources.swift",
            templatePath: "Sources.stencil"
        ),
    ]
)
 
