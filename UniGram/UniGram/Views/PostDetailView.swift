//
//  PostDetailView.swift
//  UniGram
//
//  Created by speedy on 2/8/25.
//

import SwiftUI
import WebKit
import SwiftSoup

// MARK: - Models
struct PostAttachment: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let size: String
    let type: AttachmentType
}

// Update PostAttachment to include file type
enum AttachmentType {
    case hwp
    case pdf
    case other
    
    var icon: String {
        switch self {
        case .hwp: return "doc.text"
        case .pdf: return "doc.pdf"
        case .other: return "doc"
        }
    }
    
    var color: Color {
        switch self {
        case .hwp: return .blue
        case .pdf: return .red
        case .other: return .gray
        }
    }
}
// MARK: - Views
struct PostDetailView: View {
    let notice: Notice
    @StateObject private var viewModel = PostDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Card
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text(notice.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Divider()
                    
                    // Metadata
                    HStack(spacing: 16) {
                        if !viewModel.writer.isEmpty {
                            Label(viewModel.writer, systemImage: "person.circle.fill")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        if !viewModel.date.isEmpty {
                            Label(viewModel.date, systemImage: "calendar")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        if !viewModel.views.isEmpty {
                            Label(viewModel.views, systemImage: "eye.fill")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Content section
                if viewModel.isLoading {
                    ContentLoadingView()
                } else if !viewModel.errorMessage.isEmpty {
                    ErrorView(message: viewModel.errorMessage)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.contentItems) {
                            item in switch item.type {
                                case .text: ContentTextView(text: item.content, alignment: item.alignment)
                                case .image: PostImageView(imageUrl: item.content)
                                case .table(let rows, let headers): CustomTableView(headers: headers, rows: rows) } }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                // Attachments section
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

// Loading View
struct ContentLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("로딩 중...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Text Content View
struct ContentTextView: View {
    let text: String
    let alignment: TextAlignment
    
    var body: some View {
        Text(text)
            .font(.system(size: 16))
            .lineSpacing(6)
            .foregroundColor(.primary)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
            .padding(.vertical, 8)
    }
}

// Image Content View
struct ContentImageView: View {
    let imageUrl: String
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(height: 200)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                    .frame(height: 200)
            @unknown default:
                EmptyView()
            }
        }
    }
}

// Table Content View
struct ContentTableView: View {
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
                            .padding(12)
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
                            .padding(12)
                            .background(Color(.systemBackground))
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
        .padding(.vertical, 8)
    }
}

// Updated Attachment Row
struct AttachmentRow: View {
    let attachment: PostAttachment
    @StateObject private var fileDownloader = FileDownloader()
    
    var body: some View {
        Button(action: {
            fileDownloader.downloadFile(from: attachment.url, filename: attachment.name)
        }) {
            HStack {
                Image(systemName: attachment.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(attachment.type.color)
                
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
                
                if fileDownloader.isDownloading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(attachment.type.color)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .padding(.horizontal)
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

// Add AsyncImage view for loading images
struct PostImageView: View {
    let imageUrl: String
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl)) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
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

// MARK: - ViewModel

struct PostContent: Identifiable {
    let id = UUID()
    var type: ContentType
    var content: String
    var alignment: TextAlignment = .leading // Stores text alignment
    
    
    enum ContentType {
        case text
        case image
        case table([[String]], [String]) // (rows, headers)
    }
}
class FileDownloader: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Float = 0.0
    
    func downloadFile(from urlString: String, filename: String, completion: @escaping (Bool, String) -> Void = {_,_ in }) {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }
        
        isDownloading = true
        
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            DispatchQueue.main.async {
                self.isDownloading = false
                
                if let error = error {
                    completion(false, "Download failed: \(error.localizedDescription)")
                    return
                }
                
                guard let localURL = localURL else {
                    print("❌ Local URL is nil")
                    return
                }
                
                // Get the documents directory
                guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    print("❌ Could not get documents directory")
                    return
                }
                
                // Create final URL for the file
                let destinationURL = documentsPath.appendingPathComponent(filename)
                
                // Remove existing file if it exists
                try? FileManager.default.removeItem(at: destinationURL)
                
                do {
                    // Move downloaded file to documents directory
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    print("✅ File saved: \(destinationURL.path)")
                    
                    // Share the file
                    DispatchQueue.main.async {
                        let activityVC = UIActivityViewController(
                            activityItems: [destinationURL],
                            applicationActivities: nil
                        )
                        
                        // Present the share sheet
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            activityVC.popoverPresentationController?.sourceView = rootVC.view
                            rootVC.present(activityVC, animated: true)
                        }
                    }
                } catch {
                    print("❌ File save error: \(error.localizedDescription)")
                }
                completion(true, "File downloaded successfully")
            }
        }
        
        task.resume()
    }
}

class PostDetailViewModel: ObservableObject {
    @Published var contentItems: [PostContent] = []
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
                
                    // Inside fetchPostDetail function, replace the content extraction part with this:
                    // Extract content
                    if let contentBox = try? doc.select("div.b-content-box").first() {
                        var contentItems: [PostContent] = []
                        
                        // First, try to find fr-view div
                        if let frView = try? contentBox.select("div.fr-view").first() {
                            // Process fr-view content
                            for element in try frView.children() {
                                do {
                                    let tagName = try element.tagName()
                                    
                                    switch tagName {
                                    case "p":
                                        // Handle paragraphs
                                        let styleAttr = (try? element.attr("style")) ?? ""
                                        let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                                        
                                        if !text.isEmpty {
                                            let isCenter = styleAttr.contains("text-align: center")
                                            let alignment: TextAlignment = isCenter ? .center : .leading
                                            contentItems.append(PostContent(type: .text, content: text, alignment: alignment))
                                        }
                                        
                                        // Check for images within paragraph
                                        let images = try element.select("img.fr-fic")
                                        for image in images {
                                            if let imgSrc = try? image.attr("src") {
                                                let fullImageUrl = imgSrc.starts(with: "http") ? imgSrc : "https://data.hallym.ac.kr" + imgSrc
                                                contentItems.append(PostContent(type: .image, content: fullImageUrl))
                                            }
                                        }
                                        
                                    case "table":
                                        // Handle tables
                                        var headers: [String] = []
                                        var rows: [[String]] = []
                                        
                                        // Get headers from th elements
                                        let headerElements = try element.select("th")
                                        if !headerElements.isEmpty() {
                                            headers = try headerElements.map { try $0.text() }
                                        } else {
                                            // If no th elements, use first row as header
                                            if let firstRow = try element.select("tr").first() {
                                                headers = try firstRow.select("td").map { try $0.text() }
                                            }
                                        }
                                        
                                        // Get data rows
                                        let dataRows = try element.select("tr")
                                        let startIndex = headers.isEmpty ? 0 : 1
                                        
                                        for row in dataRows.array() {
                                            if startIndex > 0 && row == dataRows.first() {
                                                continue  // Skip first row if it was used as header
                                            }
                                            
                                            let cells = try row.select("td")
                                            let rowData = try cells.map { try $0.text() }
                                            if !rowData.isEmpty {
                                                rows.append(rowData)
                                            }
                                        }
                                        
                                        if !rows.isEmpty {
                                            contentItems.append(PostContent(type: .table(rows, headers), content: ""))
                                        }
                                        
                                    default:
                                        // Handle other elements (text content)
                                        let hasTables = !(try element.select("table").isEmpty())
                                        let hasImages = !(try element.select("img").isEmpty())
                                        
                                        if !hasTables && !hasImages {
                                            let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                                            if !text.isEmpty {
                                                contentItems.append(PostContent(type: .text, content: text, alignment: .leading))
                                            }
                                        }
                                    }
                                } catch {
                                    print("Error processing element: \(error)")
                                }
                            }
                        } else {
                            // Fallback to processing contentBox directly if fr-view is not found
                            print("fr-view not found, processing content box directly")
                            if let content = try? contentBox.text() {
                                contentItems.append(PostContent(type: .text, content: content, alignment: .leading))
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self?.contentItems = contentItems
                        }
                    }
                    
                    // Extract attachments with file type
                    var attachments: [PostAttachment] = []
                    if let fileBox = try? doc.select("div.b-file-box").first() {
                        let fileLinks = try fileBox.select("a")
                        for link in fileLinks {
                            let name = try link.text()
                            let url = try link.attr("href")
                            
                            // Determine file type
                            var fileType: AttachmentType = .other
                            let className = try link.className()
                            if className.contains("hwp") {
                                fileType = .hwp
                            } else if className.contains("pdf") {
                                fileType = .pdf
                            }
                            
                            attachments.append(PostAttachment(
                                name: name,
                                url: "https://data.hallym.ac.kr" + url,
                                size: "",
                                type: fileType
                            ))
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

extension TextAlignment {
    var frameAlignment: Alignment {
        switch self {
            case .center: return .center
            case .leading: return .leading
            case .trailing: return .trailing
            @unknown default: return .leading } } }
