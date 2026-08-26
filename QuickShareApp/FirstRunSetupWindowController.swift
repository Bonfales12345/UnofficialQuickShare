import Cocoa
import NearbyShare

class FirstRunSetupWindowController: NSWindowController{

	private var pathField:NSTextField!
	private var onComplete:(() -> Void)?

	convenience init(onComplete: @escaping () -> Void){
		let window=NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 460, height: 220),
			styleMask: [.titled, .closable],
			backing: .buffered,
			defer: false
		)
		window.title=NSLocalizedString("FirstRun.Title", value: "Welcome to QuickShare", comment: "")
		window.center()
		window.isReleasedWhenClosed=false
		self.init(window: window)
		self.onComplete=onComplete
		buildContent()
	}

	private func buildContent(){
		guard let window=self.window else {return}
		let contentView=NSView(frame: window.contentView!.bounds)
		contentView.autoresizingMask=[.width, .height]

		let iconView=NSImageView()
		iconView.image=NSImage(named: "AppIcon") ?? NSImage(named: NSImage.applicationIconName)
		iconView.translatesAutoresizingMaskIntoConstraints=false

		let titleLabel=NSTextField(labelWithString: NSLocalizedString("FirstRun.Heading", value: "Where should QuickShare save files you receive?", comment: ""))
		titleLabel.font=NSFont.boldSystemFont(ofSize: 15)
		titleLabel.lineBreakMode = .byWordWrapping
		titleLabel.maximumNumberOfLines=2
		titleLabel.translatesAutoresizingMaskIntoConstraints=false

		let subtitleLabel=NSTextField(wrappingLabelWithString: NSLocalizedString("FirstRun.Subheading", value: "Files sent to you from nearby devices will be saved here. You can change this anytime from the menu bar.", comment: ""))
		subtitleLabel.font=NSFont.systemFont(ofSize: 12)
		subtitleLabel.textColor = .secondaryLabelColor
		subtitleLabel.translatesAutoresizingMaskIntoConstraints=false

		let pathField=NSTextField(string: SaveLocationManager.shared.currentSaveLocationURL().path)
		pathField.isEditable=false
		pathField.isSelectable=true
		pathField.font=NSFont.systemFont(ofSize: 12)
		pathField.translatesAutoresizingMaskIntoConstraints=false
		pathField.lineBreakMode = .byTruncatingMiddle
		self.pathField=pathField

		let pathBackground=NSView()
		pathBackground.wantsLayer=true
		pathBackground.layer?.backgroundColor=NSColor.controlBackgroundColor.cgColor
		pathBackground.layer?.cornerRadius=6
		pathBackground.layer?.borderWidth=1
		pathBackground.layer?.borderColor=NSColor.separatorColor.cgColor
		pathBackground.translatesAutoresizingMaskIntoConstraints=false
		pathBackground.addSubview(pathField)

		let chooseButton=NSButton(title: NSLocalizedString("FirstRun.ChooseFolder", value: "Choose Folder…", comment: ""), target: self, action: #selector(chooseFolderTapped))
		chooseButton.bezelStyle = .rounded
		chooseButton.translatesAutoresizingMaskIntoConstraints=false

		let useDefaultButton=NSButton(title: NSLocalizedString("FirstRun.UseDownloads", value: "Use Downloads", comment: ""), target: self, action: #selector(useDefaultTapped))
		useDefaultButton.bezelStyle = .rounded
		useDefaultButton.translatesAutoresizingMaskIntoConstraints=false

		let doneButton=NSButton(title: NSLocalizedString("FirstRun.Done", value: "Done", comment: ""), target: self, action: #selector(doneTapped))
		doneButton.bezelStyle = .rounded
		doneButton.keyEquivalent="\r"
		doneButton.translatesAutoresizingMaskIntoConstraints=false

		contentView.addSubview(iconView)
		contentView.addSubview(titleLabel)
		contentView.addSubview(subtitleLabel)
		contentView.addSubview(pathBackground)
		contentView.addSubview(chooseButton)
		contentView.addSubview(useDefaultButton)
		contentView.addSubview(doneButton)

		NSLayoutConstraint.activate([
			iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
			iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
			iconView.widthAnchor.constraint(equalToConstant: 48),
			iconView.heightAnchor.constraint(equalToConstant: 48),

			titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
			titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
			titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

			subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
			subtitleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
			subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

			pathBackground.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
			pathBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
			pathBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
			pathBackground.heightAnchor.constraint(equalToConstant: 28),

			pathField.leadingAnchor.constraint(equalTo: pathBackground.leadingAnchor, constant: 8),
			pathField.trailingAnchor.constraint(equalTo: pathBackground.trailingAnchor, constant: -8),
			pathField.centerYAnchor.constraint(equalTo: pathBackground.centerYAnchor),

			chooseButton.topAnchor.constraint(equalTo: pathBackground.bottomAnchor, constant: 12),
			chooseButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

			useDefaultButton.topAnchor.constraint(equalTo: pathBackground.bottomAnchor, constant: 12),
			useDefaultButton.leadingAnchor.constraint(equalTo: chooseButton.trailingAnchor, constant: 8),

			doneButton.topAnchor.constraint(equalTo: pathBackground.bottomAnchor, constant: 12),
			doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
			doneButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
		])

		window.contentView=contentView
	}

	@objc private func chooseFolderTapped(){
		let panel=NSOpenPanel()
		panel.canChooseFiles=false
		panel.canChooseDirectories=true
		panel.allowsMultipleSelection=false
		panel.canCreateDirectories=true
		panel.prompt=NSLocalizedString("FirstRun.SelectPrompt", value: "Select", comment: "")
		panel.directoryURL=SaveLocationManager.shared.currentSaveLocationURL()
		panel.message=NSLocalizedString("FirstRun.PanelMessage", value: "Choose a folder where QuickShare should save files you receive.", comment: "")

		panel.beginSheetModal(for: self.window!) { response in
			guard response == .OK, let url=panel.url else {return}
			if SaveLocationManager.shared.setSaveLocation(url){
				self.pathField.stringValue=url.path
			}
		}
	}

	@objc private func useDefaultTapped(){
		SaveLocationManager.shared.resetToDefaultLocation()
		pathField.stringValue=SaveLocationManager.shared.currentSaveLocationURL().path
	}

	@objc private func doneTapped(){
		SaveLocationManager.shared.markFirstRunSetupCompleted()
		self.window?.close()
		onComplete?()
	}
}
