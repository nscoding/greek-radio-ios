#import "AudioStreamer.h"
#ifdef TARGET_OS_IPHONE
#import <SystemConfiguration/SystemConfiguration.h>
#import <CFNetwork/CFNetwork.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <arpa/inet.h>
#include <netdb.h>
#endif

#import "TestFlight.h"
#import "NSInternetDoctor.h"
#import "BlockAlertView.h"
#import <MessageUI/MessageUI.h>

#define PRINTERROR(LABEL)	printf("%s err %4.4s %d\n", LABEL, (char *)&err, (int)err)

#pragma mark CFReadStream Callback Function Prototypes

void ReadStreamCallBack(
                        CFReadStreamRef stream,
                        CFStreamEventType eventType,
                        void* dataIn);

#pragma mark Audio Callback Function Prototypes

void MyAudioQueueOutputCallback(void* inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);
void MyPropertyListenerProc(	void *							inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            UInt32 *						ioFlags);
void MyPacketsProc(				void *							inClientData,
                   UInt32							inNumberBytes,
                   UInt32							inNumberPackets,
                   const void *					inInputData,
                   AudioStreamPacketDescription	*inPacketDescriptions);
OSStatus MyEnqueueBuffer(AudioStreamer* myData);

#ifdef TARGET_OS_IPHONE
void MyAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState);
#endif

#pragma mark Audio Callback Function Implementations

//
// MyPropertyListenerProc
//
// Receives notification when the AudioFileStream has audio packets to be
// played. In response, this function creates the AudioQueue, getting it
// ready to begin playback (playback won't begin until audio packets are
// sent to the queue in MyEnqueueBuffer).
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// kAudioQueueProperty_IsRunning listening added.
//
void MyPropertyListenerProc(	void *							inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            UInt32 *						ioFlags)
{
	// this is called by audio file stream when it finds property values
	AudioStreamer* myData = (AudioStreamer*)inClientData;
	OSStatus err = noErr;
    
	switch (inPropertyID) {
		case kAudioFileStreamProperty_ReadyToProducePackets :
		{
			myData->discontinuous = true;
			
			// the file stream parser is now ready to produce audio packets.
			// get the stream format.
			AudioStreamBasicDescription asbd;
			UInt32 asbdSize = sizeof(asbd);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
			if (err) { PRINTERROR("Audio Stream Format"); myData->failed = true; break; }
			
			// create the audio queue
			err = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, myData, NULL, NULL, 0, &myData->audioQueue);
			if (err) { PRINTERROR("Audio queue"); myData->failed = true; break; }
			
			// listen to the "isRunning" property
			err = AudioQueueAddPropertyListener(myData->audioQueue, kAudioQueueProperty_IsRunning, MyAudioQueueIsRunningCallback, myData);
			if (err) { PRINTERROR("Audio Property Listener"); myData->failed = true; break; }
			
			// allocate audio queue buffers
			for (unsigned int i = 0; i < kNumAQBufs; ++i) {
				err = AudioQueueAllocateBuffer(myData->audioQueue, kAQBufSize, &myData->audioQueueBuffer[i]);
				if (err) { PRINTERROR("Audio Buffer"); myData->failed = true; break; }
			}
            
			// get the cookie size
			UInt32 cookieSize;
			Boolean writable;
			
			err = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
			if (err) { PRINTERROR("FileStream Property"); break; }
			
			// get the cookie data
			void* cookieData = calloc(1, cookieSize);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
			if (err) { PRINTERROR("AudioFileStream Property"); free(cookieData); break; }
            
			// set the cookie on the queue.
			err = AudioQueueSetProperty(myData->audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
			free(cookieData);
			if (err) { PRINTERROR("set kAudioQueueProperty_MagicCookie"); break; }
			break;
		}
	}
}

