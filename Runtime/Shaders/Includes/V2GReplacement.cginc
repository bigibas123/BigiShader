#ifndef BIGI_V2G_REPLACEMENT_INCLUDED
#define BIGI_V2G_REPLACEMENT_INCLUDED

// No coversions in vertex func
#ifdef BIGI_VERT_ONLY_OBJECTSPACE
#ifndef BIGI_V2G_POSITION_FUNC
#define  BIGI_V2G_POSITION_FUNC
#else
#warning "BIGI_VERT_ONLY_OBJECTSPACE: BIGI_V2G_POSITION_FUNC Function macro already defined "
#endif

#ifndef BIGI_V2G_NORMAL_FUNC
#define  BIGI_V2G_NORMAL_FUNC
#else
#warning "BIGI_VERT_ONLY_OBJECTSPACE: BIGI_V2G_NORMAL_FUNC Function macro already defined"
#endif

#ifndef BIGI_V2G_TANGENT_FUNC
#define BIGI_V2G_TANGENT_FUNC
#else
#warning "BIGI_VERT_ONLY_OBJECTSPACE: BIGI_V2G_TANGENT_FUNC Function macro already defined"
#endif

#endif


// To world space conversion in vertex func
#ifdef BIGI_VERT_ONLY_TO_WORLDSPACE
float4 UnityObjectToWorldPos(const in float4 pos)
{
	return mul(unity_ObjectToWorld, pos);
}
#ifndef BIGI_V2G_POSITION_FUNC
#define  BIGI_V2G_POSITION_FUNC UnityObjectToWorldPos
#else
#warning "BIGI_VERT_ONLY_TO_WORLDSPACE: BIGI_V2G_POSITION_FUNC macro already declared "
#endif

#ifndef BIGI_V2G_TANGENT_FUNC
#define BIGI_V2G_TANGENT_FUNC UnityObjectToWorldDir
#else
#warning "BIGI_VERT_ONLY_TO_WORLDSPACE: BIGI_V2G_TANGENT_FUNC macro already declared "
#endif

#ifndef BIGI_V2G_NORMAL_FUNC
#define BIGI_V2G_NORMAL_FUNC UnityObjectToWorldNormal
#else
#warning "BIGI_VERT_ONLY_TO_WORLDSPACE: BIGI_V2G_NORMAL_FUNC macro already declared "
#endif

#endif


/// DEFAULTS:
#ifndef BIGI_V2G_POSITION_FUNC
#define BIGI_V2G_POSITION_FUNC UnityObjectToClipPos
#endif

#ifndef BIGI_V2G_TANGENT_FUNC
#define BIGI_V2G_TANGENT_FUNC UnityObjectToWorldDir
#endif

#ifndef BIGI_V2G_NORMAL_FUNC
#define BIGI_V2G_NORMAL_FUNC UnityObjectToWorldNormal
#endif


#else
#warning "BIGI_V2G_REPLACEMENT_INCLUDED has been included twice"
#endif