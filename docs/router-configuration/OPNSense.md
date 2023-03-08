# OPNSense
You will need to 
1. Make sure the Honeypot is using a static IP address
2. Connection attempts are forwarded to the honeypot

## Configuring a Static IP address

### Retrieve Honeypot's MAC address

OPNSense does allow "DHCP Static Mappings". To configure them, you will first need the MAC address for the honeypots interface.  On the honeypot, enter:
```
ip addr show
```
The output will look like:
/Screen Shot 2021-05-04 at 9.51.48 AM.png
The MAC address, ```b8:27:eb:75:7a:fa``` in this example, is underlined in red. If you are using a Raspberry Pi, ```eth0``` is usually used for the wired interface. ```wlan0``` refers to the built in WiFi interface. The example above also shows a USB WiFi card as ```wlan1```.

Some users find the output of ```ifconfig``` easier to read than ```ip```, but ```ifconfig``` is not always installed by default.

### Configure Static IP address for OPNSenses

