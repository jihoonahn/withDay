import SwiftUI
import Rex
import MemoFeatureInterface
import MemoDomainInterface
import Designsystem
import Utility

struct MemoListView: View {
    let interface: MemoInterface
    @State var state: MemoState
    
    private var groupedMemos: [(date: Date, memos: [MemoEntity])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: state.memos) { memo in
            calendar.startOfDay(for: memo.createdAt ?? Date())
        }
        
        return grouped
            .map { (date: $0.key, memos: $0.value) }
            .sorted { $0.date > $1.date } // 최신 날짜가 위로
    }

    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                List {
                    ForEach(groupedMemos, id: \.date) { group in
                        Section(header: Text(group.date.toString(format: "yyyy년 M월 d일 EEEE"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(JColor.textPrimary)
                            .textCase(nil)) {
                            ForEach(group.memos, id: \.id) { memo in
                                VStack(alignment: .leading, spacing: 8) {
                                    if !memo.title.isEmpty {
                                        Text(memo.title)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(JColor.textPrimary)
                                    }
                                    if !memo.content.isEmpty {
                                        Text(memo.content)
                                            .font(.system(size: 14))
                                            .foregroundColor(JColor.textSecondary)
                                            .lineLimit(3)
                                    }
                                }
                                .onTapGesture {
                                    interface.send(.showEditMemo(memo))
                                }
                                .padding(.vertical, 8)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        interface.send(.deleteMemo(memo.id))
                                    } label: {
                                        Label("Hello", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Memos")
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}
