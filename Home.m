classdef Home < handle
    % HOME Represents a home, consisting of appliances, generators and
    % batteries.
    %   The home class handles the connections between every object that is
    %   connected to it.
    
    properties
        % Connected appliances.
        loadList = Appliance();
        % Number of connected appliances.
        numberOfLoads = 0;
        
        % Connected generators.
        generatorList = SolarPanel();
        % Number of connected generators.
        numberOfGenerators = 0;
        
        % Connected batteries.
        hybridList = Battery();
        % Number of connected batteries.
        numberOfHybrids = 0;
        
        % Grid connection of the house.
        gridSupply;
    end
    
    properties
        % Available green energy.
        totalGreenEnergyAvailable = 0;
        % Used green energy.
        totalGreenEnergyUsed = 0;
        
        % Number of snapshots in the history.
        historySize = 1;
        % Generation values in the history database.
        historyConsumption = 0;
        % Timestamps for the history database.
        historyTime = 0;
    end
    
    methods
        % HOME Creates a home with a grid supply.
        function this = Home()
            this.gridSupply = GridSupply();
        end
        
        % INSTALLAPPLIANCES Installs new appliances to the current list.
        % This is an appending operation, not replacing.
        function InstallAppliances( this, applianceList )
            newApplianceSize = length( applianceList );
            currentIndex = this.numberOfLoads;
            this.loadList( currentIndex + newApplianceSize ) = Appliance();
            for applianceIndex = 1:newApplianceSize
                this.loadList( currentIndex + applianceIndex ) = applianceList( applianceIndex );
                this.loadList( currentIndex + applianceIndex ).InstallInHome( this );
                this.numberOfLoads = this.numberOfLoads + 1;
            end
        end
        
        % REMOVEAPPLIANCE Removes a specific appliance from the list.
        function RemoveAppliance( this, applianceIndex )
            if applianceIndex > this.numberOfLoads
                error( 'Appliance non-existent' );
            end
            delete( this.loadList( applianceIndex ) );
            this.loadList( applianceIndex ) = [];
            this.numberOfLoads = this.numberOfLoads - 1;
        end
        
        % INSTALLGENERATORS Installs generators to the home and adds them
        % to the list. This operation is appending, not replacing.
        function InstallGenerators( this, generatorList )
            newGeneratorSize = length( generatorList );
            currentIndex = this.numberOfGenerators;
            this.generatorList( currentIndex + newGeneratorSize ) = SolarPanel();
            for generatorIndex = 1:newGeneratorSize
                this.generatorList( currentIndex + generatorIndex ) = generatorList( generatorIndex );
                this.generatorList( currentIndex + generatorIndex ).InstallInHome( this );
                this.numberOfGenerators = this.numberOfGenerators + 1;
            end
        end
        
        % INSTALLHYBRIDS Installs batteries to the home and adds them
        % to the list. This operation is appending, not replacing.
        function InstallHybrids( this, hybridList )
            newHybridSize = length( hybridList );
            currentIndex = this.numberOfHybrids;
            this.hybridList( currentIndex + newHybridSize ) = Battery();
            for hybridIndex = 1:newHybridSize
                this.hybridList( currentIndex + hybridIndex ) = hybridList( hybridIndex );
                this.hybridList( currentIndex + hybridIndex ).InstallInHome( this );
                this.numberOfHybrids = this.numberOfHybrids + 1;
            end
        end
        
        % ISGREENENERGYAVAILABLE Checks whether there is enough green
        % energy.
        function isAvailable = IsGreenEnergyAvailable( this, dcPowerAmount )
            isAvailable = ( dcPowerAmount <= this.totalGreenEnergyAvailable );
        end
        
        % GETGREENENERGYAVAILABILITY Returns the available green energy.
        function availableEnergy = GetGreenEnergyAvailability( this )
            availableEnergy = this.totalGreenEnergyAvailable;
        end
        
        % RECORDHISTORY Takes a snapshot for the history database.
        function RecordHistory( this )
            this.historySize = this.historySize + 1;
            this.historyConsumption( this.historySize ) = this.totalGreenEnergyUsed;
            this.historyTime( this.historySize ) = HomeSimEventScheduler.GetScheduler().GetTime();
            %this.PlotHistory();
        end
        
        % PLOTHISTORY Plots the historic database.
        function PlotHistory( this )
            figure(1);
            subplot(1,2,2);
            stem( this.historyTime / ( 24 * 3600 ), this.historyConsumption );
            datetick( 'x' );
            drawnow();
        end        
        
        % USEGREENENERGY Assigns the requested green energy.
        function UseGreenEnergy( this, dcPowerAmount )
            if this.IsGreenEnergyAvailable( dcPowerAmount )
                this.totalGreenEnergyAvailable = this.totalGreenEnergyAvailable - dcPowerAmount;
                this.totalGreenEnergyUsed = this.totalGreenEnergyUsed + dcPowerAmount;
                this.RecordHistory();
                Logger.GetLogger().Log( ['Green Energy used: ' num2str( dcPowerAmount ) ' , Left: ' num2str( this.totalGreenEnergyAvailable )] );
            else
                warning( 'Green energy cannot go negative' );
            end
            
        end
        
        % RELEASEGREENENERGY Released the allocated green energy.
        function ReleaseGreenEnergy( this, dcPowerAmount )
            this.totalGreenEnergyAvailable = this.totalGreenEnergyAvailable + dcPowerAmount;
            this.totalGreenEnergyUsed = this.totalGreenEnergyUsed - dcPowerAmount;
            this.RecordHistory();
        end
        
        % UPDATEGREENENERGY When the green energy amoun changes, the
        % allocation and scheduling has to be updated. The house checks the
        % loads that already uses green. Then it checks, whether new loads
        % can transition to green. Then, individual batteries are tried to
        % be kept green and then checked for a transition to green. Finally
        % the house batteries are tried to be kept green and then tried to
        % be transitioned to green.
        function UpdateGreenEnergy( this, previousAmount, currentAmount )
            totalGreenEnergyGenerated = this.totalGreenEnergyAvailable + this.totalGreenEnergyUsed - previousAmount + currentAmount;
            this.RecordHistory();
            if totalGreenEnergyGenerated < 0
                warning( 'Green energy cannot go negative' );
                totalGreenEnergyGenerated = 0;
            end
            this.totalGreenEnergyAvailable = totalGreenEnergyGenerated;
            
            % Update everybody
            for loadIndex = 1:this.numberOfLoads
                this.loadList( loadIndex ).TryToStayGreen();
            end
            for loadIndex = 1:this.numberOfLoads
                this.loadList( loadIndex ).TryToGoGreen();
            end
            for loadIndex = 1:this.numberOfLoads
                this.loadList( loadIndex ).TryOwnBatteryToStayGreen();
            end
            for loadIndex = 1:this.numberOfLoads
                this.loadList( loadIndex ).TryOwnBatteryToGoGreen();
            end
            for hybridIndex = 1:this.numberOfHybrids
                this.hybridList( hybridIndex ).TryToStayGreen();
            end
            for hybridIndex = 1:this.numberOfHybrids
                this.hybridList( hybridIndex ).TryToGoGreen();
            end
        end
        
        % ISHOMEBATTERYAVAILABLE Checks whether a house battery is
        % available in terms of stored charge. Returns also which battery
        % is available.
        function [isAvailable, battery] = IsHomeBatteryAvailable( this, dcPowerAmount, duration )
            if this.numberOfHybrids > 0
                dischargeList = ( [this.hybridList.activeMode] == ActiveModeValues.Discharging );
                SoCList = [this.hybridList.SoC];
                if isempty( dischargeList )
                    if isempty( SoCList )
                        maximumIndex = NaN;
                    else
                        [~, maximumIndex] = max( SoCList );
                    end
                else
                    [~, maximumIndex] = max( SoCList .* dischargeList );
                end
                if isnan( maximumIndex )
                    isAvailable = false;
                    battery = false;
                else
                    battery = this.hybridList( maximumIndex );
                    isAvailable = battery.IsBatteryAvailable( dcPowerAmount, duration );
                end
            else
                isAvailable = false;
                battery = false;
            end
        end
        
        % USEGRIDSUPPLY Adds consumption to the grid supply.
        function UseGridSupply( this, acPowerAmount )
            this.gridSupply.UseGridSupply( acPowerAmount );
        end
        
        % RELEASEGRIDSUPPLY Removes consumption from the grid supply.
        function ReleaseGridSupply( this, acPowerAmount )
            this.gridSupply.ReleaseGridSupply( acPowerAmount );
        end
        
        % RANDOMIZESTARTINGTIMESGAUSS Randomizes the starting offsets of
        % every appliance using Gaussian random variable.
        function RandomizeStartingTimesGauss( this, scaleFactor )
            for load = this.loadList
                load.RandomizeStartingTimeGauss( scaleFactor );
            end
        end
        
        % RANDOMIZESTARTINGTIMESUNIFORM Randomizes the starting offsets of
        % every appliance using Uniform random variable.
        function RandomizeStartingTimesUniform( this, scaleFactor )
            for load = this.loadList
                load.RandomizeStartingTimeUniform( scaleFactor );
            end
        end
        
        % REINITIALIZESTARTINGEVENTS Resets the starting events, especially
        % if the house is loaded from a file.
        function ReinitializeStartingEvents( this )
            for load = this.loadList
                load.ReinitializeStartingEvent();
            end
            for gen = this.generatorList
                gen.ReinitializeStartingEvent();
            end
        end
    end
    
end

