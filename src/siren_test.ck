@import {"doppler.ck", "mouse.ck", "instruments.ck", "constants.ck"}

Mouse m;
spork ~ m.self_update();

DopplerObserver observer(m) --> GG.scene();

GCube cube --> GG.scene();
cube.sca(10);
cube.scaY(0.1);
cube.pos(@(0, 0, 0.4));
cube.color(@(0.3, 0.3, 0.3));

SirenInstrument siren => dac;
spork ~ siren.play();

DopplerSource source(observer, siren) --> GG.scene();
source.pos(@(-100, 2, -3));
source.sca(4);

// false => source.forces_enabled;
// @(60, 0, 0) => source.velocity;

// GG.renderPass() --> BloomPass bloom_pass --> GG.outputPass();
// bloom_pass.input( GG.renderPass().colorOutput() );
// GG.outputPass().input( bloom_pass.colorOutput() );
// bloom_pass.intensity(0.95);
// bloom_pass.radius(.85);
// bloom_pass.levels(9);

while (true)
{
    GG.nextFrame() => now;

    if (source.posX() > 150) -100 => source.posX;
}