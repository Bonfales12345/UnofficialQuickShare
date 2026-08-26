UnofficialQuickShare is a fork of **NearDrop** With more features.


**NearDrop** is a partial implementation of [Google's Nearby Share](https://blog.google/products/android/nearby-share/)/Quick Share for macOS.

[Protocol documentation](/PROTOCOL.md) is available separately.

The app lives in your menu bar and saves files to your downloads folder. It's that simple, really.

## Limitations

* **Wi-Fi LAN only**. Your Android device and your Mac need to be on the same network for this app to work. Google's implementation supports multiple mediums, including Wi-Fi Direct, Wi-Fi hotspot, Bluetooth, some kind of 5G peer-to-peer connection, and even a WebRTC-based protocol that goes over the internet through Google servers. Wi-Fi direct isn't supported on macOS (Apple has their own, incompatible, AWDL thing, used in AirDrop). Bluetooth needs further reverse engineering.
* **Visible to everyone on your network at all times** while the app is running. Limited visibility (contacts etc) requires talking to Google servers, and becoming temporarily visible requires listening for whatever triggers the "device nearby is sharing" notification.

This app Does Not support sending files from your Mac to your Android device.
