import Foundation
import Command
import CommandLine
import File

@MainActor
public struct ModuleView: View {
    
    @ObservedObject var store = ModuleStore()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text("Module name: ")
                if store.name?.isEmpty ?? true {
                    TextField { text in
                        store.nameTextFieldDidChange(text)
                    }
                } else {
                    Text(store.name ?? "")
                }
            }
            VStack(spacing: 1) {
                Text("Choose a layer to generate the module in:")
                HStack(spacing: 1) {
                    ForEach(store.layerList) { layer in
                        Button(store.selectedLayer?.text == layer.text ? "◼︎" : "□") {
                            store.layerListDidSelect(layer)
                        }
                        Text(layer.text)
                    }
                }
            }
            Spacer()
                .frame(height: 3)
            VStack(spacing: 1) {
                Text("Select components to generate [comma-separated, e.g. Sources,Tests]:")
                ForEach(store.microFeatureTypeList) { type in
                    HStack {
                        Button(action: {
                            store.toggleMicroFeatureType(type)
                        }) {
                            Text(store.selectedMicroFeatureType?.contains(type) == true ? "◼︎" : "□")
                        }
                        Text(type.text)
                    }
                }
            }
            Spacer()
            HStack {
                Spacer()
                Button("Create") {
                    store.selectCreateAction()
                }
                Spacer()
                Button("Quit") {
                    store.selectQuit()
                }
                Spacer()
            }
            .border(.white, style: .rounded)
        }
        .padding()
        .border(style: .rounded)
    }
}

/// Module ViewModel
public final class ModuleStore: ObservableObject {
    @Command(\.tuist) var tuist
    /// Variables
    @Published var layerList: [LayerModel] = [
        LayerModel(text: "Feature"),
        LayerModel(text: "Domain"),
        LayerModel(text: "Core"),
        LayerModel(text: "Shared"),
    ]
    @Published var microFeatureTypeList: [MicroFeatureType] = [
        MicroFeatureType(text: "Sources"),
        MicroFeatureType(text: "Interface"),
        MicroFeatureType(text: "Example"),
        MicroFeatureType(text: "Testing"),
        MicroFeatureType(text: "Tests"),
        MicroFeatureType(text: "UITests"),
    ]

    @Published var name: String?
    @Published var selectedLayer: LayerModel?
    @Published var selectedMicroFeatureType: [MicroFeatureType]?

    public init() {}
    
    /// Action
    func nameTextFieldDidChange(_ text: String) {
        name = text
    }

    func layerListDidSelect(_ layer: LayerModel) {
        selectedLayer = layer
    }

    func toggleMicroFeatureType(_ type: MicroFeatureType) {
        if selectedMicroFeatureType == nil {
            selectedMicroFeatureType = []
        }
        
        if let index = selectedMicroFeatureType?.firstIndex(of: type) {
            selectedMicroFeatureType?.remove(at: index)
        } else {
            selectedMicroFeatureType?.append(type)
        }
    }

    func selectCreateAction() {
        let path = Path.current.rawValue

        guard let name = name,
              let selectedLayer = selectedLayer,
              let selectedMicroFeatureType = selectedMicroFeatureType else {
            print("❌ Failed To Generate Module")
            exit(1)
        }

        let targetSnippets = selectedMicroFeatureType.map { type in
            switch type.text {
            case "Sources":
                return "Sources(name: typeName)"
            case "Interface":
                return "Interface(name: typeName)"
            case "Example":
                return "Example(name: typeName, dependencies: [])"
            case "Testing":
                return "Testing(name: typeName, dependencies: [])"
            case "Tests":
                return "Tests(name: typeName, dependencies: [])"
            case "UITests":
                return "UITests(name: typeName, dependencies: [])"
            default:
                return ""
            }
        }

        let rawTargetCode = targetSnippets.joined(separator: "\n            ")

        let quotedTargetCode = "\"\(rawTargetCode)\""
        
        tuist.scaffold(
            at: path,
            "Module",
            [
                "--name", name,
                "--layer", selectedLayer.text,
                "--target", quotedTargetCode
            ]
        )

        selectedMicroFeatureType.forEach { type in
            tuist.scaffold(at: path, type.text, ["--layer", selectedLayer.text, "--name", name])
        }

        print(EscapeSequence.disableAlternateBuffer)
        print("✅ Successful Generated Module")
        exit(0)
    }

    func selectQuit() {
        print(EscapeSequence.disableAlternateBuffer)
        exit(0)
    }
}

/// Module Model
struct LayerModel: Identifiable {
    let id = UUID()
    let text: String
}

/// Module Model
struct MicroFeatureType: Identifiable, Equatable {
    let id = UUID()
    let text: String
}
