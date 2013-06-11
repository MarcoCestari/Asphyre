unit Asphyre.OpenAL;
//---------------------------------------------------------------------------
// OpenAL header translation for Delphi and FreePascal.
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//---------------------------------------------------------------------------
// Discussion:
//
// This file includes the translation of "al.h" and "alc.h" files supplied
// in OpenAL SDK (2006) by Creative Labs.
//
// The extensions from "efx.h" and "xram.h" are not translated yet.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
type
 // 8-bit boolean.
 ALboolean  = ByteBool;
 PALboolean = ^ALboolean;

 // Character.
 ALchar = {$ifdef DelphiNextGen}Byte{$else}AnsiChar{$endif};
 PALchar = ^ALchar;

 // Signed 8-bit 2's complement integer.
 ALbyte  = ShortInt;
 PALbyte = ^ALbyte;

 // Unsigned 8-bit integer.
 ALubyte  = Byte;
 PALubyte = ^ALubyte;

 // Signed 16-bit 2's complement integer.
 ALshort  = SmallInt;
 PALshort = ^ALshort;

 // Unsigned 16-bit integer.
 ALushort  = Word;
 PALushort = ^ALushort;

 // Signed 32-bit 2's complement integer.
 ALint  = LongInt;
 PALint = ^ALint;

 // Unsigned 32-bit integer.
 ALuint  = LongWord;
 PALuint = ^ALuint;

 // Non-negative 32-bit binary integer size.
 ALsizei  = LongInt;
 PALsizei = ^ALsizei;

 // Enumerated 32-bit value.
 ALenum  = LongInt;
 PALenum = ^ALenum;

 // 32-bit IEEE754 floating-point.
 ALfloat  = Single;
 PALfloat = ^ALfloat;

 // 64-bit IEEE754 floating-point
 ALdouble  = Double;
 PALdouble = ^ALdouble;

 // Void type (for opaque pointers only).
// ALvoid = ??
 PALvoid = Pointer;

//...........................................................................

 // 8-bit boolean.
 ALCboolean  = ByteBool;
 PALCboolean = ^ALCboolean;

 // Character.
 ALCchar  = ALchar;
 PALCchar = ^ALCchar;

 // Signed 8-bit 2's complement integer.
 ALCbyte  = ShortInt;
 PALCbyte = ^ALCbyte;

 // Unsigned 8-bit integer.
 ALCubyte  = Byte;
 PALCubyte = ^ALCubyte;

 // Signed 16-bit 2's complement integer.
 ALCshort  = SmallInt;
 PALCshort = ^ALCshort;

 // Unsigned 16-bit integer.
 ALCushort  = Word;
 PALCushort = ^ALCushort;

 // Signed 32-bit 2's complement integer.
 ALCint  = LongInt;
 PALCint = ^ALCint;

 // Unsigned 32-bit integer.
 ALCuint  = LongWord;
 PALCuint = ^ALCuint;

 // Non-negative 32-bit binary integer size.
 ALCsizei  = LongInt;
 PALCsizei = ^ALCsizei;

 // Enumerated 32-bit value.
 ALCenum  = LongInt;
 PALCenum = ^ALCenum;

 // 32-bit IEEE754 floating-point.
 ALCfloat  = Single;
 PALCfloat = ^ALCfloat;

 // 64-bit IEEE754 floating-point.
 ALCdouble  = Double;
 PALCdouble = ^ALCdouble;

 // Void type (for opaque pointers only).
 ALCvoid  = Pointer;
 PALCvoid = ^ALCvoid;

 // ALCdevice_struct equivalent.
// ALCdevice  = ??
 PALCdevice = Pointer;

 // ALCcontext_struct equivalent.
// ALCcontext  = ??
 PALCcontext = Pointer;

