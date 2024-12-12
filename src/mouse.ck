// Adapted from Andrew Zhu Aday's flycam Mouse class
@import "constants.ck";

public class Mouse
{
    Constants c;
    c.MOUSE_DEVICE => int device;
    c.MOUSE_SENSITIVITY => float sensitivity;

    // state to track cumulative mouse motion
    // x: mouse delta x
    // y: mouse delta y
    // z: scrollwheel delta
    @(0.0, 0.0, 0.0) => vec3 motionDeltas;

    0 => static int LEFT_CLICK;
    1 => static int RIGHT_CLICK;
    2 => static int MIDDLE_CLICK;

    fun Mouse(int d)
    {
        d => device;
    }

    fun Mouse(int d, float s)
    {
        d => device;
        s * c.MOUSE_SENSITIVITY => sensitivity;
    }

    // returns motion delts since last time this function was called
    fun vec3 deltas()
    {
        motionDeltas => vec3 tmp;
        @(0.0, 0.0, tmp.z) => motionDeltas;  // rezero sum
        // hi :^)
        return tmp;
    }

    // return the last z
    fun float scrollDelta()
    {
        motionDeltas.z => float tmp;
        0 => motionDeltas.z;
        return tmp;
    }

    // start this device (should be sporked)
    fun void self_update()
    {
        // HID input and a HID message
        Hid hi;
        HidMsg msg;

        // open mouse, exit on fail
        if( !hi.openMouse( device ) )
        {
            cherr <= "failed to open device " + device <= IO.newline();
            me.exit();
        }
        <<< "mouse.ck: '" + hi.name() + "' ready", "" >>>;

        // infinite event loop
        while( true )
        {
            hi => now;
            while( hi.recv( msg ) )
            {
                // mouse motion
                if( msg.isMouseMotion() )
                {
                    if( msg.deltaX )
                        motionDeltas.x + msg.deltaX => motionDeltas.x;
                    if( msg.deltaY )
                        motionDeltas.y + msg.deltaY => motionDeltas.y;
                }
                
                // mouse wheel motion
                else if( msg.isWheelMotion() ) {
                    <<< "WHEEL MOTION" >>>;
                    if( msg.deltaY )
                        motionDeltas.z + msg.deltaY => motionDeltas.z;
                }
            }
        }
    }
}