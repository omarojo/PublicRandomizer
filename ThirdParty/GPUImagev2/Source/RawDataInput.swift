#if os(Linux)
#if GLES
    import COpenGLES.gles2
    #else
    import COpenGL
#endif
#else
#if GLES
    import OpenGLES
    #else
    import OpenGL.GL3
#endif
#endif

import AVFoundation

public enum PixelFormat {
    case bgra
    case rgba
    case rgb
    case luminance
    
    func toGL() -> Int32 {
        switch self {
            case .bgra: return GL_BGRA
            case .rgba: return GL_RGBA
            case .rgb: return GL_RGB
            case .luminance: return GL_LUMINANCE
        }
    }
}

// TODO: Replace with texture caches where appropriate
public class RawDataInput: ImageSource {
    public let targets = TargetContainer()
    
    let frameRenderingSemaphore = DispatchSemaphore(value:1)
    let cameraProcessingQueue = DispatchQueue.global(priority:DispatchQueue.GlobalQueuePriority.default)
    let captureAsYUV:Bool = true
    let yuvConversionShader:ShaderProgram?
    var supportsFullYUVRange:Bool = false
    
    public init() {
        if captureAsYUV {
            supportsFullYUVRange = false
            let videoOutput = AVCaptureVideoDataOutput()
            let supportedPixelFormats = videoOutput.availableVideoCVPixelFormatTypes
            for currentPixelFormat in supportedPixelFormats! {
                if ((currentPixelFormat as! NSNumber).int32Value == Int32(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)) {
                    supportsFullYUVRange = true
                }
            }
            
            if (supportsFullYUVRange) {
                yuvConversionShader = crashOnShaderCompileFailure("Camera"){try sharedImageProcessingContext.programForVertexShader(defaultVertexShaderForInputs(2), fragmentShader:YUVConversionFullRangeFragmentShader)}
            } else {
                yuvConversionShader = crashOnShaderCompileFailure("Camera"){try sharedImageProcessingContext.programForVertexShader(defaultVertexShaderForInputs(2), fragmentShader:YUVConversionVideoRangeFragmentShader)}
            }
        } else {
            yuvConversionShader = nil
        }

    }
    
    public func uploadPixelBuffer(_ cameraFrame: CVPixelBuffer ) {
        guard (frameRenderingSemaphore.wait(timeout:DispatchTime.now()) == DispatchTimeoutResult.success) else { return }
        
        let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
        let bufferHeight = CVPixelBufferGetHeight(cameraFrame)
        
        CVPixelBufferLockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))

        sharedImageProcessingContext.runOperationAsynchronously{
            let cameraFramebuffer:Framebuffer
            let luminanceFramebuffer:Framebuffer
            let chrominanceFramebuffer:Framebuffer
            if sharedImageProcessingContext.supportsTextureCaches() {
                var luminanceTextureRef:CVOpenGLESTexture? = nil
                let _ = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, sharedImageProcessingContext.coreVideoTextureCache, cameraFrame, nil, GLenum(GL_TEXTURE_2D), GL_LUMINANCE, GLsizei(bufferWidth), GLsizei(bufferHeight), GLenum(GL_LUMINANCE), GLenum(GL_UNSIGNED_BYTE), 0, &luminanceTextureRef)
                let luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef!)
                glActiveTexture(GLenum(GL_TEXTURE4))
                glBindTexture(GLenum(GL_TEXTURE_2D), luminanceTexture)
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
                luminanceFramebuffer = try! Framebuffer(context:sharedImageProcessingContext, orientation:.portrait, size:GLSize(width:GLint(bufferWidth), height:GLint(bufferHeight)), textureOnly:true, overriddenTexture:luminanceTexture)
                
                var chrominanceTextureRef:CVOpenGLESTexture? = nil
                let _ = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, sharedImageProcessingContext.coreVideoTextureCache, cameraFrame, nil, GLenum(GL_TEXTURE_2D), GL_LUMINANCE_ALPHA, GLsizei(bufferWidth / 2), GLsizei(bufferHeight / 2), GLenum(GL_LUMINANCE_ALPHA), GLenum(GL_UNSIGNED_BYTE), 1, &chrominanceTextureRef)
                let chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef!)
                glActiveTexture(GLenum(GL_TEXTURE5))
                glBindTexture(GLenum(GL_TEXTURE_2D), chrominanceTexture)
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
                chrominanceFramebuffer = try! Framebuffer(context:sharedImageProcessingContext, orientation:.portrait, size:GLSize(width:GLint(bufferWidth / 2), height:GLint(bufferHeight / 2)), textureOnly:true, overriddenTexture:chrominanceTexture)
            } else {
                glActiveTexture(GLenum(GL_TEXTURE4))
                luminanceFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:GLSize(width:GLint(bufferWidth), height:GLint(bufferHeight)), textureOnly:true)
                luminanceFramebuffer.lock()
                
                glBindTexture(GLenum(GL_TEXTURE_2D), luminanceFramebuffer.texture)
                glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE, GLsizei(bufferWidth), GLsizei(bufferHeight), 0, GLenum(GL_LUMINANCE), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0))
                
                glActiveTexture(GLenum(GL_TEXTURE5))
                chrominanceFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:GLSize(width:GLint(bufferWidth / 2), height:GLint(bufferHeight / 2)), textureOnly:true)
                chrominanceFramebuffer.lock()
                glBindTexture(GLenum(GL_TEXTURE_2D), chrominanceFramebuffer.texture)
                glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE_ALPHA, GLsizei(bufferWidth / 2), GLsizei(bufferHeight / 2), 0, GLenum(GL_LUMINANCE_ALPHA), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1))
            }
            
            cameraFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:luminanceFramebuffer.sizeForTargetOrientation(.portrait), textureOnly:false)
            
            let conversionMatrix:Matrix3x3
            if (self.supportsFullYUVRange) {
                conversionMatrix = colorConversionMatrix601FullRangeDefault
            } else {
                conversionMatrix = colorConversionMatrix601Default
            }
            convertYUVToRGB(shader:self.yuvConversionShader!, luminanceFramebuffer:luminanceFramebuffer, chrominanceFramebuffer:chrominanceFramebuffer, resultFramebuffer:cameraFramebuffer, colorConversionMatrix:conversionMatrix)
            
            
            //ONLY RGBA
            //let cameraFramebuffer:Framebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:GLSize(width:GLint(bufferWidth), height:GLint(bufferHeight)), textureOnly:true)
            //glBindTexture(GLenum(GL_TEXTURE_2D), cameraFramebuffer.texture)
            //glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(bufferWidth), GLsizei(bufferHeight), 0, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddress(cameraFrame))
            
            CVPixelBufferUnlockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
            
            
            self.updateTargetsWithFramebuffer(cameraFramebuffer)
            self.frameRenderingSemaphore.signal()
                
        }
    }
    
    public func uploadBytes(_ bytes:[UInt8], size:Size, pixelFormat:PixelFormat, orientation:ImageOrientation = .portrait) {
        let dataFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:orientation, size:GLSize(size), textureOnly:true, internalFormat:pixelFormat.toGL(), format:pixelFormat.toGL())

        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), dataFramebuffer.texture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, size.glWidth(), size.glHeight(), 0, GLenum(pixelFormat.toGL()), GLenum(GL_UNSIGNED_BYTE), bytes)

        updateTargetsWithFramebuffer(dataFramebuffer)
    }
    
    public func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        // TODO: Determine if this is necessary for the raw data uploads
//        if let buff = self.dataFramebuffer {
//            buff.lock()
//            target.newFramebufferAvailable(buff, fromSourceIndex:atIndex)
//        }
    }
}
