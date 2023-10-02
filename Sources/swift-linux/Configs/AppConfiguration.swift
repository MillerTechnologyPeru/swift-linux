//
//  AppConfiguration.swift
//
//
//  Created by Alsey Coleman Miller on 10/1/23.
//

import Foundation
import Buildroot
import AppRuntime

public extension Configuration {
    
    static var appLibraries: Configuration {
        [
            .wayland: true,
            .waylandProtocols: true,
            .wlroots: true,
            .libinput: true,
            .xorg7: true,
            .libxcb: true,
            .libx11: true,
            .libxcursor: true,
            .libdrm: true,
            .mesa3d: true, 
            .mesa3d_gbm: true, 
            .mesa3dOpenGLES: true, 
            .mesa3dOpenGLEGL: true, 
            .mesa3dOpenGLGLX: true, 
            .mesa3dGalliumDriverVirgl: true,
            .sdl2: true,
            .sdl2KmsDrm: true, 
            .sdl2OpenGL: true, 
            .sdl2OpenGLES: true, 
            .sdl2Gfx: true, 
            .sdl2Image: true, 
            .sdl2Mixer: true, 
            .sdl2Net: true, 
            .sdl2Ttf: true,
            .cairo: true,
            .cairoPS: true, 
            .cairoScript: true, 
            .cairoSvg: true, 
            .cairoPng: true, 
            .pixman: true, 
            .fontConfig: true, 
            .harfBuzz: true, 
            .lcms2: true,
            .libpng: true,
            .jpeg: true,
            .alsaLib: true,
            .openAL: true, 
            .libvorbis: true, 
            .libogg: true,
            .libepoxy: true,
            .libfribidi: true, 
            .pcre: true, 
            .pcreUcp: true,
        ]
    }
}

