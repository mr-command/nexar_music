package com.example.nexar_app

import com.ryanheise.audioservice.AudioServiceActivity

// Extending AudioServiceActivity routes lifecycle through the media playback
// foreground service, so audio keeps running undistorted with the screen
// locked / app in background.
class MainActivity : AudioServiceActivity()
