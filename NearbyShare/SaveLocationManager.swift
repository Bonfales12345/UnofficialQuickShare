import Foundation

public class SaveLocationManager{
	public static let shared=SaveLocationManager()

	private static let bookmarkDefaultsKey="SaveLocationBookmark"
	private static let hasCompletedFirstRunKey="HasCompletedFirstRunSetup"

	private var cachedURL:URL?
	private var isAccessingSecurityScopedResource=false

	private init(){}

	public var hasCompletedFirstRunSetup:Bool{
		return UserDefaults.standard.bool(forKey: SaveLocationManager.hasCompletedFirstRunKey)
	}

	public func markFirstRunSetupCompleted(){
		UserDefaults.standard.set(true, forKey: SaveLocationManager.hasCompletedFirstRunKey)
	}

	public var defaultDownloadsURL:URL{
		return (try? FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true))?.resolvingSymlinksInPath()
			?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
	}

	public var hasCustomLocation:Bool{
		return UserDefaults.standard.data(forKey: SaveLocationManager.bookmarkDefaultsKey) != nil
	}

	public var displayPath:String{
		return currentSaveLocationURL().path
	}

	@discardableResult
	public func setSaveLocation(_ url:URL) -> Bool{
		do{
			let bookmark=try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
			UserDefaults.standard.set(bookmark, forKey: SaveLocationManager.bookmarkDefaultsKey)
			stopAccessingIfNeeded()
			cachedURL=nil
			return true
		}catch{
			print("Error creating security-scoped bookmark for \(url): \(error)")
			return false
		}
	}

	public func resetToDefaultLocation(){
		stopAccessingIfNeeded()
		cachedURL=nil
		UserDefaults.standard.removeObject(forKey: SaveLocationManager.bookmarkDefaultsKey)
	}

	public func currentSaveLocationURL() -> URL{
		if let cached=cachedURL{
			return cached
		}
		guard let bookmarkData=UserDefaults.standard.data(forKey: SaveLocationManager.bookmarkDefaultsKey) else{
			return defaultDownloadsURL
		}
		do{
			var isStale=false
			let url=try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
			guard url.startAccessingSecurityScopedResource() else{
				print("Failed to access security-scoped resource for saved download location, falling back to Downloads")
				return defaultDownloadsURL
			}
			isAccessingSecurityScopedResource=true
			if isStale{

				if let refreshed=try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil){
					UserDefaults.standard.set(refreshed, forKey: SaveLocationManager.bookmarkDefaultsKey)
				}
			}
			cachedURL=url
			return url
		}catch{
			print("Error resolving saved download location bookmark: \(error). Falling back to Downloads.")
			return defaultDownloadsURL
		}
	}

	private func stopAccessingIfNeeded(){
		if isAccessingSecurityScopedResource, let url=cachedURL{
			url.stopAccessingSecurityScopedResource()
			isAccessingSecurityScopedResource=false
		}
	}
}