void MyPacketsProc(				void *							inClientData,
                   UInt32							inNumberBytes,
                   UInt32							inNumberPackets,
                   const void *					inInputData,
                   AudioStreamPacketDescription	*inPacketDescriptions)
{
	// this is called by audio file stream when it finds packets of audio
	AudioStreamer* myData = (AudioStreamer*)inClientData;
	
	// we have successfully read the first packests from the audio stream, so
	// clear the "discontinuous" flag
	myData->discontinuous = false;
    
	// the following code assumes we're streaming VBR data. for CBR data, the second branch is used.
	if (inPacketDescriptions)
	{
		for (int i = 0; i < inNumberPackets; ++i) {
			SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
			SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
			
			// If the audio was terminated before this point, then
			// exit.
			if (myData->finished)
			{
				return;
			}
            
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
			if (bufSpaceRemaining < packetSize) {
				MyEnqueueBuffer(myData);
			}
			
			pthread_mutex_lock(&myData->mutex2);
            
			// If the audio was terminated while waiting for a buffer, then
			// exit.
			if (myData->finished)
			{
				pthread_mutex_unlock(&myData->mutex2);
				return;
			}
            
			// copy data to the audio queue buffer
			AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
			memcpy((char*)fillBuf->mAudioData + myData->bytesFilled, (const char*)inInputData + packetOffset, packetSize);
			
			pthread_mutex_unlock(&myData->mutex2);
			
			// fill out packet description
			myData->packetDescs[myData->packetsFilled] = inPacketDescriptions[i];
			myData->packetDescs[myData->packetsFilled].mStartOffset = myData->bytesFilled;
			// keep track of bytes filled and packets filled
			myData->bytesFilled += packetSize;
			myData->packetsFilled += 1;
            
			// if that was the last free packet description, then enqueue the buffer.
			size_t packetsDescsRemaining = kAQMaxPacketDescs - myData->packetsFilled;
			if (packetsDescsRemaining == 0) {
				MyEnqueueBuffer(myData);
			}
		}
	}
	else
	{
		size_t offset = 0;
		while (inNumberBytes)
		{
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
			if (bufSpaceRemaining < inNumberBytes) {
				MyEnqueueBuffer(myData);
			}
			
			pthread_mutex_lock(&myData->mutex2);
            
			// If the audio was terminated while waiting for a buffer, then
			// exit.
			if (myData->finished)
			{
				pthread_mutex_unlock(&myData->mutex2);
				return;
			}
			
			// copy data to the audio queue buffer
			AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
			bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
			size_t copySize;
			if (bufSpaceRemaining < inNumberBytes)
			{
				copySize = bufSpaceRemaining;
			}
			else
			{
				copySize = inNumberBytes;
			}
			memcpy((char*)fillBuf->mAudioData + myData->bytesFilled, (const char*)(inInputData + offset), copySize);
            
			pthread_mutex_unlock(&myData->mutex2);
            
			// keep track of bytes filled and packets filled
			myData->bytesFilled += copySize;
			myData->packetsFilled = 0;
			inNumberBytes -= copySize;
			offset += copySize;
		}
	}
}

//
// MyEnqueueBuffer
//
// Called from MyPacketsProc and connectionDidFinishLoading to pass filled audio
// bufffers (filled by MyPacketsProc) to the AudioQueue for playback. This
// function does not return until a buffer is idle for further filling or
// the AudioQueue is stopped.
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// CBR functionality added.
//
OSStatus MyEnqueueBuffer(AudioStreamer* myData)
{
	OSStatus err = noErr;
	myData->inuse[myData->fillBufferIndex] = true;		// set in use flag
	
	// enqueue buffer
	AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
	fillBuf->mAudioDataByteSize = myData->bytesFilled;
	
	if (myData->packetsFilled)
	{
		err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, myData->packetsFilled, myData->packetDescs);
	}
	else
	{
		err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, 0, NULL);
	}
	
	if (err) { PRINTERROR("AudioQueueEnqueueBuffer"); myData->failed = true; return err; }
	
	if (!myData->started) {		// start the queue if it has not been started already
		err = AudioQueueStart(myData->audioQueue, NULL);
		if (err) { PRINTERROR("AudioQueueStart"); myData->failed = true; return err; }
		myData->started = true;
	}
    
	// go to next buffer
	if (++myData->fillBufferIndex >= kNumAQBufs) myData->fillBufferIndex = 0;
	myData->bytesFilled = 0;		// reset bytes filled
	myData->packetsFilled = 0;		// reset packets filled
    
	// wait until next buffer is not in use
	pthread_mutex_lock(&myData->mutex);
	while (myData->inuse[myData->fillBufferIndex] && !myData->finished)
	{
		pthread_cond_wait(&myData->cond, &myData->mutex);
	}
	pthread_mutex_unlock(&myData->mutex);
    
	return err;
}

//
// MyFindQueueBuffer
//
// Returns the index of the specified buffer in the audioQueueBuffer array.
//
// This function is unchanged from Apple's example in AudioFileStreamExample.
//
int MyFindQueueBuffer(AudioStreamer* myData, AudioQueueBufferRef inBuffer)
{
	for (unsigned int i = 0; i < kNumAQBufs; ++i) {
		if (inBuffer == myData->audioQueueBuffer[i])
			return i;
	}
	return -1;
}

