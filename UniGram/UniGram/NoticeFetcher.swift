//
//  NoticeFetcher.swift
//  UniGram
//
//  Created by 이지안 on 2/7/25.
//

import Foundation
import SwiftSoup
import UserNotifications

struct Notice: Codable, Identifiable {
    let id = UUID()
    let number: String
    let title: String
    let link: String
    let isPinned: Bool
}

class NoticeFetcher: ObservableObject {
    @Published var pinnedNotices: [Notice] = []
    @Published var notices: [Notice] = []
    @Published var isFetching: Bool = false
    @Published var hasMoreData: Bool = true
    
    private var currentOffset: Int = 0
    private let limit: Int = 10
    private let baseUrlString = "https://data.hallym.ac.kr/data/community/notice02.do?mode=list&&articleLimit=10&article.offset="
    let lastNoticesKey = "lastNotices"
    private func fetchFirstPage() {
        guard !isFetching else { return }
        
        isFetching = true
        print("🔄 Fetching first page")
        
        guard let url = URL(string: baseUrlString + "0") else {
            print("❌ Invalid URL")
            self.isFetching = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            defer {
                DispatchQueue.main.async {
                    self.isFetching = false
                }
            }
            
            if let error = error {
                print("❌ Error fetching data: \(error)")
                return
            }
            
            guard let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                print("❌ No data or unable to decode HTML")
                return
            }
            
            do {
                let doc = try SwiftSoup.parse(html)
                let elements = try doc.select("table.board-table tbody tr")
                print("📑 Found \(elements.count) rows in first page")
                
                var newPinnedNotices: [Notice] = []
                var newRegularNotices: [Notice] = []
                
                for row in elements.array() {
                    let isPinned = (try? row.hasClass("b-top-box")) ?? false
                    
                    guard let numberElement = try? row.select("td.b-num-box").first(),
                          let titleElement = try? row.select("td.b-td-left a").first() else {
                        continue
                    }
                    
                    let numberText = try numberElement.text()
                    let title = try titleElement.text()
                    let linkFragment = try titleElement.attr("href")
                    
                    let notice = Notice(
                        number: numberText,
                        title: title,
                        link: "https://data.hallym.ac.kr" + linkFragment,
                        isPinned: isPinned
                    )
                    
                    if isPinned {
                        newPinnedNotices.append(notice)
                    } else if numberText != "공지" {
                        // Convert number string to int for proper sorting
                        if let _ = Int(numberText) {
                            newRegularNotices.append(notice)
                        }
                    }
                }
                
                // Sort regular notices by number in descending order
                let sortedRegularNotices = newRegularNotices.sorted {
                    (Int($0.number) ?? 0) > (Int($1.number) ?? 0)
                }
                
                DispatchQueue.main.async {
                    self.pinnedNotices = newPinnedNotices
                    self.notices = sortedRegularNotices
                    self.currentOffset = self.limit
                    self.hasMoreData = !sortedRegularNotices.isEmpty
                    print("✅ Loaded first page with \(newPinnedNotices.count) pinned and \(sortedRegularNotices.count) regular notices")
                }
            } catch {
                print("❌ HTML parsing error: \(error)")
            }
        }.resume()
    }
    
    func fetchNextPage() {
        guard !isFetching, hasMoreData else { return }
        
        isFetching = true
        let urlString = baseUrlString + String(currentOffset)
        print("🔄 Fetching next page with offset: \(currentOffset)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid pagination URL")
            self.isFetching = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            defer {
                DispatchQueue.main.async {
                    self.isFetching = false
                }
            }
            
            guard let data = data,
                  let html = String(data: data, encoding: .utf8) else { return }
            
            do {
                let doc = try SwiftSoup.parse(html)
                let elements = try doc.select("table.board-table tbody tr")
                print("📑 Found \(elements.count) rows in next page")
                
                var newNotices: [Notice] = []
                
                for row in elements.array() {
                    let isPinned = (try? row.hasClass("b-top-box")) ?? false
                    if isPinned { continue }
                    
                    guard let numberElement = try? row.select("td.b-num-box").first(),
                          let titleElement = try? row.select("td.b-td-left a").first() else {
                        continue
                    }
                    
                    let numberText = try numberElement.text()
                    if numberText == "공지" { continue }
                    
                    // Only add if it's a valid number
                    if Int(numberText) != nil {
                        let title = try titleElement.text()
                        let linkFragment = try titleElement.attr("href")
                        
                        let notice = Notice(
                            number: numberText,
                            title: title,
                            link: "https://data.hallym.ac.kr" + linkFragment,
                            isPinned: false
                        )
                        
                        // Check if we already have this notice
                        if !self.notices.contains(where: { $0.number == numberText }) {
                            newNotices.append(notice)
                        }
                    }
                }
                
                // Sort new notices by number in descending order
                let sortedNewNotices = newNotices.sorted {
                    (Int($0.number) ?? 0) > (Int($1.number) ?? 0)
                }
                
                DispatchQueue.main.async {
                    if sortedNewNotices.isEmpty {
                        self.hasMoreData = false
                        print("📝 No more notices to load")
                    } else {
                        self.notices.append(contentsOf: sortedNewNotices)
                        // Sort all notices again to ensure proper order
                        self.notices.sort { (Int($0.number) ?? 0) > (Int($1.number) ?? 0) }
                        self.currentOffset += self.limit
                        print("✅ Loaded \(sortedNewNotices.count) new notices. Total: \(self.notices.count)")
                    }
                }
            } catch {
                print("❌ HTML parsing error: \(error)")
            }
        }.resume()
    }
    
    func refreshNotices() {
        DispatchQueue.main.async {
            self.currentOffset = 0
            self.hasMoreData = true
            self.notices = []
            self.pinnedNotices = []
            self.isFetching = false
        }
        fetchFirstPage()
    }
    
    private func checkForNewNotices(_ newNotices: [Notice]) {
        let userDefaults = UserDefaults.standard
        let lastNotices = userDefaults.stringArray(forKey: lastNoticesKey) ?? []
        let currentTitles = newNotices.map { $0.title }
        let newEntries = currentTitles.filter { !lastNotices.contains($0) }
        
        if !newEntries.isEmpty {
            sendNotification(title: "📢 새로운 공지가 있어요!", body: newEntries.first ?? "")
        }
        
        userDefaults.set(currentTitles, forKey: lastNoticesKey)
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