//---------------------------------------------------------------------------
const
 // Bad value.
 AL_INVALID = -1;

 // No error.
 AL_NONE = 0;

 // Boolean False.
 AL_FALSE = 0;

 // Boolean True.
 AL_TRUE = 1;

 // Indicate Source has relative coordinates.
 AL_SOURCE_RELATIVE = $202;

 // Directional source, outer cone angle, in degrees.
 // Range  : [0-360]
 // Default: 360
 AL_CONE_INNER_ANGLE = $1001;

 // Directional source, outer cone angle, in degrees.
 // Range  : [0-360]
 // Default: 360
 AL_CONE_OUTER_ANGLE = $1002;

 // Specify the pitch to be applied, either at source,
 //  or on mixer results, at listener.
 // Range  : [0.5-2.0]
 // Default: 1.0
 AL_PITCH = $1003;

 // Specify the current location in three dimensional space.
 // OpenAL, like OpenGL, uses a right handed coordinate system,
 //  where in a frontal default view X (thumb) points right,
 //  Y points up (index finger), and Z points towards the
 //  viewer/camera (middle finger).
 // To switch from a left handed coordinate system, flip the
 //  sign on the Z coordinate.
 // Listener position is always in the world coordinate system.
 AL_POSITION = $1004;

 // Specify the current direction.
 AL_DIRECTION = $1005;

 // Specify the current velocity in three dimensional space.
 AL_VELOCITY = $1006;

 // Indicate whether source is looping.
 // Type   : ALboolean?
 // Range  : [AL_TRUE, AL_FALSE]
 // Default: FALSE.
 AL_LOOPING = $1007;

 // Indicate the buffer to provide sound samples.
 // Type : ALuint.
 // Range: any valid Buffer id.
 AL_BUFFER = $1009;

 // Indicate the gain (volume amplification) applied.
 // Type:   ALfloat.
 // Range:  ]0.0-  ] - ??
 // A value of 1.0 means un-attenuated/unchanged.
 // Each division by 2 equals an attenuation of -6dB.
 // Each multiplicaton with 2 equals an amplification of +6dB.
 // A value of 0.0 is meaningless with respect to a logarithmic
 //  scale; it is interpreted as zero volume - the channel
 //  is effectively disabled.
 AL_GAIN = $100A;

 // Indicate minimum source attenuation
 // Type : ALfloat
 // Range: [0.0 - 1.0]
 // Logarthmic
 AL_MIN_GAIN = $100D;

 // Indicate maximum source attenuation
 // Type : ALfloat
 // Range: [0.0 - 1.0]
 // Logarthmic
 AL_MAX_GAIN = $100E;

 // Indicate listener orientation (at/up).
 AL_ORIENTATION = $100F;

 // Specify the channel mask. (Creative)
 // Type : ALuint
 // Range: [0 - 255]
 AL_CHANNEL_MASK = $3000;

 // Source state information.
 AL_SOURCE_STATE = $1010;
 AL_INITIAL      = $1011;
 AL_PLAYING      = $1012;
 AL_PAUSED       = $1013;
 AL_STOPPED      = $1014;

 // Buffer Queue params
 AL_BUFFERS_QUEUED    = $1015;
 AL_BUFFERS_PROCESSED = $1016;

 // Source buffer position information
 AL_SEC_OFFSET    = $1024;
 AL_SAMPLE_OFFSET = $1025;
 AL_BYTE_OFFSET   = $1026;

 // Source type (Static, Streaming or undetermined).
 // Source is Static if a Buffer has been attached using AL_BUFFER.
 // Source is Streaming if one or more Buffers have been attached
 //  using alSourceQueueBuffers.
 // Source is undetermined when it has the NULL buffer attached.
 AL_SOURCE_TYPE  = $1027;
 AL_STATIC       = $1028;
 AL_STREAMING    = $1029;
 AL_UNDETERMINED = $1030;

 // Sound samples: format specifier.
 AL_FORMAT_MONO8      = $1100;
 AL_FORMAT_MONO16     = $1101;
 AL_FORMAT_STEREO8    = $1102;
 AL_FORMAT_STEREO16   = $1103;

 // Source specific reference distance.
 // Type : ALfloat
 // Range: [0.0 - +inf)
 // At 0.0, no distance attenuation occurs. Default is 1.0.
 AL_REFERENCE_DISTANCE = $1020;

 // Source specific rolloff factor.
 // Type : ALfloat
 // Range: [0.0 - +inf)
 AL_ROLLOFF_FACTOR = $1021;

 // Directional source, outer cone gain.
 // Default: 0.0
 // Range  : [0.0 - 1.0]
 // Logarithmic
 AL_CONE_OUTER_GAIN = $1022;

 // Indicate distance above which sources are not
 // attenuated using the inverse clamped distance model.
 // Default: +inf
 // Type   : ALfloat
 // Range  : [0.0 - +inf)
 AL_MAX_DISTANCE = $1023;

 // Sound samples: frequency, in units of Hertz [Hz].
 // This is the number of samples per second. Half of the
 //  sample frequency marks the maximum significant
 //  frequency component.
 AL_FREQUENCY = $2001;
 AL_BITS      = $2002;
 AL_CHANNELS  = $2003;
 AL_SIZE      = $2004;

 // Buffer state.
 // Not supported for public use (yet).
 AL_UNUSED    = $2010;
 AL_PENDING   = $2011;
 AL_PROCESSED = $2012;

 // Errors: No Error.
 AL_NO_ERROR = AL_FALSE;

 // Invalid Name paramater passed to AL call.
 AL_INVALID_NAME = $A001;

 // Invalid parameter passed to AL call.
 AL_ILLEGAL_ENUM = $A002;
 AL_INVALID_ENUM = $A002;

 // Invalid enum parameter value.
 AL_INVALID_VALUE = $A003;

 // Illegal call.
 AL_ILLEGAL_COMMAND   = $A004;
 AL_INVALID_OPERATION = $A004;

 // No mojo.
 AL_OUT_OF_MEMORY = $A005;

 // Context strings: Vendor Name.
 AL_VENDOR     = $B001;
 AL_VERSION    = $B002;
 AL_RENDERER   = $B003;
 AL_EXTENSIONS = $B004;

 // Doppler scale.  Default 1.0
 AL_DOPPLER_FACTOR = $C000;

 // Tweaks speed of propagation.
 AL_DOPPLER_VELOCITY = $C001;

 // Speed of Sound in units per second
 AL_SPEED_OF_SOUND = $C003;

 // Distance models used in conjunction with DistanceModel implicit:
 // NONE, which disances distance attenuation.
 AL_DISTANCE_MODEL           = $D000;
 AL_INVERSE_DISTANCE         = $D001;
 AL_INVERSE_DISTANCE_CLAMPED = $D002;
 AL_LINEAR_DISTANCE          = $D003;
 AL_LINEAR_DISTANCE_CLAMPED  = $D004;
 AL_EXPONENT_DISTANCE        = $D005;
 AL_EXPONENT_DISTANCE_CLAMPED = $D006;

