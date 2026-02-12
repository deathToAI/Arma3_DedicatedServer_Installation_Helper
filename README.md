# Arma 3 Installation Script for Linux hosted dedicated servers

This software was developed with the purpose of making the install and basic configuring of an Arma 3(with or without mods) a little bit more intuitive.

The step by step i followed was in this three part tutorial:

**1. [Part 1: Getting Started ](https://www.youtube.com/watch?v=iq-s9xXTEMs&t=2s)**

**2. [Part 2: Server configuration ](https://www.youtube.com/watch?v=YZq_uFi7o3s)**

**3. [Part 3: Steam workshop mods ](https://www.youtube.com/watch?v=YA89e6VJ63M)**


**I'm, in no way, associated with the author of this video**, it just helped me a lot when i was hours into trying to configure the server with no success.

# Install and use
Before running:
1. Edit `.creds.sh` to your steam account(Arma 3 needs a steam account as seen on https://developer.valvesoftware.com/wiki/Dedicated_Servers_List)

2. Edit the mods you want to download at ./ExampleFiles/functions.sh `declare_mods` function. Comment those which you don´t want.

3. Download the shellscript and run it, sudo or root permissions may be needed as it may need to install curl,steamcmd or edit services in systemd. 
Obs: It will at first try to add steamcmd repositories, install curl and net-tools as they are needed for the script to run properly(ish).

`git clone https://github.com/deathToAI/Arma3_DedicatedServer_Installation_Helper.git` 

It will present you with options (see image below), and you can select one.

<img width="924" height="532" alt="Options Screenshot" src="https://github.com/user-attachments/assets/4e8763e6-0729-4d0a-a5bf-d457338e8ae0" />

# Improvements

The entire code is free to use and modify as you see fit.

**I’m not a professional programmer**, I just like tech stuff and gaming, so if you see a way to improve it, make a pull request, and I’ll be happy to be in touch and consider changes.

>Simple does it.
