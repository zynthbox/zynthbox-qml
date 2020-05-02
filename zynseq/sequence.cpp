/**	Sequence class methods implementation **/

#include "sequence.h"

Sequence::Sequence()
{
	setClockRate(120, 44100); // Default BPM and samplerate - expect host to call setClockRate to correct this
}

Sequence::~Sequence()
{
}

void Sequence::addPattern(uint32_t position, Pattern* pattern)
{
	// Find and remove overlapping patterns
	uint32_t nStart = position;
	uint32_t nEnd = nStart + pattern->getLength();
	for(uint32_t nClock = 0; nClock <= position + pattern->getLength(); ++nClock)
	{
		if(m_mPatterns.find(nClock) != m_mPatterns.end())
		{
			Pattern* pPattern = m_mPatterns[nClock];
			uint32_t nExistingStart = nClock;
			uint32_t nExistingEnd = nExistingStart + pPattern->getLength();

			if((nStart >= nExistingStart && nStart < nExistingEnd) || (nEnd > nExistingStart && nEnd <= nExistingEnd))
			{
				// Found overlapping pattern so remove from sequence but don't delete (that is responsibility of PatternManager)
				m_mPatterns.erase(nClock);
			}
		}
	}
	m_mPatterns[position] = pattern;
	if(m_nSequenceLength < position + pattern->getLength())
		m_nSequenceLength = position + pattern->getLength();
}

void Sequence::removePattern(uint32_t position)
{
	m_mPatterns.erase(position);
	updateLength();
}

Pattern* Sequence::getPattern(uint32_t position)
{
	auto it = m_mPatterns.find(position);
	if(it == m_mPatterns.end())
		return NULL;
	return it->second;
}

Pattern* Sequence::getPatternAt(uint32_t index)
{
	if(m_mPatterns.size() >= index)
		return NULL;
	return m_mPatterns[index];
}

uint8_t Sequence::getChannel()
{
	return m_nChannel;
}

void Sequence::setChannel(uint8_t channel)
{
	if(channel > 15)
		return;
	m_nChannel = channel;
}

uint8_t Sequence::getOutput()
{
	return m_nOutput;
}

void Sequence::setOutput(uint8_t output)
{
	m_nOutput = output;
}

uint8_t Sequence::getPlayMode()
{
	return m_nState;
}

void Sequence::setPlayMode(uint8_t mode)
{
	if(mode > 2)
		return;
	if(mode == PLAY || mode == LOOP)
		m_nPosition = 0;
	m_nState = mode;
}

void Sequence::togglePlayMode()
{
	if(m_nState == STOP)
		setPlayMode(PLAY);
	else
		setPlayMode(STOP);
}

bool Sequence::clock(uint32_t nTime)
{
	// Clock cycle - update position and associated counters, status, etc.
	if(m_nState == STOP || ++m_nDivCount < m_nDivisor)
		return false;
	//printf("Sequence::clock %d/%d/%d/%d/%d\n", m_nState, m_nPosition, m_nDivCount, m_nDivisor, nTime);
	m_nCurrentTime = nTime;
	m_nDivCount = 0;
	if(m_nPosition >= m_nSequenceLength)
	{
		m_nPosition = 0;
		if(m_nState != LOOP)
		{
			m_nState = STOP;
			return false;
		}
	}
	if(m_mPatterns.find(m_nPosition) != m_mPatterns.end())
	{
		// Play head at start of pattern
		m_nCurrentPattern = m_nPosition;
		m_nPatternCursor = 0;
		m_nNextEvent = 0;
		m_nDivisor = m_mPatterns[m_nCurrentPattern]->getDivisor();
		m_nDivCount = 0;
		m_nEventValue = -1;
	}
	else if(m_nCurrentPattern >= 0 && m_nPatternCursor >= m_mPatterns[m_nCurrentPattern]->getLength())
	{
		// Beyond pattern but not at start of another
		m_nCurrentPattern = -1;
		m_nNextEvent = -1;
		m_nPatternCursor = 0;
		m_nDivisor = 1;
		m_nDivCount = 0;
	}
	else
	{
		// Within a pattern
		m_nPatternCursor += m_nDivisor;
	}
	m_nPosition += m_nDivisor;
	return true;
}

SEQ_EVENT* Sequence::getEvent()
{
	// This function is called repeatedly for each clock period until no more events are available to populate JACK MIDI output schedule
	static SEQ_EVENT seqEvent; // A MIDI event timestamped for some imminent or future time
	if(m_nState == STOP || m_nCurrentPattern < 0 || m_nNextEvent < 0)
		return NULL;
	// Sequence is being played and playhead is within a pattern
	Pattern* pPattern = m_mPatterns[m_nCurrentPattern];
	StepEvent* pEvent = pPattern->getEventAt(m_nNextEvent); // Don't advance event here because need to interpolate
	if(pEvent && pEvent->getPosition() == m_nPatternCursor)
	{
		if(m_nEventValue == pEvent->getValue2end())
		{
			// We have reached the end of interpolation so move on to next event
			m_nEventValue = -1;
			pEvent = pPattern->getEventAt(++m_nNextEvent);
			if(!pEvent || pEvent->getPosition() != m_nPatternCursor)
			{
				return NULL;
			}
		}
		if(m_nEventValue == -1)
		{
			// Have not yet started to interpolate value
			m_nEventValue = pEvent->getValue2start();
			seqEvent.time = m_nCurrentTime;
		}
		else if(pEvent->getValue2start() == m_nEventValue)
		{
			// Already processed start value
			m_nEventValue = pEvent->getValue2end(); //!@todo Currently just move straight to end value but should interpolate for CC
			seqEvent.time = m_nCurrentTime + (pEvent->getDuration() - 1) * m_nSamplePerClock;
		}
	}
	else
	{
		m_nEventValue = -1;
		return NULL;
	}
	seqEvent.msg.command = pEvent->getCommand() | m_nChannel;
	seqEvent.msg.value1 = pEvent->getValue1start();
	seqEvent.msg.value2 = m_nEventValue;
	return &seqEvent;
}

void Sequence::updateLength()
{
	m_nSequenceLength = 0;
	for(auto it = m_mPatterns.begin(); it != m_mPatterns.end(); ++it)
		if(it->first + it->second->getLength() > m_nSequenceLength)
			m_nSequenceLength = it->first + it->second->getLength();
}

uint32_t Sequence::getLength()
{
	return m_nSequenceLength;
}

void Sequence::clear()
{
	m_mPatterns.clear();
	m_nSequenceLength = 0;
	m_nPatternCursor = 0;
	m_nEventValue = -1;
	m_nNextEvent = -1;
	m_nCurrentPattern = -1;
	m_nPosition = 0;
	m_nDivisor = 1;
	m_nDivCount = 0;
}

uint32_t Sequence::getStep()
{
	return m_nPatternCursor / m_nDivisor;
}

uint32_t Sequence::getPatternPlayhead()
{
	return m_nPatternCursor;
}

uint32_t Sequence::getPlayPosition()
{
	return m_nPosition;
}

void Sequence::setClockRate(uint32_t tempo, uint32_t samplerate)
{
	m_nSamplePerClock = samplerate * 60 / (tempo * 24);
}