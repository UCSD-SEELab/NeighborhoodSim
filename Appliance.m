classdef Appliance < handle
    %APPLIANCE General consumer class, decsribing an appliance.
    
    properties
        % Is the appliance currently active.
        isActive = false;
        
        % Current power consumption of the appliance.
        currentPower = 0;
        % If a load profile is followed, this indicates the current index
        % we are at.
        currentPowerIndex = 0;
        
        % Load profile.
        powerConsumptionValues;
        % Size of the load profile.
        numberOfConsumptionValues;
        % Duration of each load profile interval.
        durationValues;

        % Power type of the device, AC or DC.
        activePowerType = ActivePowerTypeValues.ACDevice;
        % The current energy source of the device.
        energySource = EnergySourceValues.Grid;
        
        % Periodicity interval at which the appliance will be rescheduled.
        periodicInterval;
        % Time offset before the initial event.
        startingOffset;
             
        % Voltage converter device for AC/DC conversion.
        voltageConverter;
        
        % Display name.
        applianceName;
        
        % Individual battery.
        myBattery; 
        % Is an individual battery installed.
        isMyBatteryInstalled = false;
        
        % If connected to a house battery, which one.
        usedHouseBattery;
        % Is the appliance drawing power from a house battery.
        isHouseBatteryConnected = false;
        
        % Initially scheduled event for deleting purposes.
        initialEvent;
        
        % The house that the appliance is connected to.
        myHome;
    end
    
    methods
        function this = Appliance( varargin )
            %APPLIANCE(fileName) Uses a spec file to construct the appliance.
            %APPLIANCE(interval,offset,consumptions) Creates an appliance with periodicity, offset
            %and given consumption values.
            %APPLIANCE(interval,offset,consumptions,durations) Specifies the duration of each
            %interval.
            %APPLIANCE(interval,offset,consumptions,durations,name) Specifies label for the
            %appliance.
            %APPLIANCE(interval,offset,consumptions,durations,name,converterFile) Specifies the spec
            %file for the voltage converter to be used.
            if nargin == 0
                specs = load( 'defaultAppliance.mat' );
                specs = specs.specs;
            elseif nargin == 1
                specs = load( varargin{1} );
                specs = specs.specs;
            elseif nargin >= 3
                specs.periodicInterval          = varargin{1};
                specs.startingOffset            = varargin{2};
                specs.powerConsumptionValues    = varargin{3};
                specs.applianceName             = 'DefaultApplianceName';
                specs.voltageConversionSpecFile = 'defaultACVoltageConverter.mat';
                if nargin >= 4
                    specs.durationValues        = varargin{4};
                    if nargin >= 5
                        specs.applianceName     = varargin{5};
                        if nargin == 6
                            specs.voltageConversionSpecFile = varargin{6};
                        elseif nargin > 6
                            error( 'Too many inputs' );
                        end
                    end
                end
            else
                error( 'Not enough inputs' );
            end
            
            this.periodicInterval           = specs.periodicInterval;
            this.startingOffset             = specs.startingOffset;
            this.powerConsumptionValues     = specs.powerConsumptionValues;
            this.numberOfConsumptionValues  = length( this.powerConsumptionValues );
            if ( isfield( specs, 'durationValues' ) || isprop( specs, 'durationValues' ) )
                this.durationValues = specs.durationValues;
                if length( this.durationValues ) ~= this.numberOfConsumptionValues
                    error( '#Duration Values must be the same as #Consumption Values' );
                end
            else
                this.durationValues = this.periodicInterval * ones( this.numberOfConsumptionValues, 1 );
            end
            this.durationValues = this.durationValues - 0.001; % To make sure duration < interval
            if any( this.durationValues > this.periodicInterval )
                error( 'Duration cannot exceed periodicity' );
            end
            
            this.applianceName        = specs.applianceName; 
            
            if ~( isfield( specs, 'voltageConversionSpecFile' ) || isprop( specs, 'voltageConversionSpecFile' ) )
                if ( isfield( specs, 'voltageConverter' ) || isprop( specs, 'voltageConverter' ) )
                    this.voltageConverter = VoltageConversionDevice( specs.voltageConverter );
                else
                    voltageConversionSpecFile = 'defaultACVoltageConverter.mat';
                    this.voltageConverter = VoltageConversionDevice( voltageConversionSpecFile );
                end
            else
                voltageConversionSpecFile = specs.voltageConversionSpecFile;
                this.voltageConverter     = VoltageConversionDevice( voltageConversionSpecFile );
            end
        end
        
        % SAVE Saves the object information into a file that has the name
        % of the appliance. Furthermore, the appliance name is appended
        % into the appliance list file for the GUI.
        function Save( this )
            specs = this;
            save( this.applianceName, 'specs' );
            applianceListFile = load( 'applianceList.mat' );
            applianceList = [applianceListFile.applianceList, this.applianceName];
            save( 'applianceList.mat', 'applianceList' );
        end
        
        % INSTALLINHOME Use this function to install the appliance to a
        % specific home. This will enable the first event of the appliance
        % and create a connection to the home.
        function InstallInHome( this, house )
            this.myHome = house;
            startEventFunction = @() this.Start();
            this.initialEvent = HomeSimEventScheduler.GetScheduler().ScheduleEventAfter( startEventFunction, ...
                                                                                         this.startingOffset );
        end
        
        % INSTALLBATTERY Appliances can have their own individual
        % batteries. These batteries can only discharge to the appliance
        % itself.
        function InstallBattery( this, battery )
            this.isMyBatteryInstalled = true;
            this.myBattery = battery;
        end
        
        % START Starting event of the appliance. The appliance first checks
        % for available green energy in the house. Then, the individual
        % battery is checked for available charge. Finally, the house
        % batteries are checked for available charge. If nothing is
        % available, the grid supply is used. Two more events are
        % scheduled: the stopping event and the next starting event.
        function Start( this )           
            usedValueIndex = mod( this.currentPowerIndex, this.numberOfConsumptionValues ) + 1;
            this.currentPowerIndex = this.currentPowerIndex + 1;
            
            currentDuration = this.durationValues( usedValueIndex );
            this.currentPower = this.powerConsumptionValues( usedValueIndex );
            
            Logger.GetLogger().Log(['Started ' this.applianceName ' at ' datestr(HomeSimEventScheduler.GetScheduler().GetTime()/(24*3600)) '(' num2str(this.currentPower) ')']);
            
            dcPowerNeed = this.voltageConverter.ToDC( this.currentPower );
            acPowerNeed = this.voltageConverter.ToAC( this.currentPower );
            if isempty(this.myHome)
                return
            end
            if dcPowerNeed > 0
                % Check green energy (Home)
                if this.myHome.IsGreenEnergyAvailable( dcPowerNeed )
                    this.energySource = EnergySourceValues.Solar;
                    this.myHome.UseGreenEnergy( dcPowerNeed );
                % Check own battery (Own Battery)
                elseif this.isMyBatteryInstalled && ...
                       this.myBattery.IsBatteryAvailable( dcPowerNeed, currentDuration )
                    this.energySource = EnergySourceValues.OwnBattery;
                    this.myBattery.UseBattery( dcPowerNeed );
                % Check global batteries (Home)
                else
                    [isAvailable, houseBattery] = this.myHome.IsHomeBatteryAvailable( dcPowerNeed, ...
                                                                                      currentDuration );
                    if isAvailable
                        this.energySource = EnergySourceValues.Battery;
                        this.usedHouseBattery = houseBattery;
                        this.isHouseBatteryConnected = true;
                        houseBattery.UseBattery( dcPowerNeed, currentDuration );
                    % Get from grid (Grid)
                    else
                        this.energySource = EnergySourceValues.Grid;
                        this.myHome.UseGridSupply( acPowerNeed );
                    end
                end
                
                % Schedule the end of time.
                stopEventFunction = @() this.Stop();
                HomeSimEventScheduler.GetScheduler().ScheduleEventAfter( stopEventFunction, ...
                                                                         currentDuration );
            end
            
            % Schedule the next cycle.
            restartEventFunction = @() this.Start();
            HomeSimEventScheduler.GetScheduler().ScheduleEventAfter( restartEventFunction, ...
                                                                     this.periodicInterval );
        end
        
        % STOP This is the stopping event. Since the usage is finished, the
        % currently used energy source is released.
        function Stop( this )
            Logger.GetLogger().Log(['Stopped ' this.applianceName ' at ' datestr(HomeSimEventScheduler.GetScheduler().GetTime()/(24*3600))]);
            dcPowerNeed = this.voltageConverter.ToDC( this.currentPower );
            acPowerNeed = this.voltageConverter.ToAC( this.currentPower );
            
            if this.energySource.IsGreenSource()
                this.myHome.ReleaseGreenEnergy( dcPowerNeed );
            elseif this.energySource == EnergySourceValues.OwnBattery
                if this.isMyBatteryInstalled
                    this.myBattery.ReleaseBattery( dcPowerNeed );
                else
                    error( 'No own battery installed. Bug' );
                end
            elseif this.energySource == EnergySourceValues.Grid
                this.myHome.ReleaseGridSupply( acPowerNeed );
            elseif this.energySource == EnergySourceValues.Battery
                if this.isHouseBatteryConnected
                    this.usedHouseBattery.ReleaseBattery( dcPowerNeed );
                    this.isHouseBatteryConnected = false;
                else
                    error( 'No battery connected. Bug' );
                end
            else
                error( 'Unknown Energy Source state' );
            end
            this.energySource = EnergySourceValues.None;
            this.currentPower = 0;
        end
        
        % TRYTOSTAYGREEN This function is called from the Home. If the
        % green energy supply becomes insufficient, the available energy
        % will need to be redistributed. This command tries to make the
        % appliance stay green if there is enough energy. If the current
        % source is not green, this function has no effect.
        function TryToStayGreen( this )
            if this.energySource.IsGreenSource()
                dcPowerNeed = this.voltageConverter.ToDC( this.currentPower );
                if dcPowerNeed > 0
                    if this.myHome.IsGreenEnergyAvailable( dcPowerNeed )
                        this.myHome.UseGreenEnergy( dcPowerNeed );
                        this.energySource = EnergySourceValues.Solar;
                    else
                        acPowerNeed = this.voltageConverter.ToAC( this.currentPower );
                        this.myHome.UseGridSupply( acPowerNeed );
                        this.energySource = EnergySourceValues.Grid;
                    end
                end
            end
        end
        
        % TRYTOGOGREEN This function is called from the Home. If the green
        % energy supply changes, the available energy is redistributed. The
        % appliance will use green energy if there is enough available. If
        % the current source is not the grid, this function has no effect.
        function TryToGoGreen( this )
            if this.energySource == EnergySourceValues.Grid
                dcPowerNeed = this.voltageConverter.ToDC( this.currentPower );
                acPowerNeed = this.voltageConverter.ToAC( this.currentPower );
                if dcPowerNeed > 0
                    if this.myHome.IsGreenEnergyAvailable( dcPowerNeed )
                        this.myHome.ReleaseGridSupply( acPowerNeed );
                        this.myHome.UseGreenEnergy( dcPowerNeed );
                        this.energySource = EnergySourceValues.Solar;
                    end
                end
            end
        end
        
        % TRYOWNBATTERYTOSTAYGREEN This function is called from the Home.
        % If the green energy supply changes, the available energy is
        % redistributed. This function simply relays the command to the
        % battery.
        function TryOwnBatteryToStayGreen( this )
            if this.isMyBatteryInstalled
                this.myBattery.TryToStayGreen();
            end
        end
        
        % TRYOWNBATTERYTOGOGREEN This function is called from the Home.
        % If the green energy supply changes, the available energy is
        % redistributed. This function simply relays the command to the
        % battery.
        function TryOwnBatteryToGoGreen( this )
            if this.isMyBatteryInstalled
                this.myBattery.TryToGoGreen();
            end
        end
        
        % DELETE Overload of the Matlab's delete function. The event will
        % be unscheduled if the appliance is deleted.
        function delete( this )
            if ~isempty( this.initialEvent ) && isvalid( this.initialEvent )
                HomeSimEventScheduler.GetScheduler().RemoveEvent( this.initialEvent );
            end
        end
        
        % RANDOMIZESTARTINGTIMEGAUSS Randomizes the starting offset of the
        % appliance. @scaleFactor determines the scale of the gaussian
        % random number.
        function RandomizeStartingTimeGauss( this, scaleFactor )
            if ~isempty( this.initialEvent )
                HomeSimEventScheduler.GetScheduler().RemoveEvent( this.initialEvent );
            end
            this.startingOffset = max( this.startingOffset + randn(1) * scaleFactor, 0 );
            startEventFunction = @() this.Start();
            this.initialEvent = HomeSimEventScheduler.GetScheduler().ScheduleEventAfter( startEventFunction, ...
                                                                                         this.startingOffset );
        end
        
        % RANDOMIZESTARTINGTIMEUNIFORM Randomizes the starting offset of
        % the appliance by a uniform random variable. @scaleFactor
        % determines the scale of the random number.
        function RandomizeStartingTimeUniform( this, scaleFactor )
            if ~isempty( this.initialEvent )
                HomeSimEventScheduler.GetScheduler().RemoveEvent( this.initialEvent );
            end
            this.startingOffset = max( this.startingOffset + rand(1) * scaleFactor, 0 );
            startEventFunction = @() this.Start();
            this.initialEvent = HomeSimEventScheduler.GetScheduler().ScheduleEventAfter( startEventFunction, ...
                                                                                         this.startingOffset );
        end
        
        % REINITIALIZESTARTINGEVENT Resets the start event by unscheduling
        % the previous instance and scheduling a new one.
        function ReinitializeStartingEvent( this )
            if ~isempty( this.initialEvent )
                HomeSimEventScheduler.GetScheduler().RemoveEvent( this.initialEvent );
            end
            startEventFunction = @() this.Start();
            this.initialEvent = HomeSimEventScheduler.GetScheduler().ScheduleEventAfter( startEventFunction, ...
                                                                                         this.startingOffset );
        end
    end
    
end

