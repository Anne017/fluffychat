### 7.0:
##### New features
* First stable release
* Implemented URI's: fluffychat://#roomalias:server.abc fluffychat://!roomid:server.abc and fluffychat://@matrixid:server.abc
* Now using the official ubports push gateway
* Repeat to messages
* Forward messages
* Content-hub integration: Share texts and links with fluffychat and export everything from fluffychat
* Redesigned settings
* New more minimalistic chat design
* Offline cache for user avatars
* STICKERS!!!111 Included the great stickerpack of mithgarthsormr (Malin Errenst)
* Add all images you find as stickers
* Animated stickers! Fluffy stickers! Cute stickers!
* More stickers! :-)
* Added animation to the chat list and chat messages
* Bugfixes and stability improvements
* Improved registration (No recaptcha-support yet so no registration on matrix.org possible. Just visit: https://matrix.org/_matrix/client for this)
* Better support for matrix privacy policy

### 0.6.0:
##### New features
* User profiles
* Design improvements
* Audioplayer in chat
* Videoplayer in chat
* Imageviewer
* Edit chat aliases
* Edit chat settings and permissions
* Kick, ban and unban users
* Edit user permissions
* New invite page
* Display and edit chat topics
* Change chat avatar
* Change user avatar
* Edit phone numbers
* Edit email addresses
* Display and edit archived chats
* New add-chat and add-contact pages
* Display contacts and find contacts with their phone number or email address
* Discover public chats on the user's homeserver
* Registration (currently only working with ubports.chat and NOT with matrix.org due captchas)
* Register and login with phone number
* Edit identity-server
* Add in-app viewer for the privacy policy

##### Bugfixes
* Sometimes messages were sent multiple times
* Much better performance in the chat
* Change password fixed
* A lot of minor fixes

### 0.5.4:
* Rebase vivid and xenial to the same version again and some minor bugfixes
* FluffyChat now automatically opens the link to the matrix.org consens
* Updated translations

### 0.5.2 (only vivid):
There seems to be a critical bug, when updating on vivid. If you have a "critical error" message in the app, please uninstall the app, clean the cache with the UT tweak tool and reinstall the newest version from the OpenStore!

### 0.5.0:
##### New features
* Search chats
* Chat avatars
* Search users in chats
* Security & Privacy settings:
  * Disable typing notifications
  * Auto-accept invitations
* New message status:
  * Sending: Activity indicator
  * Sent: Little cloud
  * Received: Tick
  * Seen by someone: Usericon
* Display stickers
* Minor UI improvements


##### Bugfixes
* Autoreset pusher, when app has a new push token
* Show toast every time at start, if user has no Ubuntu One account
* Bug that displays a wrong name in app drawer
* Fixed a bug where a invite chat is displayed multiple times in chat list

### 0.4.2:
* FluffyChat now supports convergence
* Colors on avatar names
* Animation while uploading
* Minor bug fixes

### 0.4.1:
IMPORTANT: If you are using a matrixID with capital letters, then please logout and login again, to fix the problem with the error toasts in the chat!
More bug fixes:
* New contact button is working again
* Design issues in dark mode modals

### 0.4.0:
New Features:
* Send images and files (Pre-alpha, please report bugs! You can NOT send big images/files but at the moment you will not be notified, when your file is too big - Work in progress)
* New icon and splash image
* Device settings
* Push-target infos in the settings
* Endless scrolling in chat history

Also a lot of bug and typo fixes and better performance.
Have fun sending a lot of selfies with your Ubuntu Phone ;-)

### 0.3.0:
* A LOT of little bug fixes
* Push Notifications should now work more stable
* Added new options in settings: Change password, disable account
* Added new options in notification settings
* Added new theming options: Choose color and dark mode
* Design improvements
* Stability and performance improvements

### 0.2.3:
* A lot of little bug fixes
* Download files with correct filename
* Change the notification behaviour of each chat
* Little GUI improvements
* You can now scroll through ALL members of a chat and start directly a single chat

### 0.2.2:
* New background in chat
* Correct timestamp localizing
* User avatars
* Show thumbnails
* Download sent files
* Clear persistent notifications, when in chat
* Better performance, when receiving messages
* A lot of bug fixes

### 0.2.1:
* A lot of bug fixes
* Much better performance, when using very big rooms

### 0.2.0:
* Push Notifications are now in beta (Opt-in)
* A lot of bug fixes
* New features:
- Invite contact
- Start single chat
- Change user name
- Change chat name

### 0.1.2:
* Bug fixes
* Better performance and database management
* Improved stability

### 0.1.1:
* Lots of bug fixes
* Manage unread messages
* Better performance at scrolling in history
