import Foundation

public class DeviceNameManager{
	public static let shared=DeviceNameManager()

	private static let customNameDefaultsKey="CustomDeviceName"
	public static let deviceNameDidChangeNotification=Notification.Name("DeviceNameManagerDeviceNameDidChange")

	private init(){}

	public var defaultName:String{
		return Host.current().localizedName ?? ProcessInfo.processInfo.hostName
	}

	public var hasCustomName:Bool{
		return UserDefaults.standard.string(forKey: DeviceNameManager.customNameDefaultsKey) != nil
	}

	public var currentName:String{
		if let custom=UserDefaults.standard.string(forKey: DeviceNameManager.customNameDefaultsKey), !custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
			return custom
		}
		return defaultName
	}

	@discardableResult
	public func setCustomName(_ name:String) -> Bool{
		let trimmed=name.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else {return false}
		let truncated=String(trimmed.prefix(100))
		UserDefaults.standard.set(truncated, forKey: DeviceNameManager.customNameDefaultsKey)
		NotificationCenter.default.post(name: DeviceNameManager.deviceNameDidChangeNotification, object: self)
		return true
	}

	public func resetToDefaultName(){
		UserDefaults.standard.removeObject(forKey: DeviceNameManager.customNameDefaultsKey)
		NotificationCenter.default.post(name: DeviceNameManager.deviceNameDidChangeNotification, object: self)
	}
}
