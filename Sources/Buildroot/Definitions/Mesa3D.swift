//
//  Mesa3D.swift
//  
//
//  Created by Alsey Coleman Miller on 3/9/22.
//

// Mesa3D
public extension Configuration.ID {
        
    static var mesa3d: Configuration.ID             { "BR2_PACKAGE_MESA3D" }
    
    static var mesa3d_gbm: Configuration.ID         { "BR2_PACKAGE_MESA3D_GBM" }
    
    static var mesa3dOpenGLES: Configuration.ID     { "BR2_PACKAGE_MESA3D_OPENGL_ES" }
    
    static var mesa3dOpenGLEGL: Configuration.ID    { "BR2_PACKAGE_MESA3D_OPENGL_EGL" }
    
    static var mesa3dOpenGLGLX: Configuration.ID    { "BR2_PACKAGE_MESA3D_OPENGL_GLX" }
    
    static var mesa3dGalliumDriverVirgl: Configuration.ID { "BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_VIRGL" }
}
