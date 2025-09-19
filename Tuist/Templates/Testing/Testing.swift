import ProjectDescription

private let layer = Template.Attribute.required("layer")
private let name = Template.Attribute.required("name")

private let template = Template(
    description: "A template for a new module's testing target",
    attributes: [
        layer,
        name
    ],
    items: [
        .file(
            path: "Projects/\(layer)/\(name)/Testing/Testing.swift",
            templatePath: "Testing.stencil"
        )
    ]
)
