classdef GridSupply < handle
    %GRIDSUPPLY The grid connection of a house or neighborhood.
    %   There are two types of grid supplies. 1- Each house has its own
    %   grid supply, which is the analog of the smart meter. 2- Each grid
    %   supply is connected to a global grid supply, which represents the
    %   utility side.
    
    properties
        % Unit cost of energy, currently unused.
        unitCost = 1;
        % Current consumption drawn from the grid.
        currentConsumption = 0;
        
        % Size of the historical database.
        historySize = 1;
        % All historic consumptions.
        historyConsumption = 0;
        % All historic deviations.
        historyDeviation = 0;
        % All historic time stamps for consumptions and deviations.
        historyTime = 0;
        
        % Name of the house for S2Sim Connection.
        houseName;
        % OpenDSS Manager connection over S2Sim.
        openDSSConnection;
        
        % Consumption figure axes for direct GUI connection.
        consumptionAxes;
        % Deviation figure axes for direct GUI connection.
        deviationAxes;
    end
    
    methods( Static )
        % GETMAINGRIDSUPPLY Static method to return the single global
        % utility grid supply.
        function mainGridSupplyHandle = GetMainGridSupply()
            persistent mainGridSupplyObject;
            if isempty( mainGridSupplyObject ) || ~isvalid( mainGridSupplyObject )
               mainGridSupplyObject = GridSupply();
            end
            mainGridSupplyHandle = mainGridSupplyObject;
        end
        
        % GETOPENDSSCONNECTION Returns the single instance of the S2Sim
        % OpenDSS connection.
        function openDSSConnectionHandle = GetOpenDSSConnection()
            persistent openDSSConnection;
            if isempty( openDSSConnection ) || ~isvalid( openDSSConnection )
               if exist( 'OpenDSSManager', 'class' )
                  openDSSConnection = OpenDSSManager();
               else
                   openDSSConnection = [];
               end
            end
            openDSSConnectionHandle = openDSSConnection;
        end
        
        % RESETMAINGRIDHISTORY Used to reset the history of the utility
        % grid supply, not the individual grid supplies.
        function ResetMainGridHistory()
            GetMainGridSupply().historyConsumption = 0;
            GetMainGridSupply().historyDeviation = 0;
            GetMainGridSupply().historyTime = 0;
            GetMainGridSupply().historySize = 1;
        end
    end
    
    methods
        % LOADOBJ Overloaded Matlab function to load from a saved file.
        function this = loadobj( obj )
            this = GridSupply();
            this.houseName = obj.houseName;
        end
        
        % SAVEOBJ Overloaded Matlab function to save to a file.
        function savedObj = saveobj( this )
            savedObj.houseName = this.houseName;
            savedObj.historySize = this.historySize;
            savedObj.historyConsumption = this.historyConsumption;
            savedObj.historyDeviation = this.historyDeviation;
            savedObj.historyTime = this.historyTime;
        end
        
        % GRIDSUPPLY Constructor for the grid supply.
        function this = GridSupply()
            this.openDSSConnection = this.GetOpenDSSConnection();
        end
        
        % RECORDHISTORY Records a single snapshot into the history
        % database. The current consumption is used for voltage deviation
        % calculations and then stored into the database.
        function RecordHistory( this )
            if ~isempty( this.openDSSConnection )
                if this ~= this.GetMainGridSupply()
                    this.openDSSConnection.SetWattage( this.houseName, this.currentConsumption / 1000 );
                    this.openDSSConnection.RunFor( 1 );
                    deviation = 100 * this.openDSSConnection.GetVoltageDeviation( this.houseName );
                else
                    deviation = 100 * this.openDSSConnection.GetWorstVoltageDeviation();
                end
            else
                deviation = nan;
            end
            this.historySize = this.historySize + 1;
            this.historyConsumption( this.historySize ) = this.currentConsumption;
            this.historyDeviation( this.historySize ) = deviation;
            this.historyTime( this.historySize ) = HomeSimEventScheduler.GetScheduler().GetTime();
            if this.historyTime( this.historySize ) <= this.historyTime( this.historySize - 1 )
                this.historyTime( this.historySize ) = this.historyTime( this.historySize - 1 ) + 10^-4;
            end
            this.PlotHistory();
        end
        
        % PLOTHISTORY Plots the currently stored history to the given axes.
        function PlotHistory( this )
            if Logger.GetLogger().DrawCheck() || ~Logger.GetLogger().IsSimulating()
                if ~isempty( this.consumptionAxes )
                    stairs( this.consumptionAxes, this.historyTime / ( 24 * 3600 ), this.historyConsumption );
                    datetick( this.consumptionAxes, 'x' );
                    xlabel( this.consumptionAxes, 'Time' );
                    ylabel( this.consumptionAxes, 'Total Consumption (W)' );
                    grid( this.consumptionAxes, 'on' );
                    drawnow();
                end
                if ~isempty( this.deviationAxes )
                    stairs( this.deviationAxes, this.historyTime / ( 24 * 3600 ), this.historyDeviation );
                    datetick( this.deviationAxes, 'x' );
                    xlabel( this.deviationAxes, 'Time' );
                    ylabel( this.deviationAxes, 'Deviation (%)' );
                    grid( this.deviationAxes, 'on' );
                    drawnow();
                end
            end
        end
        
        % GETINTERPOLATEDHISTORY Converts the currently event based history
        % into a regular @intervalSize time axes through interpolation.
        function [consumptions, deviations, regularTime] = GetInterpolatedHistory( this, intervalSize )
            if nargin == 1
                intervalSize = 15 * 60;
            end
            if length( this.historyConsumption ) < 2
                consumptions = [];
                deviations = [];
                regularTime = [];
            else
                minTime = min( this.historyTime );
                maxTime = max( this.historyTime );
                regularTime = minTime:intervalSize:maxTime;
                consumptions = interp1(this.historyTime,this.historyConsumption,regularTime);
                deviations = interp1(this.historyTime,this.historyDeviation,regularTime);
            end
        end
                
        % USEGRIDSUPPLY Adds to the current consumption.
        function UseGridSupply( this, amount )
            this.currentConsumption = this.currentConsumption + amount;
            this.RecordHistory();
            if this ~= this.GetMainGridSupply()
                this.GetMainGridSupply().UseGridSupply( amount );
            end
        end
        
        % RELEASEGRIDSUPPLY Removes from the current consumption.
        function ReleaseGridSupply( this, amount )
            this.currentConsumption = this.currentConsumption - amount;
            this.RecordHistory();
            if this ~= this.GetMainGridSupply()
                this.GetMainGridSupply().ReleaseGridSupply( amount );
            end
        end
    end
    
end

