import Cocoa
import UserNotifications
import NearbyShare

@main
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, MainAppDelegate{
	private var statusItem:NSStatusItem?
	private var activeIncomingTransfers:[String:TransferInfo]=[:]
	private var sendFilesWindowController:SendFilesWindowController?
	private var firstRunWindowController:FirstRunSetupWindowController?
	private var changeSaveLocationMenuItem:NSMenuItem?
	private var deviceNameMenuItem:NSMenuItem?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
		let menu=NSMenu()
		menu.addItem(withTitle: NSLocalizedString("VisibleToEveryone", value: "Visible to everyone", comment: ""), action: nil, keyEquivalent: "")
		let deviceNameItem=NSMenuItem(title: String(format: NSLocalizedString("DeviceName", value: "Device name: %@", comment: ""), arguments: [DeviceNameManager.shared.currentName]), action: nil, keyEquivalent: "")
		menu.addItem(deviceNameItem)
		self.deviceNameMenuItem=deviceNameItem
		menu.addItem(withTitle: NSLocalizedString("ChangeDeviceName.MenuItem", value: "Change Device Name…", comment: ""), action: #selector(changeDeviceNameTapped), keyEquivalent: "")
		menu.addItem(NSMenuItem.separator())
		menu.addItem(withTitle: NSLocalizedString("SendFiles.MenuItem", value: "Send Files…", comment: ""), action: #selector(sendFilesTapped), keyEquivalent: "")
		let changeSaveLocationItem=NSMenuItem(title: NSLocalizedString("ChangeSaveLocation.MenuItem", value: "Change Save Location…", comment: ""), action: #selector(changeSaveLocationTapped), keyEquivalent: "")
		menu.addItem(changeSaveLocationItem)
		self.changeSaveLocationMenuItem=changeSaveLocationItem
		menu.addItem(NSMenuItem.separator())
		menu.addItem(withTitle: NSLocalizedString("Quit", value: "Quit QuickShare", comment: ""), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
		statusItem=NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		statusItem?.button?.image=NSImage(named: "MenuBarIcon")
		statusItem?.menu=menu
		statusItem?.behavior = .removalAllowed

		let nc=UNUserNotificationCenter.current()
		nc.requestAuthorization(options: [.alert, .sound]) { granted, err in
			if !granted{
				DispatchQueue.main.async {
					self.showNotificationsDeniedAlert()
				}
			}
		}
		nc.delegate=self
		let incomingTransfersCategory=UNNotificationCategory(identifier: "INCOMING_TRANSFERS", actions: [
			UNNotificationAction(identifier: "ACCEPT", title: NSLocalizedString("Accept", comment: ""), options: UNNotificationActionOptions.authenticationRequired),
			UNNotificationAction(identifier: "DECLINE", title: NSLocalizedString("Decline", comment: ""))
		], intentIdentifiers: [])
		let errorsCategory=UNNotificationCategory(identifier: "ERRORS", actions: [], intentIdentifiers: [])
		nc.setNotificationCategories([incomingTransfersCategory, errorsCategory])
		NearbyConnectionManager.shared.mainAppDelegate=self

		NotificationCenter.default.addObserver(self, selector: #selector(deviceNameDidChange), name: DeviceNameManager.deviceNameDidChangeNotification, object: nil)

		updateChangeSaveLocationSubtitle()

		if SaveLocationManager.shared.hasCompletedFirstRunSetup{
			NearbyConnectionManager.shared.becomeVisible()
		}else{

			showFirstRunSetup {
				NearbyConnectionManager.shared.becomeVisible()
			}
		}
	}

	private func showFirstRunSetup(onComplete: @escaping () -> Void){
		let controller=FirstRunSetupWindowController(onComplete: { [weak self] in
			self?.updateChangeSaveLocationSubtitle()
			self?.firstRunWindowController=nil
			onComplete()
		})
		self.firstRunWindowController=controller
		NSApp.activate(ignoringOtherApps: true)
		controller.showWindow(nil)
	}

	private func updateChangeSaveLocationSubtitle(){
		let path=SaveLocationManager.shared.currentSaveLocationURL().path
		changeSaveLocationMenuItem?.title=String(format: NSLocalizedString("ChangeSaveLocation.MenuItemWithPath", value: "Save Location: %@", comment: ""), arguments: [(path as NSString).abbreviatingWithTildeInPath])
	}

	@objc private func deviceNameDidChange(){
		deviceNameMenuItem?.title=String(format: NSLocalizedString("DeviceName", value: "Device name: %@", comment: ""), arguments: [DeviceNameManager.shared.currentName])
	}

	@objc private func changeDeviceNameTapped(){
		let alert=NSAlert()
		alert.alertStyle = .informational
		alert.messageText=NSLocalizedString("ChangeDeviceName.Title", value: "Change Device Name", comment: "")
		alert.informativeText=NSLocalizedString("ChangeDeviceName.Message", value: "This is the name other devices will see when you share files.", comment: "")
		alert.addButton(withTitle: NSLocalizedString("ChangeDeviceName.Save", value: "Save", comment: ""))
		alert.addButton(withTitle: NSLocalizedString("Cancel", value: "Cancel", comment: ""))
		alert.addButton(withTitle: NSLocalizedString("ChangeDeviceName.UseDefault", value: "Use Default", comment: ""))

		let textField=NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
		textField.stringValue=DeviceNameManager.shared.currentName
		textField.placeholderString=DeviceNameManager.shared.defaultName
		alert.accessoryView=textField
		alert.window.initialFirstResponder=textField

		NSApp.activate(ignoringOtherApps: true)
		let response=alert.runModal()
		switch response{
		case .alertFirstButtonReturn:
			DeviceNameManager.shared.setCustomName(textField.stringValue)
		case .alertThirdButtonReturn:
			DeviceNameManager.shared.resetToDefaultName()
		default:
			break
		}
	}

	@objc private func sendFilesTapped(){
		if sendFilesWindowController==nil{
			let controller=SendFilesWindowController()
			self.sendFilesWindowController=controller
		}
		sendFilesWindowController?.showWindow(nil)
	}

	@objc private func changeSaveLocationTapped(){
		let panel=NSOpenPanel()
		panel.canChooseFiles=false
		panel.canChooseDirectories=true
		panel.allowsMultipleSelection=false
		panel.canCreateDirectories=true
		panel.prompt=NSLocalizedString("FirstRun.SelectPrompt", value: "Select", comment: "")
		panel.directoryURL=SaveLocationManager.shared.currentSaveLocationURL()
		panel.message=NSLocalizedString("ChangeSaveLocation.PanelMessage", value: "Choose a folder where QuickShare should save files you receive.", comment: "")
		NSApp.activate(ignoringOtherApps: true)
		panel.begin { response in
			guard response == .OK, let url=panel.url else {return}
			if SaveLocationManager.shared.setSaveLocation(url){
				self.updateChangeSaveLocationSubtitle()
			}
		}
	}

	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
		statusItem?.isVisible=true
		return true
	}

    func applicationWillTerminate(_ aNotification: Notification) {
		UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

	func showNotificationsDeniedAlert(){
		let alert=NSAlert()
		alert.alertStyle = .critical
		alert.messageText=NSLocalizedString("NotificationsDenied.Title", value: "Notification Permission Required", comment: "")
		alert.informativeText=NSLocalizedString("NotificationsDenied.Message", value: "QuickShare needs to be able to display notifications for incoming file transfers. Please allow notifications in System Settings.", comment: "")
		alert.addButton(withTitle: NSLocalizedString("NotificationsDenied.OpenSettings", value: "Open settings", comment: ""))
		alert.addButton(withTitle: NSLocalizedString("Quit", value: "Quit QuickShare", comment: ""))
		let result=alert.runModal()
		if result==NSApplication.ModalResponse.alertFirstButtonReturn{
			NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
		}else if result==NSApplication.ModalResponse.alertSecondButtonReturn{
			NSApplication.shared.terminate(nil)
		}
	}

	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		let transferID=response.notification.request.content.userInfo["transferID"]! as! String
		NearbyConnectionManager.shared.submitUserConsent(transferID: transferID, accept: response.actionIdentifier=="ACCEPT")
		if response.actionIdentifier != "ACCEPT"{
			activeIncomingTransfers.removeValue(forKey: transferID)
		}
		completionHandler()
	}

	func obtainUserConsent(for transfer: TransferMetadata, from device: RemoteDeviceInfo) {
		let fileStr:String
		if let textTitle=transfer.textDescription{
			fileStr=textTitle
		}else if transfer.files.count==1{
			fileStr=transfer.files[0].name
		}else{
			fileStr=String.localizedStringWithFormat(NSLocalizedString("NFiles", value: "%d files", comment: ""), transfer.files.count)
		}
		let notificationContent=UNMutableNotificationContent()
		notificationContent.title="QuickShare"
		notificationContent.subtitle=String(format:NSLocalizedString("PinCode", value: "PIN: %@", comment: ""), arguments: [transfer.pinCode!])
		notificationContent.body=String(format: NSLocalizedString("DeviceSendingFiles", value: "%1$@ is sending you %2$@", comment: ""), arguments: [device.name, fileStr])
		notificationContent.sound = .default
		notificationContent.categoryIdentifier="INCOMING_TRANSFERS"
		notificationContent.userInfo=["transferID": transfer.id]
		if #available(macOS 11.0, *){
			QSNotificationCenterHackery.removeDefaultAction(notificationContent)
		}
		let notificationReq=UNNotificationRequest(identifier: "transfer_"+transfer.id, content: notificationContent, trigger: nil)
		UNUserNotificationCenter.current().add(notificationReq)
		self.activeIncomingTransfers[transfer.id]=TransferInfo(device: device, transfer: transfer)
	}

	func incomingTransfer(id: String, didFinishWith error: Error?) {
		guard let transfer=self.activeIncomingTransfers[id] else {return}
		if let error=error{
			let notificationContent=UNMutableNotificationContent()
			notificationContent.title=String(format: NSLocalizedString("TransferError", value: "Failed to receive files from %@", comment: ""), arguments: [transfer.device.name])
			if let ne=(error as? NearbyError){
				switch ne{
				case .inputOutput:
					notificationContent.body="I/O Error";
				case .protocolError(_):
					notificationContent.body=NSLocalizedString("Error.Protocol", value: "Communication error", comment: "")
				case .requiredFieldMissing:
					notificationContent.body=NSLocalizedString("Error.Protocol", value: "Communication error", comment: "")
				case .ukey2:
					notificationContent.body=NSLocalizedString("Error.Crypto", value: "Encryption error", comment: "")
				case .canceled(reason: _):
					break;
				}
			}else{
				notificationContent.body=error.localizedDescription
			}
			notificationContent.categoryIdentifier="ERRORS"
			UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "transferError_"+id, content: notificationContent, trigger: nil))
		}
		UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["transfer_"+id])
		self.activeIncomingTransfers.removeValue(forKey: id)
	}
}

struct TransferInfo{
	let device:RemoteDeviceInfo
	let transfer:TransferMetadata
}
