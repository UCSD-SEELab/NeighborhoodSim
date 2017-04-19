classdef HomeSimEventScheduler < handle
    %HOMESIMEVENTSCHEDULER Global event scheduler.
    %   The class stores all events and executes them in ordered fashion.
    
    properties ( Access = 'private' )
        % Current simulation time.
        currentTime = 0;
        
        % List of stored events.
        scheduledEvents;
    end
    
    methods ( Access = 'private' )
        % RUNCURRENTEVENT Runs the next event in the list.
        function RunCurrentEvent( this )
            [currentEvent, currentEventIndex] = min( this.scheduledEvents );
            this.scheduledEvents( currentEventIndex ) = [];
            this.currentTime = currentEvent.GetEventTime();
            currentEvent.Run();
        end
        
        % ISEVENTLISTEMPTY Checks whether the list is empty.
        function result = IsEventListEmpty( this )
            result = isempty( this.scheduledEvents );
        end
        
        % HOMESIMEVENTSCHEDULER Empty constructor.
        function this = HomeSimEventScheduler()
        end
    end
    
    methods ( Static )
        % GETSCHEDULER Static method to obtain the only instance of the
        % event scheduler.
        function schedulerHandle = GetScheduler()
            persistent mainHomeSimScheduler;
            if isempty( mainHomeSimScheduler ) || ~isvalid( mainHomeSimScheduler )
               mainHomeSimScheduler = HomeSimEventScheduler();
            end
            schedulerHandle = mainHomeSimScheduler;
        end
    end
    
    methods
        % RESETSCHEDULER Deletes all events and resets time.
        function ResetScheduler( this )
            this.currentTime = 0;
            delete( this.scheduledEvents );
            this.scheduledEvents = [];
        end
        
        % SCHEDULEEVENT Schedules the event provided.
        function ScheduleEvent( this, eventObject )
            if eventObject.GetEventTime() < this.currentTime
                error( 'Scheduling event in the past' );
            end
            this.scheduledEvents = [this.scheduledEvents, HomeSimEvent( eventObject )];
        end
        
        % SCHEDULEEVENTAFTER Schedules an event relative to the current
        % time.
        function eventObject = ScheduleEventAfter( this, functionHandle, relativeTime )
            if relativeTime < 0
                error( 'Scheduling event in the past' );
            end
            scheduleTime = relativeTime + this.currentTime;
            eventObject = HomeSimEvent( functionHandle, scheduleTime );
            this.ScheduleEvent( eventObject );
        end
        
        % RUNSIMULATION Starts executing the events until the given time.
        function RunSimulation( this, endTime )
            if nargin == 1
                endTime = 365 * 24 * 60 * 60;
            end
            while this.currentTime < endTime
                if this.IsEventListEmpty()
                    break;
                end
                this.RunCurrentEvent();
            end
        end  
        
        % GETTIME Returns the current simulation time.
        function currentTime = GetTime( this )
            currentTime = this.currentTime;
        end
        
        % REMOVEEVENT Removes the given event from the list.
        function RemoveEvent( this, eventObject )
            numberOfEvents = length( this.scheduledEvents );
            for eventIndex = 1:numberOfEvents
                if this.scheduledEvents( eventIndex ) == eventObject
                    delete( this.scheduledEvents( eventIndex ) );
                    this.scheduledEvents( eventIndex ) = [];
                    break;
                end
            end
        end
    end
    
end

