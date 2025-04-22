import SwiftUI
import SwiftSoup
import UserNotifications

struct Notice: Identifiable, Equatable {
    let id = UUID()
    let number: String
    let title: String
    let link: String
    let isPinned: Bool
}

class NoticeFetcher: ObservableObject {
    @Published var notices: [Notice] = []
    @Published var pinnedNotices: [Notice] = []
    @Published var isFetching = false
    @Published var hasMoreData = true

    private let baseUrlString = "https://www.hallym.ac.kr/hallym_univ/sub05/cPno/list.do?pageIndex="
    private let firstPageUrlString = "https://www.hallym.ac.kr/hallym_univ/sub05/cPno/list.do"
    private var currentOffset = 1
    private let limit = 1
    private let lastNoticesKey = "lastNoticesKey"

    init() {
        fetchFirstPage()
    }

    func fetchFirstPage() {
        guard !isFetching else { return }
        isFetching = true
        currentOffset = 1
        hasMoreData = true
        print("🔄 Fetching first page...")

        guard let url = URL(string: firstPageUrlString) else {
            print("❌ Invalid first page URL")
            DispatchQueue.main.async {
                self.isFetching = false
            }
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
                print("❌ Network error: \(error.localizedDescription)")
                return
            }

            guard let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                print("❌ Invalid data or encoding")
                return
            }

            do {
                let doc = try SwiftSoup.parse(html)
                let elements = try doc.select("table.board-table tbody tr")
                print("📑 Found \(elements.count) rows in first page")

                var fetchedNotices: [Notice] = []
                var fetchedPinnedNotices: [Notice] = []

                for row in elements.array() {
                    let isPinned = (try? row.hasClass("b-top-box")) ?? false

                    guard let numberElement = try? row.select("td.b-num-box").first(),
                          let titleElement = try? row.select("td.b-td-left a").first() else {
                        continue
                    }

                    let numberText = try numberElement.text()
                    let title = try titleElement.text()
                    let linkFragment = try titleElement.attr("href")
                    let link = "https://data.hallym.ac.kr" + linkFragment

                    let notice = Notice(
                        number: numberText,
                        title: title,
                        link: link,
                        isPinned: isPinned
                    )

                    if isPinned {
                        fetchedPinnedNotices.append(notice)
                    } else if numberText != "공지" && Int(numberText) != nil {
                        fetchedNotices.append(notice)
                    }
                }

                let sortedNotices = fetchedNotices.sorted {
                    (Int($0.number) ?? 0) > (Int($1.number) ?? 0)
                }

                DispatchQueue.main.async {
                    self.pinnedNotices = fetchedPinnedNotices
                    self.notices = sortedNotices
                    self.currentOffset = 2
                    self.hasMoreData = !sortedNotices.isEmpty
                    print("✅ Fetched first page. Pinned: \(self.pinnedNotices.count), Regular: \(self.notices.count)")
                    self.checkForNewNotices(fetchedPinnedNotices + sortedNotices)
                }

            } catch {
                print("❌ HTML parsing error: \(error)")
            }
        }.resume()
    }


    func fetchNextPage() {
        guard !isFetching, hasMoreData else {
            if isFetching { print(" Bailing: Fetch already in progress.") }
            if !hasMoreData { print(" Bailing: No more data.") }
            return
        }

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

                    if Int(numberText) != nil {
                        let title = try titleElement.text()
                        let linkFragment = try titleElement.attr("href")

                        let notice = Notice(
                            number: numberText,
                            title: title,
                            link: "https://data.hallym.ac.kr" + linkFragment,
                            isPinned: false
                        )

                        if !self.notices.contains(where: { $0.number == numberText }) {
                            newNotices.append(notice)
                        }
                    }
                }

                let sortedNewNotices = newNotices.sorted {
                    (Int($0.number) ?? 0) > (Int($1.number) ?? 0)
                }

                DispatchQueue.main.async {
                    if sortedNewNotices.isEmpty {
                        self.hasMoreData = false
                        print("📝 No more notices to load")
                    } else {
                        self.notices.append(contentsOf: sortedNewNotices)
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

    private func parseNotices(from html: String, isTop: Bool = false) -> [Notice] {
        var notices: [Notice] = []
        do {
            let doc = try SwiftSoup.parse(html)
            let elements = try doc.select("table.board-table tbody tr")

            for element in elements.array() {
                guard let numberElement = try? element.select("td.b-num-box").first(),
                      let titleElement = try? element.select("td.b-td-left a").first() else {
                    continue
                }

                let numberText = try numberElement.text()
                if numberText == "번호" { continue }

                let isFixed = numberText == "공지"
                let title = try titleElement.text()
                let linkFragment = try titleElement.attr("href")
                let link = "https://data.hallym.ac.kr" + linkFragment

                let notice = Notice(
                    number: numberText,
                    title: title,
                    link: link,
                    isPinned: isFixed
                )
                notices.append(notice)
            }
        } catch Exception.Error(_, let message) {
            print("❌ SwiftSoup Parsing Error: \(message)")
        } catch {
            print("❌ Unknown parsing error: \(error)")
        }
        return notices
    }

    private func parseTopNotices(from html: String) -> [Notice] {
        var topNotices: [Notice] = []
        do {
            let doc = try SwiftSoup.parse(html)
            let elements = try doc.select("table.board-table tbody tr.notice")

            for element in elements.array() {
                 guard let titleElement = try? element.select("td.b-td-left a").first() else {
                     continue
                 }

                let title = try titleElement.text()
                 let linkFragment = try titleElement.attr("href")
                 let link = "https://data.hallym.ac.kr" + linkFragment

                 let notice = Notice(
                     number: "공지",
                     title: title,
                     link: link,
                     isPinned: true
                 )
                 topNotices.append(notice)
            }
        } catch Exception.Error(_, let message) {
            print("❌ SwiftSoup Parsing Error (Top Notices): \(message)")
        } catch {
            print("❌ Unknown parsing error (Top Notices): \(error)")
        }
        return topNotices
    }
}