//...........................................................................

 // Boolean False.
 ALC_FALSE = 0;

 // Boolean True.
 ALC_TRUE = 1;

 // Followed by <int> Hz.
 ALC_FREQUENCY = $1007;

 // Followed by <int> Hz.
 ALC_REFRESH = $1008;

 // Followed by AL_TRUE, AL_FALSE.
 ALC_SYNC = $1009;

 // Followed by <int> Num of requested Mono (3D) Sources.
 ALC_MONO_SOURCES = $1010;

 // Followed by <int> Num of requested Stereo Sources.
 ALC_STEREO_SOURCES = $1011;

 // No error.
 ALC_NO_ERROR = ALC_FALSE;

 // No device.
 ALC_INVALID_DEVICE = $A001;

 // Invalid context ID.
 ALC_INVALID_CONTEXT = $A002;

 // Bad enum.
 ALC_INVALID_ENUM = $A003;

 // Bad value.
 ALC_INVALID_VALUE = $A004;

 // Out of memory.
 ALC_OUT_OF_MEMORY = $A005;

 // The Specifier string for default device
 ALC_DEFAULT_DEVICE_SPECIFIER = $1004;
 ALC_DEVICE_SPECIFIER = $1005;
 ALC_EXTENSIONS = $1006;

 ALC_MAJOR_VERSION = $1000;
 ALC_MINOR_VERSION = $1001;

 ALC_ATTRIBUTES_SIZE = $1002;
 ALC_ALL_ATTRIBUTES  = $1003;

 // ALC_ENUMERATE_ALL_EXT enums
 ALC_DEFAULT_ALL_DEVICES_SPECIFIER = $1012;
 ALC_ALL_DEVICES_SPECIFIER         = $1013;

 // Capture extension
 ALC_CAPTURE_DEVICE_SPECIFIER = $310;
 ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER = $311;
 ALC_CAPTURE_SAMPLES = $312;