//
// MyAudioQueueOutputCallback
//
// Called from the AudioQueue when playback of specific buffers completes. This
// function signals from the AudioQueue thread to the AudioStream thread that
// the buffer is idle and available for copying data.
//
// This function is unchanged from Apple's example in AudioFileStreamExample.
//
void MyAudioQueueOutputCallback(	void*					inClientData,
                                AudioQueueRef			inAQ,
                                AudioQueueBufferRef		inBuffer)
{
	// this is called by the audio queue when it has finished decoding our data.
	// The buffer is now free to be reused.
	AudioStreamer* myData = (AudioStreamer*)inClientData;
	unsigned int bufIndex = MyFindQueueBuffer(myData, inBuffer);
	
	// signal waiting thread that the buffer is free.
	pthread_mutex_lock(&myData->mutex);
	myData->inuse[bufIndex] = false;
	pthread_cond_signal(&myData->cond);
	pthread_mutex_unlock(&myData->mutex);
}

//
// MyAudioQueueIsRunningCallback
//
// Called from the AudioQueue when playback is started or stopped. This
// information is used to toggle the observable "isPlaying" property and
// set the "finished" flag.
//
void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
	AudioStreamer *myData = (AudioStreamer *)inUserData;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (myData.isPlaying)
	{
		myData->finished = true;
		myData.isPlaying = false;
        
#ifdef TARGET_OS_IPHONE
		AudioSessionSetActive(false);
#endif
	}
	else
	{
		myData.isPlaying = true;
		if (myData->finished)
		{
			myData.isPlaying = false;
		}
		
		//
		// Note about this bug avoidance quirk:
		//
		// On cleanup of the AudioQueue thread, on rare occasions, there would
		// be a crash in CFSetContainsValue as a CFRunLoopObserver was getting
		// removed from the CFRunLoop.
		//
		// After lots of testing, it appeared that the audio thread was
		// attempting to remove CFRunLoop observers from the CFRunLoop after the
		// thread had already deallocated the run loop.
		//
		// By creating an NSRunLoop for the AudioQueue thread, it changes the
		// thread destruction order and seems to avoid this crash bug -- or
		// at least I haven't had it since (nasty hard to reproduce error!)
		//
		[NSRunLoop currentRunLoop];
	}
	
	[pool release];
}

#ifdef TARGET_OS_IPHONE
//
// MyAudioSessionInterruptionListener
//
// Invoked if the audio session is interrupted (like when the phone rings)
//
void MyAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
}
#endif

#pragma mark CFReadStream Callback Function Implementations

//
// ReadStreamCallBack
//
// This is the callback for the CFReadStream from the network connection. This
// is where all network data is passed to the AudioFileStream.
//
// Invoked when an error occurs, the stream ends or we have data to read.
//
void ReadStreamCallBack
(
 CFReadStreamRef stream,
 CFStreamEventType eventType,
 void* dataIn
 )
{
	AudioStreamer *myData = (AudioStreamer *)dataIn;
	
	if (eventType == kCFStreamEventErrorOccurred)
	{
		myData->failed = YES;
	}
	else if (eventType == kCFStreamEventEndEncountered)
	{
		if (myData->failed || myData->finished)
		{
			return;
		}
		
		//
		// If there is a partially filled buffer, pass it to the AudioQueue for
		// processing
		//
		if (myData->bytesFilled)
		{
			MyEnqueueBuffer(myData);
		}
        
		//
		// If the AudioQueue started, then flush it (to make certain everything
		// sent thus far will be processed) and subsequently stop the queue.
		//
		if (myData->started)
		{
			OSStatus err = AudioQueueFlush(myData->audioQueue);
			if (err) { PRINTERROR("AudioQueueFlush"); return; }
			
			err = AudioQueueStop(myData->audioQueue, false);
			if (err) { PRINTERROR("AudioQueueStop"); return; }
            
			CFReadStreamClose(stream);
			CFRelease(stream);
			myData->stream = nil;
		}
		else
		{
			//
			// If we have reached the end of the file without starting, then we
			// have failed to find any audio in the file. Abort.
			//
			myData->failed = YES;
		}
	}
	else if (eventType == kCFStreamEventHasBytesAvailable)
	{
		if (myData->failed || myData->finished)
		{
			return;
		}
		
		//
		// Read the bytes from the stream
		//
		UInt8 bytes[kAQBufSize];
		CFIndex length = CFReadStreamRead(stream, bytes, kAQBufSize);
		
		if (length == -1)
		{
			myData->failed = YES;
			return;
		}
		
		//
		// Parse the bytes read by sending them through the AudioFileStream
		//
		if (length > 0)
		{
			if (myData->discontinuous)
			{
				OSStatus err = AudioFileStreamParseBytes(myData->audioFileStream, length, bytes, kAudioFileStreamParseFlag_Discontinuity);
				if (err) { PRINTERROR("AudioFileStreamParseBytes"); myData->failed = true;}
			}
			else
			{
				OSStatus err = AudioFileStreamParseBytes(myData->audioFileStream, length, bytes, 0);
				if (err) { PRINTERROR("AudioFileStreamParseBytes"); myData->failed = true; }
			}
		}
	}
}

