classdef SolarPanel < handle
    %SOLARPANEL A generic green energy source.
    
    properties
        % Power values for each interval.
        powerGenerationValues;
        
        % Currently generated power.
        currentPower = 0;
        
        % Indicates the index that will be generated from the values.
        currentPowerIndex = 1;
        
        % Scales the generation power value.
        scaleValue = 1;
        
        % Duration of each interval.
        periodicInterval;
        
        % Display name for the solar panel.
        solarPanelName;
        
        % Home that the panel is connected to.
        myHome;
        
        % Initial generation event.
        initialEvent;
    end
    
    methods
        % SOLARPANEL Loads the default specs.
        % SOLARPANEL(fileName) Loads from a spec file.
        % SOLARPANEL(power,interval) Creates a panel with given power and
        % interval values.
        % SOLARPANEL(power,interval,name) Creates a panel with given power
        % and interval values and assigns the given name.
        % SOLARPANEL(power,interval,name,scale) Creates a panel with given
        % power, interval and name, and scales the power values by the
        % given scale.
        function this = SolarPanel( varargin )
            if nargin == 0
                specs = load( 'defaultSolarPanel.mat' );
                specs = specs.specs;
                this.powerGenerationValues  = specs.powerGenerationValues;
                this.periodicInterval       = specs.periodicInterval;
                this.solarPanelName         = specs.solarPanelName;
                this.scaleValue             = specs.scaleValue;
            elseif nargin == 1
                specs = load( varargin{1} );
                specs = specs.specs;
                this.powerGenerationValues  = specs.powerGenerationValues;
                this.periodicInterval       = specs.periodicInterval;
                this.solarPanelName         = specs.solarPanelName;
                this.scaleValue             = specs.scaleValue;
            elseif nargin >= 2
                this.powerGenerationValues  = varargin{1};
                this.periodicInterval       = varargin{2};
                this.solarPanelName = 'DefaultSolarPanelName';
                if nargin == 3
                    this.solarPanelName = varargin{3};
                elseif nargin == 4
                    this.solarPanelName = varargin{3};
                    this.scaleValue = varargin{4};
                else
                    error( 'Too many inputs' );
                end
            end
        end
        
        % SAVE Saves the specs to a file.
        function Save( this )
            specs = this;
            save( this.solarPanelName, 'specs' );
        end
        
        % INSTALLINHOME Installs the panel in a home and creates the
        % initial generation event.
        function InstallInHome( this, house )
            this.myHome = house;
            updateEventFunction = @() this.UpdateGeneration();
            this.initialEvent = HomeSimEventScheduler.GetScheduler().ScheduleEventAfter( updateEventFunction, ...
                                                                                         this.periodicInterval );
        end
        
        % UPDATEGENERATION This function is periodically executed to update
        % the generation value to the next given interval value.
        function UpdateGeneration( this )
            Logger.GetLogger().Log(['Updated ' this.solarPanelName ' at ' datestr(HomeSimEventScheduler.GetScheduler().GetTime()/(24*3600))]);
            previousPower = this.currentPower;
            this.currentPower = this.powerGenerationValues( mod( this.currentPowerIndex, ...
                                                            length( this.powerGenerationValues ) ) ) ...
                                                            * this.scaleValue;
            this.currentPowerIndex = this.currentPowerIndex + 1;
            Logger.GetLogger().Log([num2str( previousPower ) ' -> ' num2str( this.currentPower )]);
            this.myHome.UpdateGreenEnergy( previousPower, this.currentPower );
            
            updateEventFunction = @() this.UpdateGeneration();
            HomeSimEventScheduler.GetScheduler().ScheduleEventAfter( updateEventFunction, ...
                                                                     this.periodicInterval );
        end
        
        % SCALEGENERATION Scales the given generation values by the factor.
        function ScaleGeneration( this, scaleFactor )
            this.scaleValue = scaleFactor;
        end
        
        % REINITIALIZESTARTINGEVENT Unschedules the current event and
        % reschedules a new one.
        function ReinitializeStartingEvent( this )
            if ~isempty( this.initialEvent )
                HomeSimEventScheduler.GetScheduler().RemoveEvent( this.initialEvent );
            end
            updateEventFunction = @() this.UpdateGeneration();
            this.initialEvent = HomeSimEventScheduler.GetScheduler().ScheduleEventAfter( updateEventFunction, ...
                                                                                         this.periodicInterval );
        end
    end
    
end

