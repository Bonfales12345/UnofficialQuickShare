import Cocoa
import NearbyShare

class SendFilesWindowController: NSWindowController, ShareExtensionDelegate{

	private var urls:[URL]=[]
	private var foundDevices:[RemoteDeviceInfo]=[]
	private var chosenDevice:RemoteDeviceInfo?
	private var lastError:Error?
	private var isDiscovering=false

	private var filesLabel:NSTextField!
	private var filesIcon:NSImageView!
	private var chooseFilesButton:NSButton!
	private var statusLabel:NSTextField!
	private var deviceTableView:NSTableView!
	private var deviceScrollView:NSScrollView!
	private var loadingIndicator:NSProgressIndicator!
	private var progressStack:NSStackView!
	private var progressBar:NSProgressIndicator!
	private var progressStateLabel:NSTextField!
	private var progressDeviceLabel:NSTextField!
	private var cancelButton:NSButton!

	convenience init(){
		let window=NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 420, height: 460),
			styleMask: [.titled, .closable, .miniaturizable],
			backing: .buffered,
			defer: false
		)
		window.title=NSLocalizedString("SendFiles.Title", value: "Send Files", comment: "")
		window.center()
		window.isReleasedWhenClosed=false
		self.init(window: window)
		buildContent()
	}

	private func buildContent(){
		guard let window=self.window else {return}
		let contentView=NSView(frame: window.contentView!.bounds)
		contentView.autoresizingMask=[.width, .height]

		let filesIcon=NSImageView()
		filesIcon.image=NSImage(named: NSImage.multipleDocumentsName)
		filesIcon.translatesAutoresizingMaskIntoConstraints=false
		self.filesIcon=filesIcon

		let filesLabel=NSTextField(labelWithString: NSLocalizedString("SendFiles.NoFilesChosen", value: "No files chosen", comment: ""))
		filesLabel.font=NSFont.systemFont(ofSize: 13)
		filesLabel.lineBreakMode = .byTruncatingMiddle
		filesLabel.translatesAutoresizingMaskIntoConstraints=false
		self.filesLabel=filesLabel

		let chooseFilesButton=NSButton(title: NSLocalizedString("SendFiles.ChooseFiles", value: "Choose Files…", comment: ""), target: self, action: #selector(chooseFilesTapped))
		chooseFilesButton.bezelStyle = .rounded
		chooseFilesButton.translatesAutoresizingMaskIntoConstraints=false
		self.chooseFilesButton=chooseFilesButton

		let divider=NSBox()
		divider.boxType = .separator
		divider.translatesAutoresizingMaskIntoConstraints=false

		let statusLabel=NSTextField(labelWithString: NSLocalizedString("SendFiles.ChooseADevice", value: "Choose a device to send to:", comment: ""))
		statusLabel.font=NSFont.systemFont(ofSize: 12)
		statusLabel.textColor = .secondaryLabelColor
		statusLabel.translatesAutoresizingMaskIntoConstraints=false
		self.statusLabel=statusLabel

		let deviceTableView=NSTableView()
		let column=NSTableColumn(identifier: NSUserInterfaceItemIdentifier("device"))
		column.title=NSLocalizedString("SendFiles.DeviceColumn", value: "Device", comment: "")
		deviceTableView.addTableColumn(column)
		deviceTableView.headerView=nil
		deviceTableView.rowHeight=44
		deviceTableView.dataSource=self
		deviceTableView.delegate=self
		deviceTableView.target=self
		deviceTableView.doubleAction=#selector(deviceRowDoubleClicked)
		deviceTableView.backgroundColor = .clear

		let deviceScrollView=NSScrollView()
		deviceScrollView.documentView=deviceTableView
		deviceScrollView.hasVerticalScroller=true
		deviceScrollView.borderType = .bezelBorder
		deviceScrollView.translatesAutoresizingMaskIntoConstraints=false
		self.deviceScrollView=deviceScrollView
		self.deviceTableView=deviceTableView

		let loadingIndicator=NSProgressIndicator()
		loadingIndicator.style = .spinning
		loadingIndicator.controlSize = .small
		loadingIndicator.translatesAutoresizingMaskIntoConstraints=false
		loadingIndicator.startAnimation(nil)
		self.loadingIndicator=loadingIndicator

		let loadingLabel=NSTextField(labelWithString: NSLocalizedString("SendFiles.Searching", value: "Looking for nearby devices…", comment: ""))
		loadingLabel.font=NSFont.systemFont(ofSize: 12)
		loadingLabel.textColor = .secondaryLabelColor
		loadingLabel.translatesAutoresizingMaskIntoConstraints=false

		let loadingStack=NSStackView(views: [loadingIndicator, loadingLabel])
		loadingStack.orientation = .horizontal
		loadingStack.spacing=8
		loadingStack.translatesAutoresizingMaskIntoConstraints=false

		let progressBar=NSProgressIndicator()
		progressBar.style = .bar
		progressBar.isIndeterminate=true
		progressBar.minValue=0
		progressBar.maxValue=1000
		progressBar.translatesAutoresizingMaskIntoConstraints=false
		self.progressBar=progressBar

		let progressDeviceLabel=NSTextField(labelWithString: "")
		progressDeviceLabel.font=NSFont.boldSystemFont(ofSize: 13)
		progressDeviceLabel.alignment = .center
		progressDeviceLabel.translatesAutoresizingMaskIntoConstraints=false
		self.progressDeviceLabel=progressDeviceLabel

		let progressStateLabel=NSTextField(labelWithString: "")
		progressStateLabel.font=NSFont.systemFont(ofSize: 12)
		progressStateLabel.textColor = .secondaryLabelColor
		progressStateLabel.alignment = .center
		progressStateLabel.translatesAutoresizingMaskIntoConstraints=false
		self.progressStateLabel=progressStateLabel

		let progressStack=NSStackView(views: [progressDeviceLabel, progressStateLabel, progressBar])
		progressStack.orientation = .vertical
		progressStack.spacing=10
		progressStack.alignment = .centerX
		progressStack.translatesAutoresizingMaskIntoConstraints=false
		progressStack.isHidden=true
		self.progressStack=progressStack

		let cancelButton=NSButton(title: NSLocalizedString("Cancel", value: "Cancel", comment: ""), target: self, action: #selector(cancelTapped))
		cancelButton.bezelStyle = .rounded
		cancelButton.translatesAutoresizingMaskIntoConstraints=false
		self.cancelButton=cancelButton

		contentView.addSubview(filesIcon)
		contentView.addSubview(filesLabel)
		contentView.addSubview(chooseFilesButton)
		contentView.addSubview(divider)
		contentView.addSubview(statusLabel)
		contentView.addSubview(deviceScrollView)
		contentView.addSubview(loadingStack)
		contentView.addSubview(progressStack)
		contentView.addSubview(cancelButton)

		NSLayoutConstraint.activate([
			filesIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
			filesIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
			filesIcon.widthAnchor.constraint(equalToConstant: 32),
			filesIcon.heightAnchor.constraint(equalToConstant: 32),

			filesLabel.centerYAnchor.constraint(equalTo: filesIcon.centerYAnchor),
			filesLabel.leadingAnchor.constraint(equalTo: filesIcon.trailingAnchor, constant: 10),
			filesLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),

			chooseFilesButton.topAnchor.constraint(equalTo: filesIcon.bottomAnchor, constant: 10),
			chooseFilesButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

			divider.topAnchor.constraint(equalTo: chooseFilesButton.bottomAnchor, constant: 16),
			divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
			divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

			statusLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14),
			statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

			deviceScrollView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
			deviceScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
			deviceScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
			deviceScrollView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),

			loadingStack.centerXAnchor.constraint(equalTo: deviceScrollView.centerXAnchor),
			loadingStack.centerYAnchor.constraint(equalTo: deviceScrollView.centerYAnchor),

			progressStack.centerXAnchor.constraint(equalTo: deviceScrollView.centerXAnchor),
			progressStack.centerYAnchor.constraint(equalTo: deviceScrollView.centerYAnchor),
			progressStack.widthAnchor.constraint(equalTo: deviceScrollView.widthAnchor, constant: -40),
			progressBar.widthAnchor.constraint(equalTo: progressStack.widthAnchor),

			cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
			cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
		])

		window.contentView=contentView
		window.delegate=self
	}

	override func showWindow(_ sender: Any?){
		super.showWindow(sender)
		NSApp.activate(ignoringOtherApps: true)
		startDiscoveryIfNeeded()
	}

	private func startDiscoveryIfNeeded(){
		guard !isDiscovering else {return}
		isDiscovering=true
		NearbyConnectionManager.shared.startDeviceDiscovery()
		NearbyConnectionManager.shared.addShareExtensionDelegate(self)
	}

	private func stopDiscoveryIfNeeded(){
		guard isDiscovering else {return}
		isDiscovering=false
		NearbyConnectionManager.shared.stopDeviceDiscovery()
		NearbyConnectionManager.shared.removeShareExtensionDelegate(self)
	}

	@objc private func chooseFilesTapped(){
		let panel=NSOpenPanel()
		panel.canChooseFiles=true
		panel.canChooseDirectories=false
		panel.allowsMultipleSelection=true
		panel.prompt=NSLocalizedString("SendFiles.SelectPrompt", value: "Select", comment: "")
		panel.message=NSLocalizedString("SendFiles.PanelMessage", value: "Choose one or more files to send to a nearby device.", comment: "")

		panel.beginSheetModal(for: self.window!) { response in
			guard response == .OK else {return}
			self.urls=panel.urls
			self.updateFilesSummary()
		}
	}

	private func updateFilesSummary(){
		if urls.isEmpty{
			filesLabel.stringValue=NSLocalizedString("SendFiles.NoFilesChosen", value: "No files chosen", comment: "")
			filesIcon.image=NSImage(named: NSImage.multipleDocumentsName)
		}else if urls.count==1{
			filesLabel.stringValue=urls[0].lastPathComponent
			filesIcon.image=NSWorkspace.shared.icon(forFile: urls[0].path)
		}else{
			filesLabel.stringValue=String.localizedStringWithFormat(NSLocalizedString("NFiles", value: "%d files", comment: ""), urls.count)
			filesIcon.image=NSImage(named: NSImage.multipleDocumentsName)
		}
	}

	@objc private func deviceRowDoubleClicked(){
		let row=deviceTableView.clickedRow
		guard row>=0, row<foundDevices.count else {return}
		selectDevice(device: foundDevices[row])
	}

	@objc private func cancelTapped(){
		if let device=chosenDevice{
			NearbyConnectionManager.shared.cancelOutgoingTransfer(id: device.id!)
		}
		self.window?.close()
	}

	private func selectDevice(device:RemoteDeviceInfo){
		guard !urls.isEmpty else{
			let alert=NSAlert()
			alert.messageText=NSLocalizedString("SendFiles.NoFilesAlert.Title", value: "Choose files first", comment: "")
			alert.informativeText=NSLocalizedString("SendFiles.NoFilesAlert.Message", value: "Pick one or more files to send before choosing a device.", comment: "")
			alert.beginSheetModal(for: self.window!, completionHandler: nil)
			return
		}
		stopDiscoveryIfNeeded()
		deviceScrollView.animator().isHidden=true
		progressStack.animator().isHidden=false
		chooseFilesButton.isEnabled=false
		progressDeviceLabel.stringValue=device.name
		progressStateLabel.stringValue=NSLocalizedString("Connecting", value: "Connecting...", comment: "")
		progressBar.isIndeterminate=true
		progressBar.startAnimation(nil)
		chosenDevice=device
		NearbyConnectionManager.shared.startOutgoingTransfer(deviceID: device.id!, delegate: self, urls: urls)
	}

	private func dismissDelayed(){
		DispatchQueue.main.asyncAfter(deadline: .now()+1.5){
			self.window?.close()
		}
	}

	func addDevice(device: RemoteDeviceInfo){
		if foundDevices.isEmpty{
			loadingIndicator.superview?.isHidden=true
		}
		foundDevices.append(device)
		deviceTableView.reloadData()
	}

	func removeDevice(id: String){
		if chosenDevice != nil{
			return
		}
		foundDevices.removeAll(where: {$0.id==id})
		deviceTableView.reloadData()
		if foundDevices.isEmpty{
			loadingIndicator.superview?.isHidden=false
		}
	}

	func startTransferWithQrCode(device: RemoteDeviceInfo){

		selectDevice(device: device)
	}

	func connectionWasEstablished(pinCode: String){
		progressStateLabel.stringValue=String(format: NSLocalizedString("PinCode", value: "PIN: %@", comment: ""), arguments: [pinCode])
		progressBar.isIndeterminate=false
		progressBar.doubleValue=0
	}

	func connectionFailed(with error: Error){
		progressBar.isIndeterminate=false
		progressBar.doubleValue=0
		lastError=error
		if let ne=(error as? NearbyError), case let .canceled(reason)=ne{
			switch reason{
			case .userRejected:
				progressStateLabel.stringValue=NSLocalizedString("TransferDeclined", value: "Declined", comment: "")
			case .userCanceled:
				progressStateLabel.stringValue=NSLocalizedString("TransferCanceled", value: "Canceled", comment: "")
			case .notEnoughSpace:
				progressStateLabel.stringValue=NSLocalizedString("NotEnoughSpace", value: "Not enough disk space", comment: "")
			case .unsupportedType:
				progressStateLabel.stringValue=NSLocalizedString("UnsupportedType", value: "Attachment type not supported", comment: "")
			case .timedOut:
				progressStateLabel.stringValue=NSLocalizedString("TransferTimedOut", value: "Timed out", comment: "")
			}
			dismissDelayed()
		}else{
			let alert=NSAlert(error: error)
			alert.beginSheetModal(for: self.window!, completionHandler: nil)
		}
	}

	func transferAccepted(){
		progressStateLabel.stringValue=NSLocalizedString("Sending", value: "Sending...", comment: "")
	}

	func transferProgress(progress: Double){
		progressBar.doubleValue=progress*progressBar.maxValue
	}

	func transferFinished(){
		progressStateLabel.stringValue=NSLocalizedString("TransferFinished", value: "Transfer finished", comment: "")
		dismissDelayed()
	}
}

