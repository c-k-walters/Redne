//
//  RenderView.swift
//  Redne
//
//  Created by Charles Kelley on 3/31/25.
//

import MetalKit

// Vertex data for a full-screen quad (position and texture coordinates)
struct Vertex {
    var position: SIMD2<Float>
    var texCoord: SIMD2<Float>
}

// Simple Renderer
class RenderView: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    var texture: MTLTexture!
    
    var timebaseInfo = mach_timebase_info_data_t()
    var lastTime: UInt64!
    
    init(mtkView: MTKView) {
        guard let device = mtkView.device else {
            fatalError("Metal device not found")
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        mtkView.delegate = self
        loadAssets(mtkView: mtkView)
        
        mach_timebase_info(&timebaseInfo)
        lastTime = mach_absolute_time()
    }
    
    func loadAssets(mtkView: MTKView) {
        // 1. Set up the vertex data (two triangles forming a quad)
        let vertices = [
            Vertex(position: [-1, -1], texCoord: [0, 1]),
            Vertex(position: [ 1, -1], texCoord: [1, 1]),
            Vertex(position: [-1,  1], texCoord: [0, 0]),
            Vertex(position: [ 1, -1], texCoord: [1, 1]),
            Vertex(position: [ 1,  1], texCoord: [1, 0]),
            Vertex(position: [-1,  1], texCoord: [0, 0])
        ]
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: MemoryLayout<Vertex>.stride * vertices.count,
                                         options: [])
        
        // 2. Create the render pipeline
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Texture Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Failed to create pipeline state: \(error)")
        }
        
        // 3. Create a texture from raw 32-bit BGRA pixel data
        createTexture(width: Int(mtkView.frame.size.width), height: Int(mtkView.frame.size.height))
    }
    
    func createTexture(width: Int, height: Int){
        // Define texture properties
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false
        )
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Failed to create texture")
        }
        self.texture = texture
        
        // Upload pixel data to the texture
        let bytesPerRow = width * MemoryLayout<UInt32>.size
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: [UInt32](repeating: 0, count: width*height), bytesPerRow: bytesPerRow)
    }
    
    func updateTexture(bitMap: [UInt32], width: Int, height: Int) {
        let bytePerRow = width * MemoryLayout<UInt32>.size
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: bitMapMemory, bytesPerRow: bytePerRow)
    }
    
    // MARK: - MTKViewDelegate methods
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle window resizing if needed
    }
    
    // TODO: handle updating game logic here
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        // Create a command buffer and encoder
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set the vertex buffer and texture
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        updateTexture(bitMap: bitMapMemory, width: width, height: height)
        renderEncoder.setFragmentTexture(texture, index: 0)
        
        // Draw the textured quad (6 vertices)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        let endTime = mach_absolute_time()
        let difference = endTime - lastTime
        let elapsedNano = difference * (UInt64(timebaseInfo.numer) / UInt64(timebaseInfo.denom))
//        print("\(elapsedNano) ns")
        print("\(Float64(elapsedNano) / 1_000_000_000.0) s")
        lastTime = endTime
    }
}
