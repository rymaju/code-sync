# code-sync

## Fast Code Sharing for DrRacket

### WARNING

This project is very experimental.

### What this is NOT (yet)

A Live-Share plugin ala VSCode for DrRacket. Its kind of hard to get it to work right, keep things fast, and not break the server.

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
