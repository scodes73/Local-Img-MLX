// Copyright © 2024 LocalImg. All rights reserved.

import SwiftData
import SwiftUI

/// Sidebar gallery showing past generation history as thumbnails
struct HistoryGalleryView: View {

    var historyManager: HistoryManager?
    @Binding var selectedRecord: GenerationRecord?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GenerationRecord.createdAt, order: .reverse)
    private var records: [GenerationRecord]

    @State private var hoveredId: PersistentIdentifier?

    var body: some View {
        Group {
            if records.isEmpty {
                emptyState
            } else {
                galleryList
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.system(size: 32))
                .foregroundStyle(.quaternary)
            Text("No generations yet")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var galleryList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(records) { record in
                    historyItem(record)
                }
            }
            .padding(8)
        }
    }

    @ViewBuilder
    private func historyItem(_ record: GenerationRecord) -> some View {
        Button {
            selectedRecord = record
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Thumbnail
                // Thumbnail
                HistoryThumbnailView(record: record, size: 120)

                // Prompt preview
                Text(record.prompt)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Metadata
                Text(record.createdAt.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        selectedRecord?.id == record.id
                            ? Color.accentColor.opacity(0.1)
                            : (hoveredId == record.persistentModelID ? Color.primary.opacity(0.03) : Color.clear)
                    )
            )
            .onHover { isHovered in
                hoveredId = isHovered ? record.persistentModelID : nil
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delete") {
                withAnimation {
                    historyManager?.delete(record)
                }
            }
        }
    }
}
