@import {"doppler.ck", "mouse.ck", "instruments.ck", "constants.ck"}

Constants c;

Mouse m;
spork ~ m.self_update();

DopplerObserver observer(m) --> GG.scene();

GCube cube --> GG.scene();
cube.sca(4);
cube.scaY(0.1);
cube.pos(@(0, 0, 0.4));
cube.color(@(0.05, 0.05, 0.05));



0 => int LEFT_TO_RIGHT;
1 => int RIGHT_TO_LEFT;
2 => int BACK_TO_FRONT;
3 => int FRONT_TO_BACK;
4 => int UP_TO_DOWN;
5 => int DOWN_TO_UP;
6 => int ALL_DIRECTIONS;

45 => int NUM_SOURCES;
DopplerSource sources[NUM_SOURCES];


fun void clear_doppler_sources()
{
    for (int i; i < NUM_SOURCES; i++)
    {
        if (sources[i].instrument != null)
        {
            sources[i].instrument =< dac;
            sources[i].detach();
        }
    }
}

fun void freeze()
{
    for (int i; i < NUM_SOURCES; i++)
    {
        if (sources[i].observer != null)
        {
            sources[i].freeze_movement();
        }
    }
}

fun void unfreeze()
{
    for (int i; i < NUM_SOURCES; i++)
    {
        if (sources[i].observer != null)
        {
            sources[i].unfreeze_movement();
        }
    }
}

fun void randomize_gravities()
{
    for (int i; i < NUM_SOURCES; i++)
    {
        if (sources[i].observer != null)
        {
            10 => float g_range;
            5 => float start_speed;
            @(Math.random2f(-g_range, g_range), Math.random2f(-g_range, g_range), Math.random2f(-g_range, g_range)) => vec3 new_g;
            sources[i].set_gravity(new_g);
            new_g * start_speed => sources[i].velocity;
            true => sources[i].forces_enabled;
        }
    }
}

fun float get_closest_source_dist()
{
    int closest_source;
    999999 => float closest_source_dist;
    for (int i; i < NUM_SOURCES; i++)
    {
        if (sources[i].observer != null)        // if we have created the source
        {
            sources[i].get_distance_from_observer() => float i_dist;
            if (i_dist < closest_source_dist)
            {
                i_dist => closest_source_dist;
                i => closest_source;
            }
        }
    }
    return closest_source_dist;
}

fun void fly_across_direction(int direction, int num_sources, float g_min, float g_max)
{
    [0, 2, 4, 6, 7, 9, 11, 12, 14, -12, 16, 18, -24, 19, 21, -5, 19, 23, -36, 24, -36] @=> int LYDIAN[];
    67 => int start_note;

    Math.min(num_sources, NUM_SOURCES) => num_sources;

    for (int i; i < num_sources; i++)
    {
        // create instrument
        MonoflameInstrument mf => dac;
        Math.mtof(start_note + LYDIAN[i % LYDIAN.size()]) => mf.source_freq;
        1 => mf.source_gain;

        // create doppler source
        DopplerSource source(observer, mf) --> GG.scene();

        // setup doppler source
        100 => float start_dist;
        num_sources / 2 => float cloud_width;
        if (direction == LEFT_TO_RIGHT)
        {
            @(-start_dist, Math.random2f(0, cloud_width*2), Math.random2f(-cloud_width, cloud_width)) => source.pos;
            @(Math.random2f(g_min, g_max), 0, 0) => source.gravity;
        }
        if (direction == RIGHT_TO_LEFT)
        {
            @(start_dist, Math.random2f(-cloud_width, cloud_width), Math.random2f(-cloud_width, cloud_width)) => source.pos;
            @(-Math.random2f(g_min, g_max), 0, 0) => source.gravity;
        }
        if (direction == BACK_TO_FRONT)
        {
            @(Math.random2f(-cloud_width, cloud_width), Math.random2f(-cloud_width, cloud_width), start_dist) => source.pos;
            @(0, 0, -Math.random2f(g_min, g_max)) => source.gravity;
        }
        if (direction == FRONT_TO_BACK)
        {
            @(Math.random2f(-cloud_width, cloud_width), Math.random2f(-cloud_width, cloud_width), -start_dist) => source.pos;
            @(0, 0, Math.random2f(g_min, g_max)) => source.gravity;
        }
        if (direction == UP_TO_DOWN)
        {
            @(Math.random2f(-cloud_width, cloud_width), start_dist, Math.random2f(-cloud_width, cloud_width)) => source.pos;
            @(0, -Math.random2f(g_min, g_max), 0) => source.gravity;
        }
        if (direction == DOWN_TO_UP)
        {
            @(Math.random2f(-cloud_width, cloud_width), -start_dist, Math.random2f(-cloud_width, cloud_width)) => source.pos;
            @(0, Math.random2f(g_min, g_max), 0) => source.gravity;
        }

        if (direction == ALL_DIRECTIONS)
        {
            source.sca(2);
            @(Math.random2f(-start_dist, start_dist), Math.random2f(-start_dist, start_dist), Math.random2f(-start_dist, start_dist)) => source.pos;
            Math.random2f(g_min, g_max) * (source.get_unit_vector_to_observer()) => source.gravity;
        }
            

        source @=> sources[i];
    }

    int counter;
    while (true)
    {
        GG.nextFrame() => now;
        
        check_keyboard();

        // if the sources have finished moving to the other side, then clear them
        get_closest_source_dist() => float closest_source_dist;
        <<< "closest source dist:", closest_source_dist >>>;
        if (closest_source_dist > c.FIRST_PERSON_CLIP_FAR + 40)
        {
            clear_doppler_sources();
            break;
        }


    }
}

fun void check_keyboard()
{
    if (UI.isKeyPressed(UI_Key.F, false))
    {
        freeze();
    }

    if (UI.isKeyPressed(UI_Key.U, false))
    {
        unfreeze();
    }

    if (UI.isKeyPressed(UI_Key.R, false))
    {
        randomize_gravities();
    }
}

// Bloom
// GG.renderPass() --> BloomPass bloom_pass --> GG.outputPass();
// bloom_pass.input( GG.renderPass().colorOutput() );
// GG.outputPass().input( bloom_pass.colorOutput() );
// bloom_pass.intensity(0.95);
// bloom_pass.radius(.85);
// bloom_pass.levels(9);


fly_across_direction(LEFT_TO_RIGHT, 5, 3, 5);
fly_across_direction(RIGHT_TO_LEFT, 10, 4, 7);
fly_across_direction(UP_TO_DOWN, 40, 6, 8);
fly_across_direction(DOWN_TO_UP, 30, 5, 8);
fly_across_direction(BACK_TO_FRONT, 10, 2, 3);
fly_across_direction(ALL_DIRECTIONS, 40, 3, 3);
fly_across_direction(FRONT_TO_BACK, 40, 2.9, 3.1);


while(true)
{
    // Math.random2(0, DOWN_TO_UP) => int direction;
    // fly_across_direction(direction, )
    GG.nextFrame() => now;
}
