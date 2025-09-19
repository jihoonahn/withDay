import ProjectDescription

private let layer = Template.Attribute.required("layer")
private let name = Template.Attribute.required("name")

private let template = Template(
    description: "A template for a new module's interface target",
    attributes: [
        layer,
        name
    ],
    items: [
        .file(
            path: "Projects/\(layer)/\(name)/Interface/Interface.swift",
            templatePath: "Interface.stencil"
        )
    ]
)
