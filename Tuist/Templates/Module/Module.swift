import ProjectDescription

private let layer = Template.Attribute.required("layer")
private let name = Template.Attribute.required("name")
private let target = Template.Attribute.required("target")

private let template = Template(
    description: "A template for a new module",
    attributes: [
        layer,
        name,
        target
    ],
    items: [
        .file(
            path: "Projects/\(layer)/\(name)/Project.swift",
            templatePath: "Project.stencil"
        ),
    ]
)
