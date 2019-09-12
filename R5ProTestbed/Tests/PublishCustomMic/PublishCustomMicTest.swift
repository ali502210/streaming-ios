//
//  File.swift
//  R5ProTestbed
//
//  Created by David Heimann on 9/21/18.
//  Copyright © 2015 Infrared5, Inc. All rights reserved.
// 
//  The accompanying code comprising examples for use solely in conjunction with Red5 Pro (the "Example Code") 
//  is  licensed  to  you  by  Infrared5  Inc.  in  consideration  of  your  agreement  to  the  following  
//  license terms  and  conditions.  Access,  use,  modification,  or  redistribution  of  the  accompanying  
//  code  constitutes your acceptance of the following license terms and conditions.
//  
//  Permission is hereby granted, free of charge, to you to use the Example Code and associated documentation 
//  files (collectively, the "Software") without restriction, including without limitation the rights to use, 
//  copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
//  persons to whom the Software is furnished to do so, subject to the following conditions:
//  
//  The Software shall be used solely in conjunction with Red5 Pro. Red5 Pro is licensed under a separate end 
//  user  license  agreement  (the  "EULA"),  which  must  be  executed  with  Infrared5,  Inc.   
//  An  example  of  the EULA can be found on our website at: https://account.red5pro.com/assets/LICENSE.txt.
// 
//  The above copyright notice and this license shall be included in all copies or portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,  INCLUDING  BUT  
//  NOT  LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY, FITNESS  FOR  A  PARTICULAR  PURPOSE  AND  
//  NONINFRINGEMENT.   IN  NO  EVENT  SHALL INFRARED5, INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//  WHETHER IN  AN  ACTION  OF  CONTRACT,  TORT  OR  OTHERWISE,  ARISING  FROM,  OUT  OF  OR  IN CONNECTION 
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//

import UIKit
import R5Streaming

@objc(PublishCustomMicTest)
class PublishCustomMicTest : BaseTest {
    var mic: GainWobbleMic? = nil
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated);
        
        setupDefaultR5VideoViewController()
        
        // Set up the configuration
        let config = getConfig()
        // Set up the connection and stream
        let connection = R5Connection(config: config)
        
        
        self.publishStream = R5Stream(connection: connection)
        self.publishStream!.delegate = self
        
        
        // Attach the custom source to the stream
        if(Testbed.getParameter(param: "video_on") as! Bool){
            // Attach the video from camera to stream
            let videoDevice = AVCaptureDevice.devices(for: AVMediaType.video).last as? AVCaptureDevice
            
            let camera = R5Camera(device: videoDevice, andBitRate: Int32(Testbed.getParameter(param: "bitrate") as! Int))
            
            camera?.width = Int32(Testbed.getParameter(param: "camera_width") as! Int)
            camera?.height = Int32(Testbed.getParameter(param: "camera_height") as! Int)
            camera?.fps = Int32(Testbed.getParameter(param: "fps") as! Int)
            camera?.orientation = 90
            self.publishStream!.attachVideo(camera)
        }
        
        mic = GainWobbleMic()
        self.publishStream!.attachAudio(mic);
        
        // show preview and debug info
        // self.publishStream?.getVideoSource().fps = 2;
        self.currentView!.attach(publishStream!)
        
        
        self.publishStream!.publish(Testbed.getParameter(param: "stream1") as! String, type: getPublishRecordType ())
    }
}

@objc(GainWobbleMic)
class GainWobbleMic : R5Microphone {
    var gain : Float = 1.0
    var mod : Int = 1
    var lastTime : Double = 0.0
    
    override init() {
        let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        super.init(device: audioDevice)
        bitrate = 32
        
        processData = { samples, streamTimeMill in
            
            self.modifyGain(time: streamTimeMill - self.lastTime)
            self.lastTime = streamTimeMill
            
            var s: Int
            var val: UInt8
            let data = samples?.mutableBytes
            let length: Int = (samples?.length)!
            for i in 0...length {
                val = (data?.advanced(by: i).load(as: UInt8.self))!
                s = Int(Float(val) * self.gain)
                val = UInt8(min(s, Int(UInt8.max)))
                data?.advanced(by: i).storeBytes(of: val, as: UInt8.self)
            }
        }
    }
    
    func modifyGain(time: Double) {
        gain += Float(mod) * Float(time/2000)
        if( gain >= 2 || gain <= 0 ){
            NSLog("gain at: %f", gain)
            gain = max(2.0 * Float(mod), 0.0)
            mod *= -1
        }
    }
}
