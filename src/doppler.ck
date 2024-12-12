@import {"mouse.ck", "constants.ck"}

public class DopplerInstrument extends Chugraph
{
    float source_freq;
    float source_gain;
    float observer_freq;
    float observer_gain;
    float observer_pan;

    fun void play() {};

    // This function should set the freq, gain, and pan of the sound. Will be called every frame 
    // by a DopplerSource, after the observer freq/gain/pan are updated
    fun void update() {};

    fun void stop() {};
}

public class DopplerObserver extends GGen
{
    Constants c;

    // ----- initialize mesh -----
    0.4 => float foot_separation;
    @(0.2, 0.4, 0.5) => vec3 foot_scale;

    GSphere left_foot --> this;
    left_foot.sca(foot_scale);
    left_foot.color(Color.BLACK);
    left_foot.pos(@(-foot_separation, 0.2, 0.5));

    GSphere right_foot --> this;
    right_foot.sca(foot_scale);
    right_foot.color(Color.BLACK);
    right_foot.pos(@(foot_separation, 0.2, 0.5));

    // camera initial settings
    GG.scene().camera() @=> GCamera @ eye;
    eye.pos(c.STARTING_EYES_POS);   // relative position to overall GPlayer
    eye.clip(eye.clipNear(), c.FIRST_PERSON_CLIP_FAR);
    eye.fov(c.FIRST_PERSON_FOV);
    eye --> this;

    // crosshair settings
    // GCircle crosshair;
    // c.STARTING_CROSSHAIR_POS => crosshair.pos;   // relative position to eye
    // c.CROSSHAIR_SCA => crosshair.sca;
    // Color.WHITE => crosshair.color;
    // crosshair --> eye;
    GWindow.mouseMode(GWindow.MouseMode_Disabled);        // hide the mouse, since we have a crosshair

    
    Mouse @ mouse;

    // ----- current state of observer -----
    float rot_y;
    vec3 velocity;
    

    fun DopplerObserver(Mouse @ m)
    {
        m @=> mouse;
    }

    fun void handle_mouse()
    {
        mouse.deltas() => vec3 mouse_deltas;

        -(mouse_deltas.x * mouse.sensitivity) => float rotate_horizontal;        // delta angle to look left/right
        -(mouse_deltas.y * mouse.sensitivity) => float rotate_vertical;          // delta angle to look up/down

        // look left/right
        this.rotateY(rotate_horizontal);
        rot_y + rotate_horizontal => rot_y;     // update the player's roty (since we are manually tracking this)

        // look up/down
        this.eye.rotX() + rotate_vertical => float new_rotX;
        if (new_rotX < Math.PI/2 && new_rotX > -Math.PI/2)     // limit how far we can look up/down
        {
            this.eye.rotateX(rotate_vertical);
        }
    }

    fun update(float dt)
    {
        handle_mouse();
    }


}



public class DopplerSource extends GGen
{
    Constants c;
    DopplerInstrument @ instrument;

    GSphere sphere --> this;
    sphere.color(c.DOPPLER_SOURCE_COLOR);
    sphere.sca(c.DOPPLER_SOURCE_SCA);

    vec3 gravity;
    float mass;
    float speed_of_sound;  // speed of sound (m/s). For example, it would be 343 m/s in 20°C air

    vec3 velocity;
    vec3 acceleration;

    DopplerObserver @ observer;

    true => int forces_enabled;
    vec3 unfreeze_velocity;

    fun DopplerSource(DopplerObserver o, DopplerInstrument i)
    {
        DopplerSource(c.MASS, c.GRAVITY, c.SPEED_OF_SOUND, o, i);
    }
    
    fun DopplerSource(float m, float g, float c, DopplerObserver o, DopplerInstrument i)
    {
        m => mass;
        @(g, 0, 0) => gravity;
        c => speed_of_sound;
        o @=> observer;
        i @=> instrument;
    }

    fun update(float dt)
    {
        update_position(dt);
        update_frequency();
        update_gain();
        update_panning();
        instrument.update();        // applies the observed frequency, gain, and panning changes
    }

    // =========================== doppler effect ===========================

