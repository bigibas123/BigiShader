#ifndef BIGI_TILE_DISCARD_STUFF
#define BIGI_TILE_DISCARD_STUFF

#ifndef BIGI_UDIM_DISCARD_DECLARED
#define BIGI_UDIM_DISCARD_DECLARED
uniform float _UDIMDiscardRow3_3;
uniform float _UDIMDiscardRow3_2;
uniform float _UDIMDiscardRow3_1;
uniform float _UDIMDiscardRow3_0;
uniform float _UDIMDiscardRow2_3;
uniform float _UDIMDiscardRow2_2;
uniform float _UDIMDiscardRow2_1;
uniform float _UDIMDiscardRow2_0;
uniform float _UDIMDiscardRow1_3;
uniform float _UDIMDiscardRow1_2;
uniform float _UDIMDiscardRow1_1;
uniform float _UDIMDiscardRow1_0;
uniform float _UDIMDiscardRow0_3;
uniform float _UDIMDiscardRow0_2;
uniform float _UDIMDiscardRow0_1;
uniform float _UDIMDiscardRow0_0;
#endif

namespace b_tile_discard
{
	bool ShouldDiscard(const in float2 uv)
	{
		// Branchless (stolen from liltoon, inspired by s-ilent)
		float isDiscarded = 0;
		float4 xMask = float4((uv.x >= 0 && uv.x < 1),
							  (uv.x >= 1 && uv.x < 2),
							  (uv.x >= 2 && uv.x < 3),
							  (uv.x >= 3 && uv.x < 4));

		isDiscarded += (uv.y >= 0 && uv.y < 1) * dot(
			float4(_UDIMDiscardRow0_0, _UDIMDiscardRow0_1, _UDIMDiscardRow0_2, _UDIMDiscardRow0_3), xMask);
		isDiscarded += (uv.y >= 1 && uv.y < 2) * dot(
			float4(_UDIMDiscardRow1_0, _UDIMDiscardRow1_1, _UDIMDiscardRow1_2, _UDIMDiscardRow1_3), xMask);
		isDiscarded += (uv.y >= 2 && uv.y < 3) * dot(
			float4(_UDIMDiscardRow2_0, _UDIMDiscardRow2_1, _UDIMDiscardRow2_2, _UDIMDiscardRow2_3), xMask);
		isDiscarded += (uv.y >= 3 && uv.y < 4) * dot(
			float4(_UDIMDiscardRow3_0, _UDIMDiscardRow3_1, _UDIMDiscardRow3_2, _UDIMDiscardRow3_3), xMask);

		isDiscarded *= any(float4(uv.y >= 0, uv.y < 4, uv.x >= 0, uv.x < 4));
		// never discard outside 4x4 grid in pos coords 

		// Use a threshold so that there's some room for animations to be close to 0, but not exactly 0
		const float threshold = 0.001;
		return isDiscarded > threshold;
	}
	
}

#endif