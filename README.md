# code-sync

## Fast Code Sharing for DrRacket

### Features

- Join a "Room", allowing you to remotely send your code to all other users also connected to the room.

- When code is broadcasted to you, you have the option to either accept and overwrite your current code with the new code, or decline and keep your old code.

- Any user in the room can broadcast code, and broadcast code will go to however many users are in a room.

- There is no limit to the number of users in one room (besides the CPU load my WebSocket server)

- Perfect for quickly distibuting copies of your code.

### About

The plugin on the client side is just adding some new buttons to DrRacket, and using an existing WebSocket implementation to communicate with a backend WebSocket server.

Why WebSockets? Because its easy and allows an arbitrary number of people to join the same "Room".

Suggestions and new issues are welcomed. Contributions and clean PR's are greatly welcomed.
