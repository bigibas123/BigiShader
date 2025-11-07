#ifndef SCRUFFYRUFFLESS_AND_MERLINDERIVATIVES
#define SCRUFFYRUFFLESS_AND_MERLINDERIVATIVES
// https://github.com/pema99/shader-knowledge/blob/main/tips-and-tricks.md#functions-for-detecting-vrchat-specific-scenarios

uniform float _VRChatCameraMode;
uniform uint _VRChatCameraMask;
uniform float _VRChatMirrorMode;
uniform float3 _VRChatMirrorCameraPos;
uniform float _VRChatFaceMirrorMode;

bool IsVR()
{
	#ifdef UNITY_SINGLE_PASS_STEREO
	return true;
	#else
	return (_VRChatMirrorMode == 1) || (_VRChatFaceMirrorMode == 1);
	#endif
}

bool IsVRHandCamera()
{
	return (IsVR() && _VRChatCameraMode == 1) || (!IsVR() && _VRChatCameraMode == 2);
}

bool IsDesktop()
{
	return !IsVR();
}

bool IsVRHandCameraPreview()
{
	return IsVRHandCamera() && _ScreenParams.y == 720;
}

bool IsVRHandCameraPicture()
{
	return IsVRHandCamera() && _ScreenParams.y == 1080;
}

bool IsPanorama()
{
	return unity_CameraProjection[1][1] == 1 && _ScreenParams.x == 1075 && _ScreenParams.y == 1025;
}

bool IsInMirror()
{
	return (_VRChatMirrorMode != 0) || (_VRChatFaceMirrorMode != 0);
}

bool IsInVRMirror()
{
	return (_VRChatMirrorMode == 1);
}

bool IsInDesktopMirror()
{
	return (_VRChatMirrorMode == 2);
}

bool IsInFaceMirror()
{
	return (_VRChatFaceMirrorMode == 1);
}

bool IsRightEye()
{
	#if defined(USING_STEREO_MATRICES)
	return unity_StereoEyeIndex == 1;
	#else
	return _VRChatMirrorMode == 1 && mul(unity_WorldToCamera, float4(_VRChatMirrorCameraPos, 1)).x < 0;
	#endif
}

bool IsLeftEye() { return !IsRightEye(); }

#endif
