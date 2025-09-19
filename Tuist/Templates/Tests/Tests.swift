import ProjectDescription

private let layer = Template.Attribute.required("layer")
private let name = Template.Attribute.required("name")

private let template = Template(
    description: "A template for a new module's unit tests target",
    attributes: [
        layer,
        name
    ],
    items: [
        .file(
            path: "Projects/\(layer)/\(name)/Tests/Tests.swift",
            templatePath: "Tests.stencil"
        )
    ]
)