extension SendFilesWindowController: NSTableViewDataSource, NSTableViewDelegate{
	func numberOfRows(in tableView: NSTableView) -> Int{
		return foundDevices.count
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
		let device=foundDevices[row]
		let identifier=NSUserInterfaceItemIdentifier("DeviceCell")

		let cellView:NSTableCellView
		if let reused=tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView{
			cellView=reused
		}else{
			cellView=NSTableCellView()
			cellView.identifier=identifier

			let imageView=NSImageView()
			imageView.translatesAutoresizingMaskIntoConstraints=false
			cellView.imageView=imageView
			cellView.addSubview(imageView)

			let textField=NSTextField(labelWithString: "")
			textField.translatesAutoresizingMaskIntoConstraints=false
			cellView.textField=textField
			cellView.addSubview(textField)

			NSLayoutConstraint.activate([
				imageView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 8),
				imageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
				imageView.widthAnchor.constraint(equalToConstant: 28),
				imageView.heightAnchor.constraint(equalToConstant: 28),

				textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
				textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8),
				textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
			])
		}

		cellView.textField?.stringValue=device.name
		cellView.imageView?.image=imageForDeviceType(type: device.type)
		return cellView
	}

	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool{
		return true
	}
}

extension SendFilesWindowController: NSWindowDelegate{
	func windowWillClose(_ notification: Notification){
		stopDiscoveryIfNeeded()
	}
}

fileprivate func imageForDeviceType(type:RemoteDeviceInfo.DeviceType)->NSImage{
	let imageName:String
	switch type{
	case .tablet:
		imageName="com.apple.ipad"
	case .computer:
		imageName="com.apple.macbookpro-13-unibody"
	default:
		imageName="com.apple.iphone"
	}
	return NSImage(contentsOfFile: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/\(imageName).icns") ?? NSImage(named: NSImage.computerName)!
}
