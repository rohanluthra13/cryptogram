//
//  StandardSheet.swift
//  simple cryptogram
//
//  Created on 29/05/2025.
//

import SwiftUI

/// A reusable sheet container providing consistent styling and behavior
struct StandardSheet<Content: View>: View {
    let title: String
    let dismissAction: () -> Void
    @ViewBuilder let content: () -> Content
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.typography) private var typography
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                content()
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 20)
                    }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton(action: dismissAction)
                }
            }
        }
        .navigationViewStyle(.stack)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.95)
    }
}

/// A variant that supports custom detents for smaller sheets
struct CompactSheet<Content: View>: View {
    let title: String
    let dismissAction: () -> Void
    let detents: Set<PresentationDetent>
    @ViewBuilder let content: () -> Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                content()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton(action: dismissAction)
                }
            }
        }
        .navigationViewStyle(.stack)
        .presentationDetents(detents)
        .presentationDragIndicator(.visible)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.95)
    }
}

#if DEBUG
struct StandardSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Text("Preview Host")
                .sheet(isPresented: .constant(true)) {
                    StandardSheet(title: "Settings", dismissAction: {}) {
                        VStack {
                            Text("Sheet Content")
                            Spacer()
                        }
                        .padding()
                    }
                }
            
            Text("Preview Host")
                .sheet(isPresented: .constant(true)) {
                    CompactSheet(
                        title: "Info",
                        dismissAction: {},
                        detents: [.medium]
                    ) {
                        VStack {
                            Text("Compact Sheet Content")
                            Spacer()
                        }
                        .padding()
                    }
                }
                .preferredColorScheme(.dark)
        }
    }
}
#endif