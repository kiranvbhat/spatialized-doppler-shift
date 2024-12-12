@import {"doppler.ck"};

public class SirenInstrument extends DopplerInstrument
{
    true => int running;

    1 => source_gain;

    SqrOsc siren => 
    // Bitcrusher bc => 
    LPF lpf => 
    GVerb rev =>
    Pan2 pan =>
    outlet;

    // set parameter values
    // bc.downsample(2);
    4000 => lpf.freq;
    5 => rev.roomsize;

    fun void play()
    {
        // start a little lower (520hz)
        for (520 => int i; i < 620; i + 5 => i) {
            i => source_freq;
            10::ms => now;
        }

        // oscillate between 620hz and 1200hz
        while (running) {
            for (620 => int i; i < 1200; i + 5 => i) {
                i => source_freq;
                10::ms => now;
            }
            for (1200 => int i; i > 620; i - 5 => i) {
                i => source_freq;
                25::ms => now;
            }
        }
    }

    fun update()
    {
        if (running)
        {
            observer_freq => siren.freq;
            observer_gain => siren.gain;
            observer_pan => pan.pan;
        }
    }

    fun stop()
    {
        false => running;
    }
}


public class FlareInstrument extends DopplerInstrument
{
   

}

public class MonoflameInstrument extends DopplerInstrument
{
    true => int running;
    1 => source_gain;

    SinOsc osc => Pan2 pan => NRev rev => Gain g => outlet;
    rev.mix(0.4);
    g.gain(0.5);


    fun void play()
    {
        while (running)
        {
            // initially on
            1000::ms * Math.random2f(0, 1) => now;        // on time

            // transition to off
            Envelope gain_env => blackhole;
            1 => gain_env.value;
            0 => gain_env.target;
            200::ms => gain_env.duration;                 // transition time
            40 => int num_steps;
            repeat (num_steps)
            {
                gain_env.value() => source_gain;
                gain_env.duration() / num_steps => now;
            }
            0 => source_gain;

            // stay off
            1000::ms * Math.random2f(0, 1) => now;        // off time

            // transition to on
            1 => gain_env.target;
            200::ms => gain_env.duration;                 // transition time
            repeat (num_steps)
            {
                gain_env.value() => source_gain;
                gain_env.duration() / num_steps => now;
            }
            1 => source_gain;
        }
    }

    fun void update()
    {
        if (running)
        {
            observer_freq => osc.freq;
            observer_gain => osc.gain;
            observer_pan => pan.pan;
        }
    }

    fun stop()
    {
        false => running;
    }
}