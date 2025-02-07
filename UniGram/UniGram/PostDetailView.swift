//
//  PostDetailView.swift
//  UniGram
//
//  Created by 이지안 on 2/8/25.
//

// First, create a new file: PostDetailView.swift
import SwiftUI
import WebKit
import SwiftSoup

// MARK: - Models
struct PostAttachment: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let size: String
}

// MARK: - Views
struct PostDetailView: View {
    let notice: Notice
    @StateObject private var viewModel = PostDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text(notice.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Metadata
                    HStack(spacing: 12) {
                        if !viewModel.writer.isEmpty {
                            Label(viewModel.writer, systemImage: "person")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        if !viewModel.date.isEmpty {
                            Label(viewModel.date, systemImage: "calendar")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        if !viewModel.views.isEmpty {
                            Label(viewModel.views, systemImage: "eye")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Content
                if viewModel.isLoading {
                    ProgressView("로딩 중...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if !viewModel.errorMessage.isEmpty {
                    ErrorView(message: viewModel.errorMessage)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        // Regular content
                        if !viewModel.content.isEmpty {
                            Text(viewModel.content)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        // Table if exists
                        if !viewModel.tableData.isEmpty {
                            CustomTableView(
                                headers: viewModel.tableHeaders,
                                rows: viewModel.tableData
                            )
                            .padding(.vertical)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                
                // Attachments
                if !viewModel.attachments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📎 첨부파일")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.attachments) { attachment in
                            AttachmentRow(attachment: attachment)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchPostDetail(from: notice.link)
        }
    }
}

struct PostContentView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if content.isEmpty {
                Text("내용이 없습니다.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// Custom Table View
struct CustomTableView: View {
    let headers: [String]
    let rows: [[String]]
    
    var body: some View {
        VStack(spacing: 0) {
            // Headers
            if !headers.isEmpty {
                HStack(spacing: 0) {
                    ForEach(headers, id: \.self) { header in
                        Text(header)
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .border(Color(.systemGray4), width: 0.5)
                    }
                }
            }
            
            // Rows
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(row, id: \.self) { cell in
                        Text(cell)
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .border(Color(.systemGray4), width: 0.5)
                    }
                }
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
        .background(Color(.systemBackground))
    }
}

struct AttachmentRow: View {
    let attachment: PostAttachment
    
    var body: some View {
        Link(destination: URL(string: attachment.url) ?? URL(string: "https://data.hallym.ac.kr")!) {
            HStack {
                Image(systemName: "doc")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(attachment.name)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    if !attachment.size.isEmpty {
                        Text(attachment.size)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// MARK: - ViewModel
class PostDetailViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var tableData: [[String]] = []  // For table rows and columns
    @Published var tableHeaders: [String] = [] // For table headers
    @Published var date: String = ""
    @Published var writer: String = ""
    @Published var views: String = ""
    @Published var attachments: [PostAttachment] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    func fetchPostDetail(from link: String) {
        isLoading = true
        errorMessage = ""
        
        guard let articleNo = extractArticleNo(from: link) else {
            errorMessage = "Invalid article number"
            isLoading = false
            return
        }
        
        let viewUrlString = "https://data.hallym.ac.kr/data/community/notice02.do?mode=view&articleNo=\(articleNo)&article.offset=0&articleLimit=10"
        
        guard let url = URL(string: viewUrlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data,
                      let html = String(data: data, encoding: .utf8) else {
                    self?.errorMessage = "Failed to load content"
                    return
                }
                
                do {
                    let doc = try SwiftSoup.parse(html)
                    
                    // Extract metadata
                    if let etcBox = try? doc.select("div.b-etc-box").first() {
                        let spans = try etcBox.select("span")
                        for span in spans {
                            let text = try span.text()
                            if text.contains("작성자") {
                                self?.writer = text.replacingOccurrences(of: "작성자 : ", with: "")
                            } else if text.contains("등록일") {
                                self?.date = text.replacingOccurrences(of: "등록일 : ", with: "")
                            } else if text.contains("조회수") {
                                self?.views = text.replacingOccurrences(of: "조회수 : ", with: "")
                            }
                        }
                    }
                    
                    // Extract content and parse tables
                    if let contentBox = try? doc.select("div.b-content-box").first() {
                        // Extract text content
                        var contentText = try contentBox.text()
                        contentText = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
                        self?.content = contentText
                        
                        // Parse tables
                        let tables = try contentBox.select("table")
                        for table in tables {
                            var headers: [String] = []
                            var rows: [[String]] = []
                            
                            // Get headers
                            let headerRows = try table.select("tr:has(th)")
                            for headerRow in headerRows {
                                let headerCells = try headerRow.select("th")
                                headers = try headerCells.map { try $0.text() }
                            }
                            
                            // If no th elements, try first row as header
                            if headers.isEmpty {
                                if let firstRow = try table.select("tr").first() {
                                    let cells = try firstRow.select("td")
                                    headers = try cells.map { try $0.text() }
                                }
                            }
                            
                            // Get data rows
                            let dataRows = try table.select("tr")
                            for row in dataRows {
                                let cells = try row.select("td")
                                let rowData = try cells.map { try $0.text() }
                                if !rowData.isEmpty {
                                    rows.append(rowData)
                                }
                            }
                            
                            self?.tableHeaders = headers
                            self?.tableData = rows
                        }
                    }
                    
                    // Extract attachments
                    var attachments: [PostAttachment] = []
                    if let fileList = try? doc.select("ul.b-file li") {
                        for fileItem in fileList {
                            if let linkElement = try? fileItem.select("a").first() {
                                let name = try linkElement.text()
                                let url = try linkElement.attr("href")
                                
                                var size = ""
                                if let sizeSpan = try? fileItem.select("span.file-size").first() {
                                    size = try sizeSpan.text()
                                }
                                
                                attachments.append(PostAttachment(
                                    name: name,
                                    url: "https://data.hallym.ac.kr" + url,
                                    size: size
                                ))
                            }
                        }
                    }
                    self?.attachments = attachments
                    
                } catch {
                                    self?.errorMessage = "Failed to parse content"
                                    print("❌ Parsing error: \(error)")
                                }
                            }
                        }.resume()
                    }
    
    private func extractArticleNo(from link: String) -> String? {
        // Try to find articleNo in the link
        guard let range = link.range(of: "articleNo=") else {
            return nil
        }
        
        let start = range.upperBound
        let remainingString = String(link[start...])
        
        // Extract the number until the next & or the end of string
        if let endRange = remainingString.range(of: "&") {
            return String(remainingString[..<endRange.lowerBound])
        } else {
            return remainingString
        }
    }
}
