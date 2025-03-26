#ifndef BIGI_LENGTH_DEFINE_H
#define BIGI_LENGTH_DEFINE_H
#ifndef GET_DISTANCE

namespace b_effects
{
	namespace constants
	{
		const static float4 startingPoint = float4(0.0, 0.1, 0.0, 0.0);
		const static float scaling = 4.0;
	}
}

#define GET_DISTANCE(pos) (length((pos + b_effects::constants::startingPoint) * b_effects::constants::scaling) % 1.0)
#endif
#endif
