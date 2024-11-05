
# Blackb0x
 Apple TV 2/3 Jailbreak [Download here](https://github.com/NSSpiral/Blackb0x/releases)


Untethered jailbreak tool that runs on modern versions of macOS (10.11+). 


Devices supported: 
- Apple TV 3,2 (A1469) (tvOS 8.4.x untethered, tvOS 7.x tethered)
- Apple TV 3,1 (A1427) (tvOS 8.4.x untethered, tvOS 7.x tethered)
- Apple TV 2,1 (A1378) (tvOS 7.1.2 tethered, tvOS 6.1.4 untethered)

![Screen Shot 2021-07-07 at 9 49 07 pm](https://user-images.githubusercontent.com/32339783/124758042-8c1de500-df71-11eb-8db3-32a34e2ed3a2.png)

IMPORTANT: 
Make sure your device is connected to the internet for the first boot. Do not turn off during first boot until Kodi appears.

## Steps to Jailbreak: 

0. (3,1 Only) PWN with Arduino + [synackuk's fork of checkm8-A5](https://github.com/synackuk/checkm8-a5)
1. Plug in your Apple TV via micro-USB **AND** plug in the power cable.
2. Open Blackb0x - Right click Blackb0x.app then click Open *(Important)*
3. Click Jailbreak.
4. Follow instructions to enter DFU mode
5. Once Jailbreak has finished installing connect to your tv and wait 5-10 minutes until Kodi appears (Be patient, go have a coffee).
6. If Kodi does not appear force install it:
   ```
   ssh -oHostKeyAlgorithms=+ssh-rsa root@apple-tv.local
   ```
7. The password is `alpine`
   ```
   apt-get -y --force-yes install org.xbmc.kodi-atv2
   ```


<br>

## Credits
**nyan_satan**
* libbootkit (iBSS loader for AppleTV3,2)

**dora2ios**
* iBSS loader for AppleTV3,1

**tihmstar**
* etasonATV jsc untether
* answering questions about patches

**zzanehip**
* updated CBPatcher (Created by Jonathan Seals)
* updated iBoot32Patcher (Created by iH8sn0w)
* updated xpwntool (Created by planetbeing)

**a1exdandy, synackuk, nyan_satan**
* checkm8-A5

**axi0mx**
* checkm8

**p0sixninja**
* SHAtter
