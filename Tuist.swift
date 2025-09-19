import ProjectDescription

let tuist = Tuist(
    project: .tuist(plugins: [
        .git(url: "https://github.com/jihoonme/tuistui", tag: "0.2.9")
    ])
)
