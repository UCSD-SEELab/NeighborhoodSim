classdef HomeSimEvent < handle
    %HOMESIMEVENT A simple event class with time and callback handle.
    
    properties ( Access = 'private' )
        % Function to be invoked as the event.
        functionHandle;
    end
    properties ( SetAccess = 'private' )
        % Time of the event to take place.
        eventTime;
    end
    
    methods
        % HOMESIMEVENT(event) Creates a new event from a previous one.
        % HOMESIMEVENT(function,time) Creates a new event from a function
        % and a time.
        function this = HomeSimEvent( input1, input2 )
            if nargin == 1
                this.functionHandle = input1.functionHandle;
                this.eventTime = input1.eventTime;
            elseif nargin == 2
                this.functionHandle = input1;
                this.eventTime = input2;
            end
        end
        
        % RUN Runs the event.
        function Run( this )
            this.functionHandle();
        end
        
        % GETEVENTTIME Returns the event time.
        function eventTime = GetEventTime( this )
            eventTime = this.eventTime;
        end
        
        % LT Overload for the < operator.
        function result = lt( this, rhs )
            result = this.eventTime < rhs.eventTime;
        end
        
        % GT Overload for the > operator.
        function result = gt( this, rhs )
            result = this.eventTime > rhs.eventTime;
        end
        
        % EQ Overload for the == operator.
        function result = eq( this, rhs )
            result = ( this.eventTime == rhs.eventTime ) && ( this.functionHandle == rhs.functionHandle );
        end
        
        % LE Overload for the <= operator.
        function result = le( this, rhs )
            result = this.eventTime <= rhs.eventTime;
        end
        
        % GE Overload for the >= operator.
        function result = ge( this, rhs )
            result = this.eventTime >= rhs.eventTime;
        end
        
        % NE Overload for the ~= operator.
        function result = ne( this, rhs )
            result = this.eventTime ~= rhs.eventTime;
        end
        
        % Overload for the sort function. Sorts events in time.
        function [sortedEvents,sortedIndices] = sort( eventArray )
            [~, sortedIndices] = sort( [eventArray.eventTime] );
            sortedEvents = eventArray( sortedIndices );
        end
        
        % Overload for the min function. Finds the earliest event.
        function [minimumEvent, minimumIndex] = min( eventArray )
            [~, minimumIndex] = min( [eventArray.eventTime] );
            minimumEvent = HomeSimEvent( eventArray( minimumIndex ) );
        end
    end
    
end

