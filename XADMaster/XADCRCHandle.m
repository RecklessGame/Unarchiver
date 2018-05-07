#import "XADCRCHandle.h"

@implementation XADCRCHandle

+(XADCRCHandle *)IEEECRC32HandleWithHandle:(CSHandle *)handle
correctCRC:(uint32_t)correctcrc conditioned:(BOOL)conditioned
{
    if(conditioned) return [[self alloc] initWithHandle:handle length:CSHandleMaxLength initialCRC:0xffffffff
                                             correctCRC:correctcrc^0xffffffff CRCTable:XADCRCTable_edb88320];
    else return [[self alloc] initWithHandle:handle length:CSHandleMaxLength initialCRC:0
                                  correctCRC:correctcrc CRCTable:XADCRCTable_edb88320];
}

+(XADCRCHandle *)IEEECRC32HandleWithHandle:(CSHandle *)handle length:(off_t)length
                                correctCRC:(uint32_t)correctcrc conditioned:(BOOL)conditioned
{
    if(conditioned) return [[self alloc] initWithHandle:handle length:length initialCRC:0xffffffff
                                             correctCRC:correctcrc^0xffffffff CRCTable:XADCRCTable_edb88320];
    else return [[self alloc] initWithHandle:handle length:length initialCRC:0
                                  correctCRC:correctcrc CRCTable:XADCRCTable_edb88320];
}

+(XADCRCHandle *)IBMCRC16HandleWithHandle:(CSHandle *)handle length:(off_t)length
correctCRC:(uint32_t)correctcrc conditioned:(BOOL)conditioned
{
    if(conditioned) return [[self alloc] initWithHandle:handle length:length initialCRC:0xffff
                                             correctCRC:correctcrc^0xffff CRCTable:XADCRCTable_a001];
    else return [[self alloc] initWithHandle:handle length:length initialCRC:0
                                  correctCRC:correctcrc CRCTable:XADCRCTable_a001];
}

+(XADCRCHandle *)CCITTCRC16HandleWithHandle:(CSHandle *)handle length:(off_t)length
correctCRC:(uint32_t)correctcrc conditioned:(BOOL)conditioned
{
    if(conditioned) return [[self alloc] initWithHandle:handle length:length initialCRC:0xffff
                                             correctCRC:XADUnReverseCRC16(correctcrc)^0xffff CRCTable:XADCRCReverseTable_1021];
    else return [[self alloc] initWithHandle:handle length:length initialCRC:0
                                  correctCRC:XADUnReverseCRC16(correctcrc) CRCTable:XADCRCReverseTable_1021];
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length initialCRC:(uint32_t)initialcrc
         correctCRC:(uint32_t)correctcrc CRCTable:(const uint32_t *)crctable
{
	if((self=[super initWithName:[handle name] length:length]))
	{
		parent=handle;
		crc=initcrc=initialcrc;
		compcrc=correctcrc;
		table=crctable;
		transformationfunction=NULL;
		transformationcontext=NULL;
	}
	return self;
}

-(void)dealloc
{
    parent = nil;
	
}

-(void)setCRCTransformationFunction:(XADCRCTransformationFunction *)function context:(void *)context
{
	transformationfunction=function;
	transformationcontext=context;
}

-(void)resetStream
{
	[parent seekToFileOffset:0];
	crc=initcrc;
}

-(int)streamAtMost:(int)num toBuffer:(void *)buffer
{
	int actual=[parent readAtMost:num toBuffer:buffer];
	crc=XADCalculateCRC(crc,buffer,actual,table);
	return actual;
}

-(BOOL)hasChecksum { return YES; }

-(BOOL)isChecksumCorrect
{
	if([parent hasChecksum]&&![parent isChecksumCorrect]) return NO;

	if(transformationfunction)
	{
		uint32_t actualcrc=transformationfunction(crc,transformationcontext);
		return actualcrc==compcrc;
	}
	else
	{
		return crc==compcrc;
	}
}

-(double)estimatedProgress { return [parent estimatedProgress]; }

@end