@implementation AudioStreamer

@synthesize isPlaying = _isPlaying;
@synthesize delegate = _delegate;


- (void)setIsPlaying:(BOOL)status
{
    if (_isPlaying != status)
    {
        _isPlaying = status;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(streamerStatusDidChange)])
        {
            [self.delegate streamerStatusDidChange];
        }
    }
}

//
// initWithURL
//
// Init method for the object.
//
- (id)initWithURL:(NSURL *)newUrl
{
	self = [super init];
	if (self != nil)
	{
		status_number = 0;
		
		url = [newUrl retain];
	}
	return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
    self.delegate = nil;
    
	[url release];
	[super dealloc];
}

//
// startInternal
//
// This is the start method for the AudioStream thread. This thread is created
// because it will be blocked when there are no audio buffers idle (and ready
// to receive audio data).
//
// Activity in this thread:
//	- Creation and cleanup of all AudioFileStream and AudioQueue objects
//	- Receives data from the CFReadStream
//	- AudioFileStream processing
//	- Copying of data from AudioFileStream into audio buffers
//  - Stopping of the thread because of end-of-file
//	- Stopping due to error or failure
//
// Activity *not* in this thread:
//	- AudioQueue playback and notifications (happens in AudioQueue thread)
//  - Actual download of NSURLConnection data (NSURLConnection's thread)
//	- Creation of the AudioStreamer (other, likely "main" thread)
//	- Invocation of -start method (other, likely "main" thread)
//	- User/manual invocation of -stop (other, likely "main" thread)
//
// This method contains bits of the "main" function from Apple's example in
// AudioFileStreamExample.
//
- (void)startInternal
{
	//
	// Retains "self". This means that we can't be deleted while playback is
	// using our buffers. It also means that releasing an AudioStreamer while
	// it is playing won't stop playback. This is a bit weird but, oh well.
	//
	[self retain];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
#ifdef TARGET_OS_IPHONE
	//
	// Set the audio session category so that we continue to play if the
	// iPhone/iPod auto-locks.
	//
	AudioSessionInitialize (
                            NULL,                          // 'NULL' to use the default (main) run loop
                            NULL,                          // 'NULL' to use the default run loop mode
                            MyAudioSessionInterruptionListener,  // a reference to your interruption callback
                            self                       // data to pass to your interruption listener callback
                            );
	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty (
                             kAudioSessionProperty_AudioCategory,
                             sizeof (sessionCategory),
                             &sessionCategory
                             );
	AudioSessionSetActive(true);
#endif
    
	//
	// Attempt to guess the file type from the URL. Reading the MIME type
	// from the CFReadStream would be a better approach since lots of
	// URL's don't have the right extension.
	//
	// If you have a fixed file-type, you may want to hardcode this.
	//
	AudioFileTypeID fileTypeHint = kAudioFileMP3Type;
	NSString *fileExtension = [[url path] lastPathComponent];
	if ([fileExtension isEqualToString:@"mp3"])
	{
		fileTypeHint = kAudioFileMP3Type;
	}
	else if ([fileExtension rangeOfString:@"wav"].location != NSNotFound)
	{
		fileTypeHint = kAudioFileWAVEType;
	}
    else if ([fileExtension rangeOfString:@"aifc"].location != NSNotFound)
	{
		fileTypeHint = kAudioFileAIFCType;
	}
    else if ([fileExtension rangeOfString:@"aiff"].location != NSNotFound)
	{
		fileTypeHint = kAudioFileAIFFType;
	}
    else if ([fileExtension rangeOfString:@"m4a"].location != NSNotFound)
	{
		fileTypeHint = kAudioFileM4AType;
	}
    else if ([fileExtension rangeOfString:@"mp4"].location != NSNotFound)
	{
		fileTypeHint = kAudioFileMPEG4Type;
	}
    else if ([fileExtension rangeOfString:@"caf"].location != NSNotFound)
	{
		fileTypeHint = kAudioFileCAFType;
	}
    else if ([fileExtension rangeOfString:@"aac"].location != NSNotFound)
	{
		fileTypeHint = kAudioFileAAC_ADTSType;
	}
    else if ([fileExtension rangeOfString:@"m3u"].location != NSNotFound)
	{
		fileTypeHint = kAudioFileMP3Type;
	}
    
	// initialize a mutex and condition so that we can block on buffers in use.
	pthread_mutex_init(&mutex, NULL);
	pthread_cond_init(&cond, NULL);
	pthread_mutex_init(&mutex2, NULL);
	
	// create an audio file stream parser
	OSStatus err = AudioFileStreamOpen(self, MyPropertyListenerProc, MyPacketsProc,
                                       fileTypeHint, &audioFileStream);
	if (err) { PRINTERROR("AudioFileStreamOpen"); goto cleanup; }
	
	//
	// Create the GET request
	//
    CFHTTPMessageRef message= CFHTTPMessageCreateRequest(NULL, (CFStringRef)@"GET", (CFURLRef)url, kCFHTTPVersion1_1);
    stream = CFReadStreamCreateForHTTPRequest(NULL, message);
    CFRelease(message);
    if (!CFReadStreamOpen(stream))
	{
        CFRelease(stream);
		goto cleanup;
    }
	
	//
	// Set our callback function to receive the data
	//
	CFStreamClientContext context = {0, self, NULL, NULL, NULL};
	CFReadStreamSetClient(
                          stream,
                          kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered,
                          ReadStreamCallBack,
                          &context);
	CFReadStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
	//
	// Process the run loop until playback is finished or failed.
	//
    
	do
	{
		CFRunLoopRunInMode(
                           kCFRunLoopDefaultMode,
                           2,
                           false);
		
		if (failed)
		{
			[self stop];
            
			if ([[NSInternetDoctor shared] connected])
            {                
                BlockAlertView *alertView = [[BlockAlertView alloc] initWithTitle:NSLocalizedString(@"label_something_wrong", @"")
                                                                          message:NSLocalizedString(@"app_player_error_subtitle", @"")];
                [alertView setCancelButtonWithTitle:NSLocalizedString(@"button_dismiss", @"") block:nil];
                [alertView show];
                
                if (url.absoluteString.length > 0)
                {
                    [TestFlight passCheckpoint:[NSString stringWithFormat:@"%@ - (Εrror)",
                                                [url absoluteString]]];
                }
			}
			else
            {
				[[NSInternetDoctor shared] showNoInternetAlert];
			}
			
			break;
		}
	} while (isPlaying || !finished);
	
cleanup:
    
	//
	// Cleanup the read stream if it is still open
	//
	if (stream)
	{
		CFReadStreamClose(stream);
        CFRelease(stream);
		stream = nil;
	}
	
	//
	// Close the audio file strea,
	//
	err = AudioFileStreamClose(audioFileStream);
	if (err) { PRINTERROR("1 AudioFileStreamClose"); goto cleanup;
	}
	
	//
	// Dispose of the Audio Queue
	//
	if (started)
	{
		err = AudioQueueDispose(audioQueue, true);
		if (err) { PRINTERROR("AudioQueueDispose"); goto cleanup; }
	}
    
	[pool release];
	[self release];
}


