import ProjectDescription
import TuistUI

let workspace = WithDay().module()

struct WithDay: Module {
    var body: some Module {
        Workspace {
            Path("Projects/App")
        }
    }
}
