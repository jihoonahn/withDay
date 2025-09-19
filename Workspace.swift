import ProjectDescription
import TuistUI

let workspace = ModulerApp().module()

struct ModulerApp: Module {
    var body: some Module {
        Workspace {
            Path("Projects/App")
        }
    }
}
