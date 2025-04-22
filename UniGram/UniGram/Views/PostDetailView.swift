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
                VStack(alignment: .leading, spacing: 12) {
                    Text(notice.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Divider()
                    
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

struct ContentTableView: View {
    let headers: [String]
    let rows: [[String]]
    
    var body: some View {
        VStack(spacing: 0) {
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

struct AlertMessage: Identifiable {
    let id = UUID() 
    let text: String
}

struct AttachmentRow: View {
    let attachment: PostAttachment
    @StateObject private var fileDownloader = FileDownloader()
    @State private var isShowingPreview = false
    @State private var alertMessage: AlertMessage? = nil

    var body: some View {
        Button(action: {
            alertMessage = nil 

            fileDownloader.downloadFile(from: attachment.url, filename: attachment.name) { downloadedURL, error in
                if let error = error {
                    print("❌ Download failed in AttachmentRow: \(error.localizedDescription)")
                    self.alertMessage = AlertMessage(text: "다운로드 실패: \(error.localizedDescription)")
                } else if downloadedURL != nil {
                    self.isShowingPreview = true
                }
            }
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
        .sheet(isPresented: $isShowingPreview) {
            if let previewURL = fileDownloader.previewURL {
                QuickLookPreview(url: previewURL)
            }
        }
        .alert(item: $alertMessage) { msg in 
            Alert(title: Text("다운로드 오류"), message: Text(msg.text), dismissButton: .default(Text("확인")))
        }
    }
}

/*
// Helper struct to conform String to Identifiable for the alert
extension String: Identifiable {
    public var id: String { self }
}
*/

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        
        init(url: URL) {
            self.url = url
            super.init()
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
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

struct CustomTableView: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        VStack(spacing: 0) {
            if !headers.isEmpty {
                HStack(spacing: 0) {
                    ForEach(headers.indices, id: \.self) { index in
                        Text(headers[index]) 
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .border(Color(.systemGray4), width: 0.5)
                    }
                }
            }

            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(rows[rowIndex].indices, id: \.self) { cellIndex in
                        Text(rows[rowIndex][cellIndex]) 
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
    var alignment: TextAlignment = .leading
    
    
    enum ContentType {
        case text
        case image
        case table([[String]], [String]) 
    }
}
import QuickLook

class FileDownloader: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Float = 0.0
    @Published var previewURL: URL?
    
    func downloadFile(from urlString: String, filename: String, completion: @escaping (URL?, Error?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion(nil, NSError(domain: "FileDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        isDownloading = true
        downloadProgress = 0.0 

        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            DispatchQueue.main.async {
                self.isDownloading = false

                if let error = error {
                    print("❌ Download failed: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }

                guard let localURL = localURL else {
                    print("❌ Local URL is nil")
                    completion(nil, NSError(domain: "FileDownloader", code: -2, userInfo: [NSLocalizedDescriptionKey: "Local URL is nil after download"]))
                    return
                }

                guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    print("❌ Could not get documents directory")
                    completion(nil, NSError(domain: "FileDownloader", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not get documents directory"]))
                    return
                }

                let destinationURL = documentsPath.appendingPathComponent(filename)

                try? FileManager.default.removeItem(at: destinationURL)

                do {
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    print("✅ File saved: \(destinationURL.path)")

                    // *** REMOVED UIActivityViewController presentation ***

                    self.previewURL = destinationURL
                    completion(destinationURL, nil)
                } catch {
                    print("❌ File move error: \(error.localizedDescription)")
                    completion(nil, error)
                }
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
                    
                    if let etcBox = try? doc.select("div.b-etc-box").first() {
                        let spans = try etcBox.select("span")
                        for span in spans {
                            let text = try span.text() 
                            if text.contains("작성자") {
                                self?.writer = text.replacingOccurrences(of: "작성자 : ", with: "")
                            } else if text.contains("등록일") {
                                self?.date = try span.text().replacingOccurrences(of: "등록일 : ", with: "") // Added try
                            } else if text.contains("조회수") {
                                self?.views = text.replacingOccurrences(of: "조회수 : ", with: "")
                            }
                        }
                    }
                
                    if let contentBox = try? doc.select("div.b-content-box").first() {
                        var contentItems: [PostContent] = []
                        
                        if let frView = try? contentBox.select("div.fr-view").first() {
                            for element in frView.children() { 
                                do {
                                    let tagName = element.tagName() 
                                    
                                    switch tagName {
                                    case "p":
                                        let styleAttr = (try? element.attr("style")) ?? ""
                                        let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                                        
                                        if !text.isEmpty {
                                            let isCenter = styleAttr.contains("text-align: center")
                                            let alignment: TextAlignment = isCenter ? .center : .leading
                                            contentItems.append(PostContent(type: .text, content: text, alignment: alignment))
                                        }
                                        
                                        let images = try element.select("img.fr-fic")
                                        for image in images {
                                            if let imgSrc = try? image.attr("src") {
                                                let fullImageUrl = imgSrc.starts(with: "http") ? imgSrc : "https://data.hallym.ac.kr" + imgSrc
                                                contentItems.append(PostContent(type: .image, content: fullImageUrl))
                                            }
                                        }
                                        
                                    case "table":
                                        var headers: [String] = []
                                        var rows: [[String]] = []
                                        
                                        let headerElements = try element.select("th")
                                        if !headerElements.isEmpty() {
                                            headers = try headerElements.map { try $0.text() }
                                        } else {
                                            if let firstRow = try element.select("tr").first() {
                                                headers = try firstRow.select("td").map { try $0.text() }
                                            }
                                        }
                                        
                                        let dataRows = try element.select("tr")
                                        let startIndex = headers.isEmpty ? 0 : 1
                                        
                                        for row in dataRows.array() {
                                            if startIndex > 0 && row == dataRows.first() {
                                                continue  
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
                            print("fr-view not found, processing content box directly")
                            if let content = try? contentBox.text() {
                                contentItems.append(PostContent(type: .text, content: content, alignment: .leading))
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self?.contentItems = contentItems
                        }
                    }
                    
                    var attachments: [PostAttachment] = []
                    if let fileBox = try? doc.select("div.b-file-box").first() {
                        let fileLinks = try fileBox.select("a")
                        for link in fileLinks {
                            let name = try link.text()
                            let url = try link.attr("href")
                            
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
        guard let range = link.range(of: "articleNo=") else {
            return nil
        }
        
        let start = range.upperBound
        let remainingString = String(link[start...])
        
        if let endRange = remainingString.range(of: "&") {
            return String(remainingString[..<endRange.lowerBound])
        } else {
            return remainingString
        }
    }

/*extension TextAlignment {
    var frameAlignment: Alignment {
        switch self {
            case .center: return .center
            case .leading: return .leading
            case .trailing: return .trailing
            @unknown default: return .leading } } }
*/