//---------------------------------------------------------------------------
var
 //..........................................................................
 // Renderer State management.
 //..........................................................................
 alEnable   : procedure(capability: ALenum); cdecl;
 alDisable  : procedure(capability: ALenum); cdecl;
 alIsEnabled: function(capability: ALenum): ALboolean; cdecl;

 //..........................................................................
 // State retrieval.
 //..........................................................................
 alGetString  : function(param: ALenum): PALchar; cdecl;
 alGetBooleanv: procedure(param: ALenum; Data: PALboolean); cdecl;
 alGetIntegerv: procedure(param: ALenum; Data: PALint); cdecl;
 alGetFloatv  : procedure(param: ALenum; Data: PALfloat); cdecl;
 alGetDoublev : procedure(param: ALenum; Data: PALdouble); cdecl;

 //..........................................................................
 alGetBoolean: function(param: ALenum): ALboolean; cdecl;
 alGetInteger: function(param: ALenum): ALint; cdecl;
 alGetFloat  : function(param: ALenum): ALfloat; cdecl;
 alGetDouble : function(param: ALenum): ALdouble; cdecl;

 //..........................................................................
 // ERROR support.
 //..........................................................................
 // Obtain the most recent error generated in the AL state machine.
 alGetError: function(): ALenum; cdecl;

 //..........................................................................
 // EXTENSION support.
 //..........................................................................
 // Query for the presence of an extension, and obtain any appropriate
 // function pointers and enum values.
 alIsExtensionPresent: function(extname: PALchar): ALboolean; cdecl;
 alGetProcAddress    : function(fname: PALchar): PALvoid; cdecl;
 alGetEnumValue      : function(ename: PALchar): ALenum; cdecl;

 //..........................................................................
 // LISTENER
 //..........................................................................
 // Listener represents the location and orientation of the 'user' in
 // 3D-space.
 //
 // Properties include: -
 //
 // Gain         AL_GAIN         ALfloat
 // Position     AL_POSITION     ALfloat[3]
 // Velocity     AL_VELOCITY     ALfloat[3]
 // Orientation  AL_ORIENTATION  ALfloat[6] (Forward then Up vectors)

 // Set Listener parameters.
 alListenerf: procedure(param: ALenum; value: ALfloat); cdecl;

 alListener3f: procedure(param: ALenum; value1: ALfloat; value2: ALfloat;
  value3: ALfloat); cdecl;

 alListenerfv: procedure(param: ALenum; values: PALfloat); cdecl;
 alListeneri : procedure(param: ALenum; value: ALint); cdecl;

 alListener3i: procedure(param: ALenum; value1: ALint; value2: ALint;
  value3: ALint);

 alListeneriv: procedure(param: ALenum; values: PALint);

 //..........................................................................

 // Get Listener parameters.
 alGetListenerf: procedure(param: ALenum; value: PALfloat); cdecl;

 alGetListener3f: procedure(param: ALenum; value1: PALfloat;
  value2: PALfloat; value3: PALfloat); cdecl;

 alGetListenerfv: procedure(param: ALenum; values: PALfloat); cdecl;
 alGetListeneri : procedure(param: ALenum; value: PALint); cdecl;

 alGetListener3i: procedure(param: ALenum; value1: PALint; value2: PALint;
  value3: PALint); cdecl;

 alGetListeneriv: procedure(param: ALenum; values: PALint); cdecl;

 //..........................................................................
 // SOURCE
 //..........................................................................
 // Sources represent individual sound objects in 3D-space.
 // Sources take the PCM data provided in the specified Buffer,
 // apply Source-specific modifications, and then
 // submit them to be mixed according to spatial arrangement etc.
 //
 // Properties include: -
 //
 // Gain                           AL_GAIN               ALfloat
 // Min Gain                       AL_MIN_GAIN           ALfloat
 // Max Gain                       AL_MAX_GAIN           ALfloat
 // Position                       AL_POSITION           ALfloat[3]
 // Velocity                       AL_VELOCITY           ALfloat[3]
 // Direction                      AL_DIRECTION          ALfloat[3]
 // Head Relative Mode             AL_SOURCE_RELATIVE    ALint (AL_TRUE or AL_FALSE)
 // Reference Distance             AL_REFERENCE_DISTANCE ALfloat
 // Max Distance                   AL_MAX_DISTANCE       ALfloat
 // RollOff Factor                 AL_ROLLOFF_FACTOR     ALfloat
 // Inner Angle                    AL_CONE_INNER_ANGLE   ALint or ALfloat
 // Outer Angle                    AL_CONE_OUTER_ANGLE   ALint or ALfloat
 // Cone Outer Gain                AL_CONE_OUTER_GAIN    ALint or ALfloat
 // Pitch                          AL_PITCH              ALfloat
 // Looping                        AL_LOOPING            ALint (AL_TRUE or AL_FALSE)
 // MS Offset                      AL_MSEC_OFFSET        ALint or ALfloat
 // Byte Offset                    AL_BYTE_OFFSET        ALint or ALfloat
 // Sample Offset                  AL_SAMPLE_OFFSET      ALint or ALfloat
 // Attached Buffer                AL_BUFFER             ALint
 // State (Query only)             AL_SOURCE_STATE       ALint
 // Buffers Queued (Query only)    AL_BUFFERS_QUEUED     ALint
 // Buffers Processed (Query only) AL_BUFFERS_PROCESSED  ALint

 // Create Source objects.
 alGenSources: procedure(n: ALsizei; sources: PALuint); cdecl;

 // Delete Source objects.
 alDeleteSources: procedure(n: ALsizei; sources: PALuint); cdecl;

 // Verify a handle is a valid Source.
 alIsSource: function(sid: ALuint): ALboolean; cdecl;

 //..........................................................................

 // Set Source parameters.
 alSourcef: procedure(sid: ALuint; param: ALenum; value: ALfloat); cdecl;

 alSource3f: procedure(sid: ALuint; param: ALenum; value1: ALfloat;
  value2: ALfloat; value3: ALfloat); cdecl;

 alSourcefv: procedure(sid: ALuint; param: ALenum; values: PALfloat); cdecl;
 alSourcei : procedure(sid: ALuint; param: ALenum; value: ALint); cdecl;

 alSource3i: procedure(sid: ALuint; param: ALenum; value1: ALint;
 value2: ALint; value3: ALint); cdecl;

 alSourceiv: procedure(sid: ALuint; param: ALenum; values: PALint); cdecl;

 //..........................................................................

 // Get Source parameters.
 alGetSourcef: procedure(sid: ALuint; param: ALenum; value: PALfloat); cdecl;

 alGetSource3f: procedure(sid: ALuint; param: ALenum; value1: PALfloat;
  value2: PALfloat; value3: PALfloat); cdecl;

 alGetSourcefv: procedure(sid: ALuint; param: ALenum; values: PALfloat); cdecl;
 alGetSourcei : procedure(sid: ALuint; param: ALenum; value: PALint); cdecl;

 alGetSource3i: procedure(sid: ALuint; param: ALenum; value1: PALint;
  value2: PALint; value3: PALint); cdecl;

 alGetSourceiv: procedure(sid: ALuint; param: ALenum; values: PALint); cdecl;

 //..........................................................................
 // Source vector based playback calls.
 //..........................................................................
 // Play, replay, or resume (if paused) a list of Sources.
 alSourcePlayv: procedure(ns: ALsizei; sids: PALuint); cdecl;

 // Stop a list of Sources.
 alSourceStopv: procedure(ns: ALsizei; sids: PALuint); cdecl;

 // Rewind a list of Sources.
 alSourceRewindv: procedure(ns: ALsizei; sids: PALuint); cdecl;

 // Pause a list of Sources.
 alSourcePausev: procedure(ns: ALsizei; sids: PALuint); cdecl;

 //..........................................................................
 // Source based playback calls.
 //..........................................................................
 // Play, replay, or resume a Source.
 alSourcePlay: procedure(sid: ALuint); cdecl;

 // Stop a Source.
 alSourceStop: procedure(sid: ALuint); cdecl;

 // Rewind a Source (set playback postiton to beginning).
 alSourceRewind: procedure(sid: ALuint); cdecl;

 // Pause a Source.
 alSourcePause: procedure(sid: ALuint); cdecl;

 // Source Queuing
 alSourceQueueBuffers: procedure(sid: ALuint; numEntries: ALsizei;
  bids: PALuint); cdecl;

 alSourceUnqueueBuffers: procedure(sid: ALuint; numEntries: ALsizei;
  bids: PALuint); cdecl;

 //..........................................................................
 // BUFFER
 //..........................................................................
 // Buffer objects are storage space for sample data.
 // Buffers are referred to by Sources. One Buffer can be used
 // by multiple Sources.
 //
 // Properties include: -
 //
 // Frequency (Query only)    AL_FREQUENCY      ALint
 // Size (Query only)         AL_SIZE           ALint
 // Bits (Query only)         AL_BITS           ALint
 // Channels (Query only)     AL_CHANNELS       ALint

 // Create Buffer objects.
 alGenBuffers: procedure(n: ALsizei; buffers: PALuint); cdecl;

 // Delete Buffer objects.
 alDeleteBuffers: procedure(n: ALsizei; buffers: PALuint); cdecl;

 // Verify a handle is a valid Buffer.
 alIsBuffer: function(bid: ALuint): ALboolean; cdecl;

 // Specify the data to be copied into a buffer.
 alBufferData: procedure(bid: ALuint; format: ALenum; data: PALvoid;
  size: ALsizei; freq: ALsizei); cdecl;

 //..........................................................................
 // Set Buffer parameters.
 //..........................................................................
 alBufferf: procedure(bid: ALuint; param: ALenum; value: ALfloat); cdecl;

 alBuffer3f: procedure(bid: ALuint; param: ALenum; value1: ALfloat;
  value2: ALfloat; value3: ALfloat); cdecl;

 alBufferfv: procedure(bid: ALuint; param: ALenum; values: PALfloat); cdecl;

 alBufferi: procedure(bid: ALuint; param: ALenum; value: ALint); cdecl;

 alBuffer3i: procedure(bid: ALuint; param: ALenum; value1: ALint;
  value2: ALint; value3: ALint); cdecl;

 alBufferiv: procedure(bid: ALuint; param: ALenum; values: PALint); cdecl;

 //..........................................................................
 // Get Buffer parameters.
 //..........................................................................
 alGetBufferf: procedure(bid: ALuint; param: ALenum; value: PALfloat); cdecl;

 alGetBuffer3f: procedure(bid: ALuint; param: ALenum; value1: PALfloat;
  value2: PALfloat; value3: PALfloat); cdecl;

 alGetBufferfv: procedure(bid: ALuint; param: ALenum; values: PALfloat); cdecl;

 alGetBufferi: procedure(bid: ALuint; param: ALenum; value: PALint); cdecl;

 alGetBuffer3i: procedure(bid: ALuint; param: ALenum; value1: PALint;
  value2: PALint; value3: PALint); cdecl;

 alGetBufferiv: procedure(bid: ALuint; param: ALenum; values: PALint); cdecl;

 //..........................................................................
 // Global Parameters.
 //..........................................................................
 alDopplerFactor  : procedure(value: ALfloat); cdecl;
 alDopplerVelocity: procedure(value: ALfloat); cdecl;
 alSpeedOfSound   : procedure(value: ALfloat); cdecl;
 alDistanceModel  : procedure(distanceModel: ALenum); cdecl;

 //..........................................................................
 // Context Management.
 //..........................................................................
 alcCreateContext:   function(device: PALCdevice;
  attrlist: PALCint): PALCcontext; cdecl;

 alcMakeContextCurrent: function(context: PALCcontext): ALCboolean; cdecl;

 alcProcessContext: procedure(context: PALCcontext); cdecl;
 alcSuspendContext: procedure(context: PALCcontext); cdecl;
 alcDestroyContext: procedure(context: PALCcontext); cdecl;

 alcGetCurrentContext: function(): PALCcontext; cdecl;
 alcGetContextsDevice: function(context: PALCcontext): PALCdevice; cdecl;

 //..........................................................................
 // Device Management.
 //..........................................................................
 alcOpenDevice : function(const devicename: PALCchar): PALCdevice; cdecl;
 alcCloseDevice: function(device: PALCdevice): ALCboolean; cdecl;

 //..........................................................................
 // Error support.
 //..........................................................................
 // Obtain the most recent Context error.
 alcGetError: function(device: PALCdevice): ALCenum; cdecl;

 //..........................................................................
 // Extension support.
 //..........................................................................
 // Query for the presence of an extension, and obtain any appropriate
 // function pointers and enum values.
 alcIsExtensionPresent: function(device: PALCdevice;
  const extName: PALCchar): ALCboolean; cdecl;

 alcGetProcAddress: function(device: PALCdevice;
  const funcname: PALCchar): PALCvoid; cdecl;

 alcGetEnumValue: function(device: PALCdevice;
  const enumname: PALCchar): ALCenum; cdecl;

 //..........................................................................
 // Query functions.
 //..........................................................................
 alcGetString: function(device: PALCdevice; param: ALCenum): PALCchar; cdecl;

 alcGetIntegerv: procedure(device: PALCdevice; param: ALCenum;
  size: ALCsizei; data: PALCint); cdecl;

 //..........................................................................
 // Capture functions.
 //..........................................................................
 alcCaptureOpenDevice: function(const devicename: PALCchar; frequency: ALCuint;
  format: ALCenum; buffersize: ALCsizei): PALCdevice; cdecl;

 alcCaptureCloseDevice: function(device: PALCdevice): ALCboolean; cdecl;

 alcCaptureStart: procedure(device: PALCdevice); cdecl;
 alcCaptureStop : procedure(device: PALCdevice); cdecl;

 alcCaptureSamples: procedure(device: PALCdevice; buffer: ALCvoid;
  samples: ALCsizei); cdecl;

