# UniGram

UniGram is an iOS application that aggregates and displays university announcements and notifications directly from the Hallym University website. 
The app parses rich HTML content—including text, images, tables, and attachments—using SwiftUI and SwiftSoup, presenting the notifications with a modern, intuitive interface.


## Features

- Post Aggregation:
  Retrieve both pinned and regular university notifications from the official website.

- Rich Content Parsing:
  Extract and display various HTML elements such as paragraphs, images (img.fr-fic), tables (along with headers and rows), and special text alignments (e.g., centered text).

- File Downloading:
  Supports downloading attachments (e.g., HWP, PDF) with progress indication and integration with the share sheet for saving or opening files.

- Modern UI/UX:
  Uses SwiftUI to present notifications and detailed posts in a card-based layout with elegant typography, shadows, and dynamic content views.


## Requirements

- Xcode 12 or later
- iOS 15 or higher
- Swift 5
- (SwiftSoup)[https://github.com/scinfu/SwiftSoup] (managed via Swift Package Manager)


## Installation

1. Clone the Repository:

```bash
git clone https://github.com/speedyfriend67/UniGram.git
```

2. Open in Xcode:

```bash
cd UniGram
open UniGram.xcodeproj
```

3. Install Dependencies:

The project uses Swift Package Manager. In Xcode, go to File > Swift Packages > Add Package Dependency... and add:

```bash
https://github.com/scinfu/SwiftSoup.git
```

4. Configure Info.plist:

Add the following keys to your Info.plist file for file sharing and document handling:

```bash
LSSupportsOpeningDocumentsInPlace – Boolean: YES
UIFileSharingEnabled – Boolean: YES
```

## Usage

- Run the App:
Build and run the project on a simulator or an iOS device.

- View Notifications:
The main screen shows a list of notifications. Pinned posts appear at the top.

- Detailed Post View:
Tap a notification to view full details. The detail view renders rich HTML content—text, images, tables, etc.—with proper formatting and modern styling.

- Download Attachments:
Tap on an attachment to download and share it using the native share sheet.


## To-Do

- Fix Auto Refresh
- Fix Blank Post Content
- Add Various File Format
- Fix some specific posts not appearing when randomly refresh


## Contributing
Contributions are welcome!

- Fork the repository and create a feature branch for your changes.
- Ensure your code follows the project style and include any necessary tests.
- Submit a pull request with a detailed description of your changes.


## Contact

For any questions or support, please contact:
**speedyfriend67**
Email: speedyfriend433@gmail.com


## License

This project is licensed under the MIT License.