    fun void update_frequency()
    {
        get_frequency_shift_factor() => float shift_factor;
        instrument.source_freq * shift_factor => float observer_freq;
        Math.max(0, observer_freq) => instrument.observer_freq;
    }

    // computes the frequency shift factor based on the current source's, and the provided observer's, velocity and position.
    fun float get_frequency_shift_factor()
    {
        343 => float c;

        -1 * get_unit_vector_to_observer() => vec3 r;

        (speed_of_sound + r.dot(observer.velocity)) / (speed_of_sound + r.dot(this.velocity)) => float shift_factor;

        return shift_factor;
    }

    // =========================== spatial audio ===========================

    // update gain based on distance between observer and source
    fun void update_gain()
    {
        // initial intensity of sound at source (W/m^2)
        instrument.source_gain => float I_s;

        // exponential decay due to absorption
        get_distance_from_observer() => float d;
        Math.pow(Math.e, (-c.ABSORPTION_COEFF * d)) => float decay;

        // geometric spreading factor
        // 1 / Math.pow(d, 2) => float spread_factor;
        1 / (1 + Math.pow(d, c.SPREAD_N)) => float spread_factor;

        // compute final sound intensity at observers position
        I_s * decay * spread_factor => float I_o;

        I_o => instrument.observer_gain;
    }

    fun void update_panning()
    {
        // absolute angle in radians between observer and source
        Math.atan((observer.posWorld().x - this.posWorld().x) / (observer.posWorld().z - this.posWorld().z)) => float absolute_angle;

        // angle in radians of the observer's head
        observer.rot_y => float head_angle;

        // relative angle between observer and source, accounting for head rotation
        head_angle - absolute_angle => float relative_angle;

        // convert relative_angle to a pan value
        relative_angle % (2*Math.PI) => relative_angle;
        if (relative_angle < 0) (2*Math.PI) +=> relative_angle;

        float pan_val;

        if (relative_angle < 2*Math.PI)
        {
            1 -((relative_angle - 1.5*Math.PI) / (0.5*Math.PI)) => pan_val;
        }
        if (relative_angle < 1.5*Math.PI)
        {
            ((relative_angle - (Math.PI)) / (0.5*Math.PI)) => pan_val;
        }
        if (relative_angle < Math.PI)
        {
            -(1 - (relative_angle - (0.5*Math.PI)) / (0.5*Math.PI)) => pan_val;
        }
        if (relative_angle < 0.5*Math.PI)
        {
            -(relative_angle / (0.5*Math.PI)) => pan_val;
        }

        -pan_val => instrument.observer_pan;
    }

    // =========================== kinematics ===========================

    fun update_position(float dt)
    {
        // 1. update the current acceleration of object, based on active forces
        if (forces_enabled) update_acceleration();

        // 2. compute the velocity with the current acceleration
        update_velocity(dt);

        // 3. compute the new position with the updated velocity
        this.pos() + (velocity * dt) => this.pos;
    }

    fun update_velocity(float dt)
    {
        velocity + (acceleration * dt) => velocity;
    }

    fun update_acceleration()
    {
        vec3 total_force;
        total_force + get_gravity_force() => total_force;
        total_force / mass => acceleration;
    }

    fun vec3 get_gravity_force()
    {
        return gravity * mass;
    }

    fun void set_gravity(vec3 new_gravity)
    {
        new_gravity => gravity;
    }

    fun void freeze_movement()
    {
        false => forces_enabled;
        velocity => unfreeze_velocity;
        @(0, 0, 0) => acceleration;
        @(0, 0, 0) => velocity;
    }

    fun void unfreeze_movement()
    {
        unfreeze_velocity => velocity;
        true => forces_enabled;
    }

    // =========================== other useful function ===========================
    fun float get_distance_from_observer()
    {
        (this.posWorld() - observer.posWorld()) => vec3 displacement;
        return displacement.magnitude();                             // distance between observer and this source
    }

    fun vec3 get_unit_vector_to_observer()
    {
        observer.posWorld() - this.posWorld() => vec3 r;
        r.normalize();      // unit vector pointing from source to observer
        return r;
    }
}