//---------------------------------------------------------------------------
function InitOpenAL(): Boolean;
procedure DoneOpenAL();

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifdef MsWindows}
 Windows
{$else}
 SysUtils
{$endif};

//---------------------------------------------------------------------------
const
{$ifdef MsWindows}
 DynamicLibName = 'OpenAL32.dll';
{$endif}
{$ifdef MacOS}
 DynamicLibName = '/System/Library/Frameworks/OpenAL.framework/OpenAL';
{$endif}
{$ifdef Linux}
 DynamicLibName = 'libopenal.so';
{$endif}

//---------------------------------------------------------------------------
var
 LibHandle: THandle = 0;

//---------------------------------------------------------------------------
function GetProcAddressEx(const ProcName: string): Pointer;
{$ifdef DelphiNextGen}
var
 TempBytes: TBytes;
{$endif}
begin
 Result:= nil;

 if (Assigned(alGetProcAddress)) then
  begin
  {$ifdef DelphiNextGen}
   SetLength(TempBytes, Length(ProcName) + 1);
   TMarshal.WriteStringAsAnsi(TPtrWrapper.Create(@TempBytes[0]), ProcName,
    Length(ProcName));

   Result:= alGetProcAddress(@TempBytes[0]);
  {$else}
   Result:= alGetProcAddress(PALchar(AnsiString(ProcName)));
  {$endif}
  end;

 if (not Assigned(Result)) then
  Result:= GetProcAddress(LibHandle, PChar(ProcName));
