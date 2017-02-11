
import simd
import SceneKit
import GameController



extension GameViewController {

    // MARK: Controller orientation
    
    private static let controllerAcceleration = Float(1.0 / 10.0)
    private static let controllerDirectionLimit = float2(1.0)
    
    internal func controllerDirection() -> float2 {
        // Poll when using a game controller
        if let dpad = controllerDPad {
            if dpad.xAxis.value == 0.0 && dpad.yAxis.value == 0.0 {
                controllerStoredDirection = float2(0.0)
            } else {
                controllerStoredDirection = clamp(controllerStoredDirection + float2(dpad.xAxis.value, -dpad.yAxis.value) * GameViewController.controllerAcceleration, min: -GameViewController.controllerDirectionLimit, max: GameViewController.controllerDirectionLimit)
            }
        }
        
        return controllerStoredDirection
    }
    
    // MARK: Game Controller Events
    
    internal func setupGameControllers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.handleControllerDidConnectNotification(_:)), name: .GCControllerDidConnect, object: nil)
    }
    
    @objc func handleControllerDidConnectNotification(_ notification: NSNotification) {
        let gameController = notification.object as! GCController
        registerCharacterMovementEvents(gameController)
    }
    
    private func registerCharacterMovementEvents(_ gameController: GCController) {
        
        // An analog movement handler for D-pads and thumbsticks.
        let movementHandler: GCControllerDirectionPadValueChangedHandler = { [unowned self] dpad, _, _ in
            self.controllerDPad = dpad
        }
        
        #if os(tvOS)
            
        // Apple TV remote
        if let microGamepad = gameController.microGamepad {
            // Allow the gamepad to handle transposing D-pad values when rotating the controller.
            microGamepad.allowsRotation = true
            microGamepad.dpad.valueChangedHandler = movementHandler
        }
            
        #endif
        
        // Gamepad D-pad
        if let gamepad = gameController.gamepad {
            gamepad.dpad.valueChangedHandler = movementHandler
        }
        
        // Extended gamepad left thumbstick
        if let extendedGamepad = gameController.extendedGamepad {
            extendedGamepad.leftThumbstick.valueChangedHandler = movementHandler
        }
    }
    
    // MARK: Touch Events
    
    #if os(iOS)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if gameView.virtualDPadBounds().contains(touch.location(in: gameView)) {
                // We're in the dpad
                if padTouch == nil {
                    padTouch = touch
                    controllerStoredDirection = float2(0.0)
                }
            } else if panningTouch == nil {
                // Start panning
                panningTouch = touches.first
            }
            
            if padTouch != nil && panningTouch != nil {
                break // We already have what we need
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = panningTouch {
            let displacement = (float2(touch.location(in: view)) - float2(touch.previousLocation(in: view)))
            panCamera(displacement)
        }
        
        if let touch = padTouch {
            let displacement = (float2(touch.location(in: view)) - float2(touch.previousLocation(in: view)))
            controllerStoredDirection = clamp(mix(controllerStoredDirection, displacement, t: GameViewController.controllerAcceleration), min: -GameViewController.controllerDirectionLimit, max: GameViewController.controllerDirectionLimit)
        }
    }
    
    func commonTouchesEnded(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = panningTouch {
            if touches.contains(touch) {
                panningTouch = nil
            }
        }
        
        if let touch = padTouch {
            if touches.contains(touch) || event?.touches(for: view)?.contains(touch) == false {
                padTouch = nil
                controllerStoredDirection = float2(0.0)
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        commonTouchesEnded(touches, withEvent: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        commonTouchesEnded(touches, withEvent: event)
    }
    
    #endif
    
	
}
