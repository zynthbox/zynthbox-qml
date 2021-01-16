/** Implementation of standard MIDI file class
*/

#include "smf.h"

#include <stdio.h> //provides printf
#include <cstring> //provides strcmp, memset

#define DPRINTF(fmt, args...) if(m_bDebug) printf(fmt, ## args)

Smf::Smf()
{

}

Smf::~Smf()
{
	unload();
}

void Smf::enableDebug(bool bEnable)
{
    m_bDebug = bEnable;
}

// Private file management functions

int Smf::fileWrite8(uint8_t value, FILE *pFile)
{
	int nResult = fwrite(&value, 1, 1, pFile);
	return nResult;
}

uint8_t Smf::fileRead8(FILE* pFile)
{
	uint8_t nResult = 0;
	fread(&nResult, 1, 1, pFile);
	return nResult;
}

int Smf::fileWrite16(uint16_t value, FILE *pFile)
{
	for(int i = 1; i >=0; --i)
		fileWrite8((value >> i * 8), pFile);
	return 2;
}

uint16_t Smf::fileRead16(FILE* pFile)
{
	uint16_t nResult = 0;
	for(int i = 1; i >=0; --i)
	{
		uint8_t nValue;
		fread(&nValue, 1, 1, pFile);
		nResult |= nValue << (i * 8);
	}
	return nResult;
}

int Smf::fileWrite32(uint32_t value, FILE *pFile)
{
	for(int i = 3; i >=0; --i)
		fileWrite8((value >> i * 8), pFile);
	return 4;
}

uint32_t Smf::fileRead32(FILE* pFile)
{
	uint32_t nResult = 0;
	for(int i = 3; i >=0; --i)
	{
		uint8_t nValue;
		fread(&nValue, 1, 1, pFile);
		nResult |= nValue << (i * 8);
	}
	return nResult;
}

uint32_t Smf::fileReadVar(FILE* pFile)
{
	uint32_t nValue = 0;
	for(int i = 0; i < 4; ++i)
	{
		uint8_t nByte = fileRead8(pFile);
		nValue <<= 7;
		nValue |= (nByte & 0x7F);
		if((nByte & 0x80) == 0)
			break;
	}
	return nValue;
}

size_t Smf::fileReadString(FILE *pFile, char* pString, size_t nSize)
{
	size_t nRead = fread(pString, 1, nSize, pFile);
	pString[nRead] = '\0';
	return nRead;
}

