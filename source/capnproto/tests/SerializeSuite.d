// Copyright (c) 2013-2014 Sandstorm Development Group, Inc. and contributors
// Licensed under the MIT License:
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

module capnproto.tests.SerializeSuite;

import java.nio.ByteBuffer;

import capnproto;

//SegmentReading
unittest
{
	//When transmitting over a stream, the following should be sent. All integers are unsigned and little-endian.
	//- (4 bytes) The number of segments, minus one (since there is always at least one segment).
	//- (N * 4 bytes) The size of each segment, in words.
	//- (0 or 4 bytes) Padding up to the next word boundary.
	//- The content of each segment, in order.
	
	expectSerializesTo(1, [
	    0, 0, 0, 0, //1 segment.
	    0, 0, 0, 0  //Segment 0 contains 0 bytes.
	    //No padding.
	    //Segment 0 (empty).
	]);
	
	expectSerializesTo(2, [
	    1, 0, 0, 0, //2 segments.
	    0, 0, 0, 0, //Segment 0 contains 0 words.
	    1, 0, 0, 0, //Segment 1 contains 1 words.
	    //Padding.
	    0, 0, 0, 0,
	    //Segment 0 (empty).
	    //Segment 1.
	    1, 0, 0, 0, 0, 0, 0, 0
	]);
	
	expectSerializesTo(3, [
	    2, 0, 0, 0, //3 segments.
	    0, 0, 0, 0, //Segment 0 contains 0 words.
	    1, 0, 0, 0, //Segment 1 contains 1 words.
	    2, 0, 0, 0, //Segment 2 contains 2 words.
	    //No padding.
	    //Segment 0 (empty).
	    //Segment 1.
	    1, 0, 0, 0, 0, 0, 0, 0,
	    //Segment 2.
	    2, 0, 0, 0, 0, 0, 0, 0,
	    2, 0, 0, 0, 0, 0, 0, 0
	]);
	
	expectSerializesTo(4, [
	    3, 0, 0, 0, //4 segments.
	    0, 0, 0, 0, //Segment 0 contains 0 words.
	    1, 0, 0, 0, //Segment 1 contains 1 words.
	    2, 0, 0, 0, //Segment 2 contains 2 words.
	    3, 0, 0, 0, //Segment 3 contains 3 words.
	    //Padding.
	    0, 0, 0, 0,
	    //Segment 0 (empty).
	    //Segment 1.
	    1, 0, 0, 0, 0, 0, 0, 0,
	    //Segment 2.
	    2, 0, 0, 0, 0, 0, 0, 0,
	    2, 0, 0, 0, 0, 0, 0, 0,
	    //Segment 3.
	    3, 0, 0, 0, 0, 0, 0, 0,
	    3, 0, 0, 0, 0, 0, 0, 0,
	    3, 0, 0, 0, 0, 0, 0, 0
	]);
}

/**
 * \param exampleSegmentCount number of segments.
 * \param exampleBytes byte array containing `segmentCount` segments; segment `i` contains `i` words each set to `i`.
 */
void expectSerializesTo(int exampleSegmentCount, ubyte[] exampleBytes)
{
	void checkSegmentContents(ReaderArena arena)
	{
		assert(arena.segments.data.length == exampleSegmentCount);
		foreach(i; 0..exampleSegmentCount)
		{
			auto segment = arena.segments.data[i];
			auto segmentWords = segment.buffer.asLongBuffer();
			
			assert(segmentWords.capacity/8 == i);
			segmentWords.rewind();
			while(segmentWords.hasRemaining)
				assert(segmentWords.getLong() == i);
		}
	}
	
	
	// ----
	// read via ReadableByteChannel
	{
		auto messageReader = Serialize.read(new ArrayInputStream(exampleBytes));
		checkSegmentContents(messageReader.arena);
	}
	
	// ------
	// read via ByteBuffer
	{
		auto wrapped = ByteBuffer.wrap(exampleBytes);
		auto messageReader = Serialize.read(wrapped);
		checkSegmentContents(messageReader.arena);
	}
}
