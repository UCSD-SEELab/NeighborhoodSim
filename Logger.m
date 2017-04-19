classdef Logger < handle
    %LOGGER Displays messages on console
    
    properties( Access = 'private' )
        % Indicates whether to print logs.
        printLog = true;
        
        % Indicates whether results are drawn immediatelly.
        drawImmediatelly = true;
        
        % Indicates whether the simulation has started.
        simulating = false;
    end
    
    methods
        % LOG Logs a message.
        function Log( this, message )
            if this.printLog
                disp( message );
            end
        end
        
        % DRAWCHECK Returns whether immediate drawing is allowed.
        function check = DrawCheck( this )
            check = this.drawImmediatelly;
        end
        
        % ISSIMULATING Checks whether the simulation is running.
        function check = IsSimulating( this )
            check = this.simulating;
        end
        
        % ENABLELOGS Enables printing of the logs.
        function EnableLogs( this )
            this.printLog = true;
        end
        
        % DISABLELOGS Disables log printing.
        function DisableLogs( this )
            this.printLog = false;
        end
        
        % ENABLEIMMEDIATEDRAW Enables the drawing of figures immediately.
        function EnableImmediateDraw( this )
            this.drawImmediatelly = true;
        end
        
        % DISABLEIMMEDIATEDRAW Disables the drawing of figures immediately.
        function DisableImmediateDraw( this )
            this.drawImmediatelly = false;
        end
        
        % STARTSIMULATION Called to indicate that the simulation has
        % started.
        function StartSimulation( this )
            this.simulating = true;
        end
        
        % STOPSIMULATION Called to indicate that the simulation has
        % stopped.
        function StopSimulation( this )
            this.simulating = false;
        end
            
    end
    
    methods( Static )
        % GETLOGGER Returns the single Logger instance.
        function logHandle = GetLogger()
            persistent logObject;
            if isempty( logObject ) || ~isvalid( logObject )
                logObject = Logger();
            end
            logHandle = logObject;
        end
    end
    
end