bool Smf::load(char* sFilename, bool bLoadEvents)
{
	unload();

	FILE *pFile;
	pFile = fopen(sFilename, "r");
	if(pFile == NULL)
	{
        DPRINTF("Failed to open file '%s'\n", sFilename);
		return false;
	}
	char sHeader[4];
	
    uint16_t nDivision = 0;
	uint8_t nTrack = 0;
	// Iterate each block within IFF file
	while(fread(sHeader, 4, 1, pFile) == 1)
	{
		uint32_t nPosition = 0;
		uint32_t nBlockSize = fileRead32(pFile);
		if(memcmp(sHeader, "MThd", 4) == 0)
		{
			// SMF file header
			DPRINTF("Found MThd block of size %u\n", nBlockSize);
            m_nFormat = fileRead16(pFile);
            m_nTracks = fileRead16(pFile);
            nDivision = fileRead16(pFile);
			m_bTimecodeBased = ((nDivision & 0x8000) == 0x8000);
			if(m_bTimecodeBased)
			{
				m_nSmpteFps = -(int8_t(nDivision & 0xFF00) >> 8);
				m_nSmpteResolution = nDivision & 0x00FF;
				DPRINTF("Standard MIDI File - Format: %u, Tracks: %u, SMPTE fps: %u, SMPTE subframe resolution: %u\n", m_nFormat, m_nTracks, m_nSmpteFps, m_nSmpteResolution);
			}
			else
			{
				m_nTicksPerQuarterNote = nDivision & 0x7FFF;
				DPRINTF("Standard MIDI File - Format: %u, Tracks: %u, Ticks per quarter note: %u\n", m_nFormat, m_nTracks, m_nTicksPerQuarterNote);
			}
			DPRINTF("\n");
		}
		else if(memcmp(sHeader, "MTrk", 4) == 0)
		{
			// SMF track header
			DPRINTF("Found MTrk block of size %u\n", nBlockSize);
			Track* pTrack = new Track();
			m_vTracks.push_back(pTrack);
			uint8_t nRunningStatus = 0;
			long nEnd = ftell(pFile) + nBlockSize;
			while(ftell(pFile) < nEnd)
			{
				uint32_t nDelta = fileReadVar(pFile);
				nPosition += nDelta;
				uint8_t nStatus = fileRead8(pFile);
				DPRINTF("Abs: %u Delta: %u ", nPosition, nDelta);
				if((nStatus & 0x80) == 0)
				{
					nStatus = nRunningStatus;
					fseek(pFile, -1, SEEK_CUR);
				}
				uint32_t nMessageLength;
				uint8_t nMetaType;
				uint8_t nChannel;
				uint8_t* pData;
				Event* pEvent = NULL;
				switch(nStatus)
				{
					case 0xFF:
						// Meta event
						nMetaType = fileRead8(pFile);
						nMessageLength = fileReadVar(pFile);
						pData = new uint8_t[nMessageLength + 1];
						fread(pData, nMessageLength, 1, pFile);
						pEvent = new Event(nPosition, EVENT_TYPE_META, nMetaType, nMessageLength, pData);
						if(bLoadEvents)
							pTrack->addEvent(pEvent);
						if(nMetaType == 0x51) // Tempo
							m_nMicrosecondsPerQuarterNote = pEvent->getInt32();
						else if(nMetaType == 0x7F) // Manufacturer
							m_nManufacturerId = pEvent->getInt32();
						nRunningStatus = 0;
						break;
					case 0xF0:
						// SysEx event
						//!@todo Store SysEx messages
						nMessageLength = fileReadVar(pFile);
						DPRINTF("SysEx %u bytes\n", nMessageLength);
						if(nMessageLength > 0)
						{
							fseek(pFile, nMessageLength - 1, SEEK_CUR);
							if (fileRead8(pFile) == 0xF7)
								nRunningStatus = 0xF0;
							else
								nRunningStatus = 0;
						}
						else
							nRunningStatus = 0;
						break;
					case 0xF7:
						// End of SysEx or Escape sequence
						nMessageLength = fileReadVar(pFile);
						if(nRunningStatus == 0xF0)
						{
							DPRINTF("SysEx continuation %u bytes\n", nMessageLength);
							if(nMessageLength > 0)
							{
								fseek(pFile, nMessageLength - 1, SEEK_CUR);
								if(fileRead8(pFile) == 0xF7)
									nRunningStatus = 0;
							}
							else
								nRunningStatus = 0;
						}
						else
						{
							DPRINTF("Escape sequence %u bytes\n", nMessageLength);
							pData = new uint8_t[nMessageLength];
							fread(pData, nMessageLength, 1, pFile);
							pEvent = new Event(nPosition, EVENT_TYPE_ESCAPE, 0, nMessageLength, pData);
							if(bLoadEvents)
								pTrack->addEvent(pEvent);
							nRunningStatus = 0;
						}
						break;
					default:
						// MIDI event
						nChannel = nStatus & 0x0F;
						nStatus = nStatus & 0xF0;
						nRunningStatus = nStatus;
						switch(nStatus)
						{
							case 0x80: // Note Off
							case 0x90: // Note On
							case 0xA0: // Polyphonic Pressure
							case 0xB0: // Control Change
							case 0xE0: // Pitchbend
								// MIDI commands with 2 parameters
								pData = new uint8_t[2];
								fread(pData, 1, 2, pFile);
								pEvent = new Event(nPosition, EVENT_TYPE_MIDI, nStatus, 2, pData);
								if(bLoadEvents)
									pTrack->addEvent(pEvent);
								break;
							case 0xC0: // Program Change
							case 0xD0: // Channel Pressure
								pData = new uint8_t;
								fread(pData, 1, 1, pFile);
								pEvent = new Event(nPosition, EVENT_TYPE_MIDI, nStatus, 1, pData);
								if(bLoadEvents)
									pTrack->addEvent(pEvent);
								break;
							default:
								DPRINTF("Unexpected MIDI event 0x%02X\n", nStatus);
								nRunningStatus = 0;
						}
				}
			}
		}
		else
		{
			// Ignore unknown block
			DPRINTF("Found unsupported %c%c%c%c block of size %u\n", sHeader[0], sHeader[1], sHeader[2], sHeader[3], nBlockSize);
			fseek(pFile, nBlockSize, SEEK_CUR);
		}
		if(nPosition > m_nDurationInTicks)
			m_nDurationInTicks = nPosition;
	}

	fclose(pFile);
	if(!m_bTimecodeBased)
	{
		uint32_t nSeconds = m_nDurationInTicks / m_nTicksPerQuarterNote * m_nMicrosecondsPerQuarterNote  / 1000000;
		uint32_t nMinutes = (nSeconds / 60) % 60;
		uint32_t nHours = nSeconds / 3600;
		DPRINTF("Duration: %u ticks, %u quater notes, %u:%02u:%02u (assuming constant tempo)\n",  m_nDurationInTicks, m_nDurationInTicks / m_nTicksPerQuarterNote, nHours, nMinutes, nSeconds % 60);
		DPRINTF("m_nDurationInTicks: %u, m_nTicksPerQuarterNote: %u, m_nMicrosecondsPerQuarterNote: %u, nSeconds: %u, getDuration():%f\n", m_nDurationInTicks, m_nTicksPerQuarterNote, m_nMicrosecondsPerQuarterNote, nSeconds, getDuration());
	}

	setPosition(0);

	return true; //!@todo Return duration of longest track
}