//
// start
//
// Calls startInternal in a new thread.
//
- (void)start
{
	[NSThread detachNewThreadSelector:@selector(startInternal) toTarget:self withObject:nil];
}

//
// stop
//
// This method can be called to stop downloading/playback before it completes.
// It is automatically called when an error occurs.
//
// If playback has not started before this method is called, it will toggle the
// "isPlaying" property so that it is guaranteed to transition to true and
// back to false 
//
- (void)stop
{
	if (stream)
	{
		CFReadStreamClose(stream);
        CFRelease(stream);
		stream = nil;
		
		if (finished)
		{
			return;
		}
		
		if (started)
		{
			//
			// Set finished to true *before* we call stop. This is to handle our
			// third thread...
			//	- This method is called from main (UI) thread
			//	- The AudioQueue thread (which owns the AudioQueue buffers nad
			//		will delete them as soon as we call AudioQueueStop)
			//	- URL connection thread is copying data from AudioStream to
			//		AudioQueue buffer
			// We set this flag to tell the URL connection thread to stop
			// copying.
			//
			pthread_mutex_lock(&mutex2);
			finished = true;
            
			OSStatus err = AudioQueueStop(audioQueue, true);
			if (err) { PRINTERROR("AudioQueueStop"); }
			pthread_mutex_unlock(&mutex2);
			
			pthread_mutex_lock(&mutex);
			pthread_cond_signal(&cond);
			pthread_mutex_unlock(&mutex);
		}
		else
		{
			finished = true;
			self.isPlaying = YES;
			self.isPlaying = NO;
		}
	}
}

@end
