﻿#ifndef BIGI_SOUND_UTILS_DEFINES
#define BIGI_SOUND_UTILS_DEFINES

#include "../Core/BigiShaderParams.cginc"
#include "./BigiSoundUtils.cginc"

#define GET_SOUND_SETTINGS(set) b_sound::ALSettings set; \
set.AL_Mode = clamp(_AL_Mode, 0, (b_sound::AudioLinkMode::ALM_WireFrame - _AL_BlockWireFrame)); \
set.AL_Distance = distance.w;\
set.AL_Theme_Weight = _AL_Theme_Weight; \
set.AL_TC_BassReactive = _AL_TC_BassReactive;

#define GET_SOUND_COLOR_CALL(setin,lout) const half4 lout = b_sound::GetDMXOrALColor(setin);

#define GET_SOUND_COLOR(outName) GET_SOUND_SETTINGS(bsoundSet); GET_SOUND_COLOR_CALL(bsoundSet,outName);

#endif