void Smf::unload()
{
	for(auto it = m_vTracks.begin(); it != m_vTracks.end(); ++it)
	{
		delete (*it);
	}
	m_vTracks.clear();
	m_bTimecodeBased = false;
	m_nFormat = 0;
	m_nTracks = 0;
	m_nSmpteFps = 0;
	m_nSmpteResolution = 0;
	m_nTicksPerQuarterNote = 96;
	m_nManufacturerId = 0;
	m_nDurationInTicks = 0;
	m_nMicrosecondsPerQuarterNote = 500000;
}

double Smf::getDuration()
{
	return double(m_nDurationInTicks) * m_nMicrosecondsPerQuarterNote / m_nTicksPerQuarterNote / 1000000.0;
}

Event* Smf::getNextEvent(bool bAdvance)
{
	size_t nPosition = -1;
	size_t nNextTrack;
	for(size_t nTrack = 0; nTrack < m_vTracks.size(); ++nTrack)
	{
		// Iterate through tracks and find earilest next event
		Event* pEvent = m_vTracks[nTrack]->getNextEvent(false);
		if(pEvent && pEvent->getTime() < nPosition)
		{
			nPosition = pEvent->getTime();
			nNextTrack = nTrack;
		}
	}
	if(nPosition == -1)
		return NULL;
	if(bAdvance)
		m_nPosition = nPosition;
	return m_vTracks[nNextTrack]->getNextEvent(bAdvance);
}

void Smf::setPosition(size_t nTime)
{
	for(auto it = m_vTracks.begin(); it!= m_vTracks.end(); ++it)
		(*it)->setPosition(nTime);
	m_nPosition = nTime;
}

size_t Smf::getTracks()
{
	return m_vTracks.size();
}

uint8_t Smf::getFormat()
{
	return m_nFormat;
}