public class Constants
{
    // --------------------- mouse.ck ---------------------
    0 => int MOUSE_DEVICE;
    0.002 => float MOUSE_SENSITIVITY;

    // --------------------- doppler.ck ---------------------

    // DopplerObserver eyes
    @(0.0, 1.8, 0.0) => vec3 STARTING_EYES_POS;     // where the player's eyes are (relative to the player's position)
    100 => float FIRST_PERSON_CLIP_FAR;
    0.785398 + 0.6 => float FIRST_PERSON_FOV;

    // crosshair
    @(0, 0, -0.4) => vec3 STARTING_CROSSHAIR_POS;
    0.005 => float CROSSHAIR_SCA;


    // physics constants
    9.81 => float EARTH_G;

    // DopplerSource physics
    1 => float MASS;
    EARTH_G => float GRAVITY;
    0.4 => float MU_K;
    343 => float SPEED_OF_SOUND;

    // DopplerSource spatial audio
    0.003 => float ABSORPTION_COEFF;
    1.1 => float SPREAD_N;

    // DopplerSource mesh
    0.3 => float DOPPLER_SOURCE_SCA;
    Color.WHITE => vec3 DOPPLER_SOURCE_COLOR;
}