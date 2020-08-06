#pragma once
#include "constants.h"
#include <cstdio>
#include <vector>
#include <memory>

/**	StepEvent class provides an individual step event .
*	The event may be part of a song, pattern or sequence. Events do not have MIDI channel which is applied by the function to play the event, e.g. pattern player assigned to specific channel. Events have the concept of position which is an offset from some epoch measured in MIDI steps. The epoch depends on the function using the event, e.g. pattern player may use start of pattern as epoch (position = 0). There is a starting and end value to allow interpolation of MIDI events between the start and end positions.
*/
class StepEvent
{
	public:
		/**	Default constructor of StepEvent object
		*/
		StepEvent()
		{
			m_nPosition = 0;
			m_nDuration = 1;
			m_nCommand = MIDI_NOTE_ON;
			m_nValue1start = 60;
			m_nValue2start = 100;
			m_nValue1end = 60;
			m_nValue2end = 0;
		};

		/**	Constructor - create an instance of StepEvent object
		*/
		StepEvent(uint32_t position, uint8_t command, uint8_t value1 = 0, uint8_t value2 = 0, uint32_t duration = 1)
		{
			m_nPosition = position;
			m_nDuration = duration;
			m_nCommand = command;
			m_nValue1start = value1;
			m_nValue2start = value2;
			m_nValue1end = value1;
			if(command == MIDI_NOTE_ON)
				m_nValue2end = 0;
			else
				m_nValue2end = value2;
		};
		/**	Copy constructor - create an copy of StepEvent object from an existing object
		*/
		StepEvent(StepEvent* pEvent)
		{
			m_nPosition = pEvent->getPosition();
			m_nDuration = pEvent->getDuration();
			m_nCommand = pEvent->getCommand();
			m_nValue1start = pEvent->getValue1start();
			m_nValue2start = pEvent->getValue2start();
			m_nValue1end = pEvent->getValue1end();
			m_nValue2end = pEvent->getValue2end();
		};
		uint8_t getPosition() { return m_nPosition; };
		uint8_t getDuration() { return m_nDuration; };
		uint8_t getCommand() { return m_nCommand; };
		uint8_t getValue1start() { return m_nValue1start; };
		uint8_t getValue2start() { return m_nValue2start; };
		uint8_t getValue1end() { return m_nValue1end; };
		uint8_t getValue2end() { return m_nValue2end; };
		void setPosition(uint32_t position) { m_nPosition = position; };
		void setDuration(uint32_t duration) { m_nDuration = duration; };
		void setValue1start(uint8_t value) { m_nValue1start = value; };
		void setValue2start(uint8_t value) { m_nValue2start = value; };
		void setValue1end(uint8_t value) { m_nValue1end = value; };
		void setValue2end(uint8_t value) { m_nValue2end = value; };
	private:
		uint32_t m_nPosition; // Start position of event in steps
		uint32_t m_nDuration; // Duration of event
		uint8_t m_nCommand; // MIDI command without channel
		uint8_t m_nValue1start; // MIDI value 1 at start of event
		uint8_t m_nValue2start; // MIDI value 2 at start of event
		uint8_t m_nValue1end; // MIDI value 1 at end of event
		uint8_t m_nValue2end; // MIDI value 2 at end of event
		uint32_t m_nProgress; // Progress through event (start value to end value)
};

/**	Pattern class provides a group of MIDI events within period of time
*/
class Pattern
{
	public:
		/**	@brief	Construct pattern object
		*	@param	steps Quantity of steps in pattern
		*	@param	clkPerStep Quantity of clock cycles per step
		*/
		Pattern(uint32_t steps = 16, uint8_t divisor = 6) :
			m_nDivisor(divisor),
			m_nLength(steps * divisor)
		{
		}

		~Pattern();

		/**	@brief	Add step event to pattern
		*	@param	position Quantity of steps from start of pattern
		*	@param	command MIDI command
		*	@param	value1 MIDI value 1
		*	@param	value2 MIDI value 2
		*	@param	duration Event duration in steps cycles
		*/
		StepEvent* addEvent(uint32_t position, uint8_t command, uint8_t value1 = 0, uint8_t value2 = 0, uint32_t duration = 1);

		/**	@breif	Add event from existing event
		*	@param	pEvent Pointer to event to copy
		*	@retval	StepEvent* Pointer to new event
		*/
		StepEvent* addEvent(StepEvent* pEvent);

