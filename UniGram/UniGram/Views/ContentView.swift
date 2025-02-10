//
//  ContentView.swift
//  UniGram
//
//  Created by speedy on 2/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var noticeFetcher = NoticeFetcher()
    @StateObject private var colorScheme = ColorSchemeManager()
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if noticeFetcher.isFetching && noticeFetcher.notices.isEmpty && noticeFetcher.pinnedNotices.isEmpty {
                        ProgressView("로딩 중...")
                            .padding()
                    } else {
                        // Pinned Notices Section
                        if !noticeFetcher.pinnedNotices.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("📌 고정 공지")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                
                                ForEach(noticeFetcher.pinnedNotices) { notice in
                                    ModernNoticeRow(notice: notice, isPinned: true)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            Divider()
                                .padding(.horizontal)
                        }
                        
                        // Regular Notices Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("공지사항")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            if noticeFetcher.notices.isEmpty && !noticeFetcher.isFetching {
                                EmptyNoticeView()
                            } else {
                                ForEach(noticeFetcher.notices) { notice in
                                    ModernNoticeRow(notice: notice, isPinned: false)
                                        .onAppear {
                                            if notice.id == noticeFetcher.notices.last?.id {
                                                noticeFetcher.fetchNextPage()
                                            }
                                        }
                                }
                            }
                            
                            if noticeFetcher.isFetching {
                                LoadingRow()
                            } else if !noticeFetcher.hasMoreData && !noticeFetcher.notices.isEmpty {
                                EndOfContentRow()
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("UniGram 공지사항")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DarkModeButton(colorScheme: colorScheme)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            colorScheme.toggleColorScheme()
                        }
                    }) {
                        Image(systemName: colorScheme.isDarkMode ? "moon.fill" : "moon")
                            .foregroundColor(colorScheme.isDarkMode ? .yellow : .primary)
                            .font(.system(size: 16))
                            .rotationEffect(.degrees(colorScheme.isDarkMode ? 360 : 0))
                            .animation(.easeInOut(duration: 0.3), value: colorScheme.isDarkMode)
                    }
                }
            }

            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                noticeFetcher.refreshNotices()
            }
            .onReceive(timer) { _ in
                noticeFetcher.refreshNotices()
            }
            .refreshable {
                noticeFetcher.refreshNotices()
            }
        }
        .preferredColorScheme(colorScheme.isDarkMode ? .dark : .light)
    }
}

struct DarkModeButton: View {
    @ObservedObject var colorScheme: ColorSchemeManager
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                colorScheme.toggleColorScheme()
            }
        }) {
            ZStack {
                Circle()
                    .fill(colorScheme.isDarkMode ? Color.black.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: colorScheme.isDarkMode ? "moon.fill" : "moon")
                    .foregroundColor(colorScheme.isDarkMode ? .yellow : .primary)
                    .font(.system(size: 16))
                    .rotationEffect(.degrees(colorScheme.isDarkMode ? 360 : 0))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: colorScheme.isDarkMode)
    }
}


struct ModernNoticeRow: View {
    let notice: Notice
    let isPinned: Bool
    
    var body: some View {
        NavigationLink(destination: PostDetailView(notice: notice)) {
            HStack(spacing: 16) {
                // Number Circle
                ZStack {
                    Circle()
                        .fill(isPinned ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text(notice.number)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isPinned ? .red : .blue)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notice.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(notice.link)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
}

struct EmptyNoticeView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("📭 공지사항이 없습니다.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct LoadingRow: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct EndOfContentRow: View {
    var body: some View {
        Text("더 이상 공지사항이 없습니다")
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}

