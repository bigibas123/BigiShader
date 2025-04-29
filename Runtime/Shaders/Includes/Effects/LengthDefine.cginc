#ifndef BIGI_LENGTH_DEFINE_H
#define BIGI_LENGTH_DEFINE_H
#ifndef GET_DISTANCE
// length(pos - startingpoint) * scaling
#define GET_DISTANCE(pos) (length((pos - float4(0.0, 0.4, 0.0, 0.0)) * 5.0))
#endif
#endif
