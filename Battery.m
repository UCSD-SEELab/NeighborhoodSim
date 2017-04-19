classdef Battery < handle
    %BATTERY A general battery class to be used in home of per appliance.
    
    properties
        % Current mode of the battery.
        activeMode = ActiveModeValues.Idle;
        % Current charge/discharge power of the battery.
        selectedCurrent = 0;
        
        % Last update time for released/added charge calculation.
        updateTime = 0;
        % The duration promised by the battery to an appliance to be
        % available.
        promisedDuration = 0;
        % Current State of Charge.
        SoC = 1;
        
        % Charge capacity of the battery.
        capacity;
        % Nominal voltage of the battery.
        nominalVoltage;
        % Rated time of discharge of the battery.
        ratedTime;
        % Lower bound for the current.
        lowerCurrentLimit;
        % Discharge upper bound for the current.
        dischargeUpperCurrentLimit;
        % Charging upper bound for the current.
        chargeUpperCurrentLimit;
        % Peukert exponent of the battery chemistry.
        peukertExponent;
        % Depth of discharge limit of the battery.
        dodLimit;
        
        % Display name of the battery.
        batteryName;

        % The current source of the energy.
        energySource = EnergySourceValues.Grid;
        
        % Voltage converter device for AC/DC conversion.
        voltageConverter;
        
        % Current update event for unscheduling
        updateEvent;
        % Is update event scheduled.
        isUpdateScheduled = false;
        
        % The home that the battery is installed in.
        myHome;
    end
    
    methods
        % BATTERY Loads the default battery specs.
        % BATTERY(fileName) Loads the specs from a saved file.
        % BATTERY(capacity, nominalVoltage, ratedTime, lowerLimit, 
        % dischargeUpperLimit,chargeUpperLimit,peukertExponent,dodLimit)
        % Creates a battery with the given specs.
        % BATTERY(capacity, nominalVoltage, ratedTime, lowerLimit, 
        % dischargeUpperLimit, chargeUpperLimit, peukertExponent, dodLimit,
        % batteryName) Creates a battery with the given specs and name.
        % BATTERY(capacity, nominalVoltage, ratedTime, lowerLimit, 
        % dischargeUpperLimit, chargeUpperLimit, peukertExponent, dodLimit,
        % batteryName, converterName) Creates a battery with the given
        % specs, name and voltage converter spec file name.
        function this = Battery( varargin )
            if nargin == 0
                specs = load( 'defaultBattery.mat' );
                specs = specs.specs;
            elseif nargin == 1
                specs = load( varargin{1} );
                specs = specs.specs;
            elseif nargin >= 8
                specs.capacity                      = 60 * 60 * varargin{1};
                specs.nominalVoltage                = varargin{2};
                specs.ratedTime                     = varargin{3};
                specs.lowerCurrentLimit             = varargin{4};
                specs.dischargeUpperCurrentLimit    = varargin{5};
                specs.chargeUpperCurrentLimit       = varargin{6};
                specs.peukertExponent               = varargin{7};
                specs.dodLimit                      = varargin{8};
                specs.batteryName                   = 'DefaultBatteryName';
                specs.voltageConversionSpecFile     = 'defaultDCVoltageConverter.mat';
                if nargin >= 9
                    specs.batteryName               = varargin{9};
                    if nargin == 10
                        specs.voltageConversionSpecFile = varargin{10};
                    elseif nargin > 10
                        error( 'Too many inputs.' );
                    end
                end
            else
                error( 'Wrong number of inputs' );
            end
            this.capacity                       = specs.capacity;
            this.nominalVoltage                 = specs.nominalVoltage;
            this.ratedTime                      = specs.ratedTime;
            this.lowerCurrentLimit              = specs.lowerCurrentLimit;
            this.dischargeUpperCurrentLimit     = specs.dischargeUpperCurrentLimit;
            this.chargeUpperCurrentLimit        = specs.chargeUpperCurrentLimit;
            this.peukertExponent                = specs.peukertExponent;
            this.dodLimit                       = specs.dodLimit;
            this.batteryName                    = specs.batteryName;
            
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
        
        % SAVE Saves the battery specs to a file and adds the name to the
        % battery list file for the GUI connection.
        function Save( this )
            specs = this;
            save( this.batteryName, 'specs' );
            batteryListFile = load( 'batteryList.mat' );
            batteryList = [batteryListFile.batteryList, this.batteryName];
            save( 'batteryList.mat', 'batteryList' );
        end
        
        % INSTALLINHOME Installs the battery in a house and creates the
        % necessary connections.
        function InstallInHome( this, house )
            this.myHome = house;
        end
        
        % CALCULATEEFFECTIVECAPACITY Calculates the effective capacity
        % using the nonlinear Peukert's model.
        function effectiveCapacity = CalculateEffectiveCapacity( this )
            effectiveCapacity = this.capacity * ...
                                ( this.capacity / ( this.selectedCurrent * this.ratedTime ) ) ...
                                ^ ( this.peukertExponent - 1 );
        end
        
        % CALCULATEACTIVEPOWER Power = Voltage x Current
        function activePower = CalculateActivePower( this )
            activePower = this.selectedCurrent * this.nominalVoltage;
        end
        
        % CALCULATEREQUIREDCURRENT Current = Power / Voltage.
        function activeCurrent = CalculateRequiredCurrent( this, activePower )
            activeCurrent = activePower / this.nominalVoltage;
        end
        
        % CALCULATECHARGETIME Calculates the time to fully charge the
        % battery.
        function chargeTime = CalculateChargeTime( this )
            remainingCapacity = ( 1 - this.SoC ) * this.capacity;
            chargeTime = remainingCapacity / ( this.selectedCurrent ^ ( this.peukertExponent - 1 ) );
        end
        
        % CALCULATEDISCHARGETIME Calculates the remaining lifetime of the
        % battery using its current charge.
        function dischargeTime = CalculateDischargeTime( this )
            remainingCapacity = ( this.SoC - ( 1 - this.dodLimit ) ) * this.CalculateEffectiveCapacity();
            dischargeTime = remainingCapacity / this.selectedCurrent;
        end
        
        % RELEASEPOWERSOURCE When the battery's current operation finishes,
        % the currently used power source is notified.
        function ReleasePowerSource( this )
            if this.activeMode == ActiveModeValues.Charging
                if this.energySource == EnergySourceValues.Grid
                    activePower = this.voltageConverter.ToAC( this.CalculateActivePower() );
                    this.myHome.LeaveGridSupply( activePower );
                elseif this.energySource.IsGreenSource()
                    activePower = this.voltageConverter.ToDC( this.CalculateActivePower() );
                    this.myHome.LeaveGreenEnergy( activePower );
                end
                this.energySource = EnergySourceValues.None;
            elseif this.activeMode == ActiveModeValues.Discharging
                if this.energySource == EnergySourceValues.Grid
                    activePower = this.voltageConverter.ToAC( this.CalculateActivePower() );
                    this.myHome.LeaveGridSupply( -activePower );
                elseif this.energySource.IsGreenSource()
                    activePower = this.voltageConverter.ToDC( this.CalculateActivePower() );
                    this.myHome.LeaveGreenEnergy( -activePower );
                end
                this.energySource = EnergySourceValues.None;
            end
            this.activeMode = ActiveModeValues.Idle;
            this.selectedCurrent = 0;
        end
        
        % UPDATEBATTERYSTATE Updates the current battery state since the
        % last usage according to the time elapsed since the last update
        % and the power used during that interval.
        function UpdateBatteryState( this )
            if this.activeMode == ActiveModeValues.Charging
                effectiveCapacity = this.CalculateEffectiveCapacity();
                currentTime = HomeSimEventScheduler.GetScheduler().GetTime();
                totalCharge = ( currentTime - this.updateTime ) * this.selectedCurrent;
                this.SoC = this.SoC + totalCharge / effectiveCapacity;
                if this.SoC > 1
                    Logger.GetLogger().Warning( 'SoC gone beyond full' );
                    this.SoC = 1;
                end
                this.updateTime = currentTime;
                
                % Charging is finished
                if this.SoC == 1
                    this.ReleasePowerSource();
                end
            elseif this.activeMode == ActiveModeValues.Discharging
                effectiveCapacity = this.CalculateEffectiveCapacity();
                currentTime = HomeSimEventScheduler.GetScheduler().GetTime();
                totalCharge = ( currentTime - this.updateTime ) * this.selectedCurrent;
                this.SoC = this.SoC - totalCharge / effectiveCapacity;
                if this.SoC < 1 - this.dodLimit
                    Logger.GetLogger().Warning( 'SoC gone beyond DoD Limit' );
                    this.SoC = 1 - this.dodLimit;
                end
                this.updateTime = currentTime;
                
                % Discharging is finished and we are empty.
                if this.SoC == 1 - this.dodLimit
                    this.ReleasePowerSource();
                end
            end
            this.isUpdateScheduled = false;
        end
        
        % SCHEDULEUPDATETIME Schedules the next update time. This is either
        % at the end of charging or end of discharging.
        function ScheduleUpdateTime( this )
            finishTime = 0;
            if this.activeMode == ActiveModeValues.Charging
                finishTime = this.CalculateChargeTime();
            elseif this.activeMode == ActiveModeValues.Discharging
                finishTime = this.CalculateDischargeTime();
            end
            if finishTime > 0
                if this.isUpdateScheduled
                    HomeSimEventScheduler.GetScheduler().RemoveEvent( this.updateEvent );
                end
                updateEventFunction = @() this.UpdateBatteryState();
                this.updateEvent = HomeSimEventScheduler.GetScheduler().ScheduleEventAfter( updateEventFunction, ...
                                                                                            finishTime );
                this.isUpdateScheduled = true;
            end
        end
                
        % TRYTOSTAYGREEN This function is invoked by the appliance of the
        % home when the available green energy changes for rescheduling.
        function TryToStayGreen( this )
            if this.activeMode == ActiveModeValues.Charging
                if this.energySource.IsGreenSource()
                    previousCurrent = this.selectedCurrent;
                    this.selectedCurrent = this.chargeUpperCurrentLimit;
                    dcPowerNeed = this.voltageConverter.ToDC( this.CalculateActivePower() );
                    if this.myHome.IsGreenEnergyAvailable( dcPowerNeed )
                        this.myHome.UseGreenEnergy( dcPowerNeed );
                    else
                        availablePower = this.myHome.GetGreenEnergyAvailability();
                        convertedPower = this.voltageConverter.FromDC( availablePower );
                        this.selectedCurrent = this.CalculateRequiredCurrent( convertedPower );
                        dcPowerNeed = this.voltageConverter.ToDC( this.CalculateActivePower() );
                        this.myHome.UseGreenEnergy( dcPowerNeed );
                    end
                    this.energySource = EnergySourceValues.Solar;
                    if this.selectedCurrent ~= previousCurrent
                        if this.selectedCurrent == 0
                            this.ReleasePowerSource();
                        else
                            this.ScheduleUpdateTime();
                        end
                    end
                end
            end
        end
        
        % TRYTOGOGREEN This function is invoked by the appliance of the
        % home when the available green energy changes for rescheduling.
        function TryToGoGreen( this )
            if this.activeMode == ActiveModeValues.Idle
                if this.SoC < 1
                    previousCurrent = 0;
                    this.selectedCurrent = this.chargeUpperCurrentLimit;
                    dcPowerNeed = this.voltageConverter.ToDC( this.CalculateActivePower() );
                    if this.myHome.IsGreenEnergyAvailable( dcPowerNeed )
                        this.myHome.UseGreenEnergy( dcPowerNeed );
                    else
                        availablePower = this.myHome.GetGreenEnergyAvailability();
                        convertedPower = this.voltageConverter.FromDC( availablePower );
                        this.selectedCurrent = this.CalculateRequiredCurrent( convertedPower );
                        dcPowerNeed = this.voltageConverter.ToDC( this.CalculateActivePower() );
                        this.myHome.UseGreenEnergy( dcPowerNeed );
                    end
                    this.energySource = EnergySourceValues.Solar;
                    if this.selectedCurrent ~= previousCurrent
                        if this.selectedCurrent == 0
                            this.ReleasePowerSource();
                        else
                            this.ScheduleUpdateTime();
                        end
                    end
                end
            end
        end
        
        % ISBATTERYAVAILABLE Checks whether the battery has enough charge
        % for the given power and duration.
        function isAvailable = IsBatteryAvailable( this, dcPower, duration )
            checkedDuration = max( duration, this.promisedDuration );
            isAvailable = false;
            if this.activeMode == ActiveModeValues.Charging
                isAvailable = false;
            else
                if this.activeMode == ActiveModeValues.Idle
                    possibleCurrent = this.CalculateRequiredCurrent( dcPower );
                elseif this.activeMode == ActiveModeValues.Discharging
                    possibleCurrent = this.selectedCurrent + this.CalculateRequiredCurrent( dcPower );
                end
                if possibleCurrent <= this.dischargeUpperCurrentLimit
                    previousCurrent = this.selectedCurrent;
                    this.selectedCurrent = possibleCurrent;
                    dischargeTime = this.CalculateDischargeTime();
                    if checkedDuration <= dischargeTime
                        isAvailable = true;
                    end
                    this.selectedCurrent = previousCurrent;
                end
            end
        end
        
        % USEBATTERY The battery is assigned for the given consumption and
        % duration.
        function UseBattery( this, dcPower, duration )
            this.promisedDuration = max( this.promisedDuration, duration );
            this.selectedCurrent = this.selectedCurrent + this.CalculateRequiredCurrent( dcPower );
            this.activeMode = ActiveModeValues.Discharging;
            this.updateTime = HomeSimEventScheduler.GetScheduler().GetTime();
            this.ScheduleUpdateTime();
        end
        
        % RELEASEBATTERY The battery is not used anymore.
        function ReleaseBattery( this, dcPower )
            this.selectedCurrent = this.selectedCurrent - this.CalculateRequiredCurrent( dcPower );
            if this.selectedCurrent < eps
                this.selectedCurrent = 0;
                this.activeMode = ActiveModeValues.Idle;
                this.promisedDuration = 0;
            end
        end
    end
    
end

