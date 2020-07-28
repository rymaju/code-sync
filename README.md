# code-sync

## Fast Code Sharing for DrRacket

### WARNING

This project isn't paticularly complex, but it does have some issues. Heres some things that will definitely break the plugin:

- Trying to send an image
- Trying to send a box of any kind
- Really, sending anything that isnt just regular text
- Silently disconnecting (fix coming soon)
- Violently disconnecting (thats kind of on you though)

The master branch is the most recent "stable" version of code-sync whose limitations I describe above. The next version is in the "development" branch, and will hopefully be much cleaner than this mess.


### What this is NOT (yet)

A Live-Share plugin ala VSCode for DrRacket. Its kind of hard to get it to work right, keep things fast, and not break the server.

It is not integrated with git, or anything similar, even though it seems like it might be a good fit. You can only PUSH code to others, **there is no way to ask to PULL code from a room (what does that even mean in a room with 3+ people?)**.

Coming soon maybe: lecture/protected mode where only the first user of a room will be able to broadcast code.

### Features

- Join a "Room", allowing you to remotely send your code to all other users also connected to the room.

- When code is broadcasted to you, you have the option to either accept and overwrite your current code with the new code, or decline and keep your old code.

- Any user in the room can broadcast code, and broadcast code will go to however many users are in a room.

- There is no limit to the number of users in one room (besides the CPU load of my WebSocket server)

- Perfect for quickly distibuting copies of your code.

### About

The plugin on the client side is just adding some new buttons to DrRacket, and using an existing WebSocket implementation to communicate with a backend WebSocket server. You can see all the code for the server [here](https://github.com/rymaju/code-sync-server).

Why WebSockets? Because its easy and allows an arbitrary number of people to join the same "Room".

Suggestions and new issues are welcomed. Contributions and clean PR's are greatly welcomed.


### TODO

So many things.

For one, we could make this a live-share type app. Honestly, sounds kind of like a bad idea though. For one, its hard to implement. Secondly, kind of breaks the idea of pair programming (driver, navgiator) by blurring the lines.

Another much better idea: have a git-like implementation where you can push/pull from a source. Can do this manually with a server, but probably much smart to hook this up to GitHub somehow. Maybe creating/loading gists if possible. This would require some work to get integration to work properly.

In the meantime, a proof of concept can be done. Probablly wanna do it in another repo and another plugin forked from this. All we need is a MongoDB/Redis sitution to store the code in each room. 

Another idea we can get rid of websockets in favor of regular http requests IF we dont care about realtime notifications of code being shared, but it might be cool to keep that in.