end;

//---------------------------------------------------------------------------
procedure LoadProcAddreses();
begin
 alGetProcAddress:= GetProcAddress(LibHandle, 'alGetProcAddress');

 alEnable     := GetProcAddressEx('alEnable');
 alDisable    := GetProcAddressEx('alDisable');
 alIsEnabled  := GetProcAddressEx('alIsEnabled');
 alGetString  := GetProcAddressEx('alGetString');
 alGetBooleanv:= GetProcAddressEx('alGetBooleanv');
 alGetIntegerv:= GetProcAddressEx('alGetIntegerv');
 alGetFloatv  := GetProcAddressEx('alGetFloatv');
 alGetDoublev := GetProcAddressEx('alGetDoublev');
 alGetBoolean := GetProcAddressEx('alGetBoolean');
 alGetInteger := GetProcAddressEx('alGetInteger');
 alGetFloat   := GetProcAddressEx('alGetFloat');
 alGetDouble  := GetProcAddressEx('alGetDouble');
 alGetError   := GetProcAddressEx('alGetError');

 alIsExtensionPresent:= GetProcAddressEx('alIsExtensionPresent');
 alGetProcAddress    := GetProcAddressEx('alGetProcAddress');

 alGetEnumValue := GetProcAddressEx('alGetEnumValue');
 alListenerf    := GetProcAddressEx('alListenerf');
 alListener3f   := GetProcAddressEx('alListener3f');
 alListenerfv   := GetProcAddressEx('alListenerfv');
 alListeneri    := GetProcAddressEx('alListeneri');
 alListener3i   := GetProcAddressEx('alListener3i');
 alListeneriv   := GetProcAddressEx('alListeneriv');
 alGetListenerf := GetProcAddressEx('alGetListenerf');
 alGetListener3f:= GetProcAddressEx('alGetListener3f');
 alGetListenerfv:= GetProcAddressEx('alGetListenerfv');
 alGetListeneri := GetProcAddressEx('alGetListeneri');
 alGetListener3i:= GetProcAddressEx('alGetListener3i');
 alGetListeneriv:= GetProcAddressEx('alGetListeneriv');
 alGenSources   := GetProcAddressEx('alGenSources');
 alDeleteSources:= GetProcAddressEx('alDeleteSources');

 alIsSource:= GetProcAddressEx('alIsSource');
 alSourcef := GetProcAddressEx('alSourcef');
 alSource3f:= GetProcAddressEx('alSource3f');
 alSourcefv:= GetProcAddressEx('alSourcefv');
 alSourcei := GetProcAddressEx('alSourcei');
 alSource3i:= GetProcAddressEx('alSource3i');
 alSourceiv:= GetProcAddressEx('alSourceiv');

 alGetSourcef := GetProcAddressEx('alGetSourcef');
 alGetSource3f:= GetProcAddressEx('alGetSource3f');
 alGetSourcefv:= GetProcAddressEx('alGetSourcefv');
 alGetSourcei := GetProcAddressEx('alGetSourcei');
 alGetSource3i:= GetProcAddressEx('alGetSource3i');
 alGetSourceiv:= GetProcAddressEx('alGetSourceiv');

 alSourcePlayv  := GetProcAddressEx('alSourcePlayv');
 alSourceStopv  := GetProcAddressEx('alSourceStopv');
 alSourceRewindv:= GetProcAddressEx('alSourceRewindv');
 alSourcePausev := GetProcAddressEx('alSourcePausev');
 alSourcePlay   := GetProcAddressEx('alSourcePlay');
 alSourceStop   := GetProcAddressEx('alSourceStop');
 alSourceRewind := GetProcAddressEx('alSourceRewind');
 alSourcePause  := GetProcAddressEx('alSourcePause');

 alSourceQueueBuffers  := GetProcAddressEx('alSourceQueueBuffers');
 alSourceUnqueueBuffers:= GetProcAddressEx('alSourceUnqueueBuffers');

 alGenBuffers   := GetProcAddressEx('alGenBuffers');
 alDeleteBuffers:= GetProcAddressEx('alDeleteBuffers');
 alIsBuffer     := GetProcAddressEx('alIsBuffer');
 alBufferData   := GetProcAddressEx('alBufferData');

 alBufferf := GetProcAddressEx('alBufferf');
 alBuffer3f:= GetProcAddressEx('alBuffer3f');
 alBufferfv:= GetProcAddressEx('alBufferfv');
 alBufferi := GetProcAddressEx('alBufferi');
 alBuffer3i:= GetProcAddressEx('alBuffer3i');
 alBufferiv:= GetProcAddressEx('alBufferiv');

 alGetBufferf := GetProcAddressEx('alGetBufferf');
 alGetBuffer3f:= GetProcAddressEx('alGetBuffer3f');
 alGetBufferfv:= GetProcAddressEx('alGetBufferfv');
 alGetBufferi := GetProcAddressEx('alGetBufferi');
 alGetBuffer3i:= GetProcAddressEx('alGetBuffer3i');
 alGetBufferiv:= GetProcAddressEx('alGetBufferiv');

 alDopplerFactor  := GetProcAddressEx('alDopplerFactor');
 alDopplerVelocity:= GetProcAddressEx('alDopplerVelocity');
 alSpeedOfSound   := GetProcAddressEx('alSpeedOfSound');
 alDistanceModel  := GetProcAddressEx('alDistanceModel');

 alcCreateContext:= GetProcAddressEx('alcCreateContext');
 alcMakeContextCurrent:= GetProcAddressEx('alcMakeContextCurrent');

 alcProcessContext:= GetProcAddressEx('alcProcessContext');
 alcSuspendContext:= GetProcAddressEx('alcSuspendContext');
 alcDestroyContext:= GetProcAddressEx('alcDestroyContext');

 alcGetCurrentContext:= GetProcAddressEx('alcGetCurrentContext');
 alcGetContextsDevice:= GetProcAddressEx('alcGetContextsDevice');

 alcOpenDevice := GetProcAddressEx('alcOpenDevice');
 alcCloseDevice:= GetProcAddressEx('alcCloseDevice');
 alcGetError   := GetProcAddressEx('alcGetError');

 alcIsExtensionPresent:= GetProcAddressEx('alcIsExtensionPresent');

 alcGetProcAddress:= GetProcAddressEx('alcGetProcAddress');
 alcGetEnumValue  := GetProcAddressEx('alcGetEnumValue');
 alcGetString     := GetProcAddressEx('alcGetString');
 alcGetIntegerv   := GetProcAddressEx('alcGetIntegerv');

 alcCaptureOpenDevice := GetProcAddressEx('alcCaptureOpenDevice');
 alcCaptureCloseDevice:= GetProcAddressEx('alcCaptureCloseDevice');

 alcCaptureStart  := GetProcAddressEx('alcCaptureStart');
 alcCaptureStop   := GetProcAddressEx('alcCaptureStop');
 alcCaptureSamples:= GetProcAddressEx('alcCaptureSamples');
end;

//---------------------------------------------------------------------------
function InitOpenAL(): Boolean;
begin
 if (LibHandle <> 0) then
  begin
   Result:= True;
   Exit;
  end;

 LibHandle:= LoadLibrary(PChar(DynamicLibName));

 Result:= LibHandle <> 0;
 if (not Result) then Exit;

 LoadProcAddreses();
end;

//---------------------------------------------------------------------------
procedure DoneOpenAL();
begin
 if (LibHandle <> 0) then
  begin
   FreeLibrary(LibHandle);
   LibHandle:= 0;
  end;
end;

//---------------------------------------------------------------------------
end.