		/**	@brief	Add note to pattern
		*	@param	step Quantity of steps from start of pattern at which to add note
		*	@param	note MIDI note number
		*	@param	velocity MIDI velocity
		*	@param	duration Duration of note in steps
		*/
		void addNote(uint32_t step, uint8_t note, uint8_t velocity, uint32_t duration = 1);

		/**	@brief	Remove note from pattern
		*	@param	position Quantity of steps from start of pattern at which to remove note
		*	@param	note MIDI note number
		*/
		void removeNote(uint32_t step, uint8_t note);

		/**	@brief	Get velocity of note
		*	@param	position Quantity of steps from start of pattern at which note starts
		*	@param	note MIDI note number
		*	@retval	uint8_t MIDI velocity of note
		*/
		uint8_t getNoteVelocity(uint32_t step, uint8_t note);

		/**	@brief	Set velocity of note
		*	@param	position Quantity of steps from start of pattern at which note starts
		*	@param	note MIDI note number
		*	@param	velocity MIDI velocity
		*/
		void setNoteVelocity(uint32_t step, uint8_t note, uint8_t velocity);

		/**	@brief	Get duration of note
		*	@param	position Quantity of steps from start of pattern at which note starts
		*	@param	note MIDI note number
		*	@retval	uint32_t Duration of note or 0 if note does not exist
		*/
		uint8_t getNoteDuration(uint32_t step, uint8_t note);

		/**	@brief	Add continuous controller to pattern
		*	@param	position Quantity of steps from start of pattern at which control starts
		*	@param	control MIDI controller number
		*	@param	valueStart Controller value at start of event
		*	@param	valueEnd Controller value at end of event
		*	@param	duration Duration of event in steps
		*/
		void addControl(uint32_t step, uint8_t control, uint8_t valueStart, uint8_t valueEnd, uint32_t duration = 1);

		/**	@brief	Get duration of controller event
		*	@param	position Quantity of steps from start of pattern at which control starts
		*	@param	control MIDI controller number
		*/
		void getControlDuration(uint32_t step, uint8_t control);

		/**	@brief	Remove continuous controller from pattern
		*	@param	position Quantity of steps from start of pattern at which control starts
		*	@param	control MIDI controller number
		*/
		void removeControl(uint32_t step, uint8_t control);

		/**	@brief	Set quantity of steps in pattern
		*	@param	steps Pattern length in steps
		*/
		void setSteps(uint32_t steps);

		/**	@brief	Get quantity of steps in pattern
		*	@retval	uint32_t Quantity of steps
		*/
		uint32_t getSteps() { return m_nLength; };

		/**	@brief	Get length of pattern in steps
		*	@retval uint32_t Length of pattern in steps
		*/
		uint32_t getLength() { return m_nLength * m_nDivisor; };

		/**	@brief	Set quantity of clocks per step
		*	@param	value Quantity of clock cycles per step
		*/
		void setClockDivisor(uint32_t value);

		/**	@brief	Get quantity of clocks per step
		*	@retval	uint32_t Quantity of clocks per step
		*/
		uint32_t getClockDivisor() { return m_nDivisor; };

		/**	@brief	Set quantity of steps per beat (grid line separation)
		*	@param	value Quantity of steps per beat
		*/
		void setStepsPerBeat(uint32_t value);

		/**	@brief	Get quantity of steps per beat
		*	@retval	uint32_t Quantity of steps per beat
		*/
		uint32_t getStepsPerBeat() { return m_nStepsPerBeat; };


		/**	@brief	Transpose all notes within pattern
		*	@param	value Offset to transpose
		*/
		void transpose(int value);

		/**	@brief	Clear all events from pattern
		*/
		void clear();
		
		/**	@brief	Get event at given index
		*	@param	index Index of event
		*	@retval	StepEvent* Pointer to event or null if event does not existing
		*/
		StepEvent* getEventAt(uint32_t index);

	private:
		void deleteEvent(uint32_t position, uint8_t command, uint8_t value1);

		std::vector<StepEvent> m_vEvents; // Vector of pattern events
		uint32_t m_nLength; // Quantity of steps in pattern
		uint32_t m_nDivisor; // Clock cycles per step
		uint32_t m_nStepsPerBeat; // Steps per beat
};
