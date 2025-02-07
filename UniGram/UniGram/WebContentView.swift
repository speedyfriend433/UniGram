//
//  WebContentView.swift
//  UniGram
//
//  Created by 이지안 on 2/8/25.
//

import SwiftUI
import WebKit

struct WebContentView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false // Disable scrolling within WebView
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Create HTML document with proper styling
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 16px;
                    line-height: 1.5;
                    margin: 0;
                    padding: 0;
                    background-color: transparent;
                }
                
                table {
                    width: 100% !important;
                    border-collapse: collapse;
                    margin: 10px 0;
                }
                
                td, th {
                    border: 1px solid #ccc;
                    padding: 8px;
                    text-align: left;
                }
                
                img {
                    max-width: 100%;
                    height: auto;
                }
                
                @media (prefers-color-scheme: dark) {
                    body { color: #FFFFFF; }
                    table { border-color: #444; }
                    td, th { border-color: #444; }
                }
            </style>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: nil)
        
        // Adjust WebView height to content
        webView.evaluateJavaScript("document.readyState") { complete, _ in
            if complete != nil {
                webView.evaluateJavaScript("document.body.scrollHeight") { height, _ in
                    if let height = height as? CGFloat {
                        DispatchQueue.main.async {
                            webView.frame.size.height = height
                        }
                    }
                }
            }
        }
    }
}
