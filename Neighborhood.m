classdef Neighborhood < handle
    %NEIGHBORHOOD This class contains multiple homes with fast
    % configuration capabilities.
    
    properties
        % Number of houses in the neighborhood.
        numberOfHomes = 0;
        
        % List of houses.
        houseList = Home();
    end
    
    methods
        % NEIGHBORHOOD Empty constructor.
        function this = Neighborhood()
        end
        
        % ADDPROBABILISTICSOLARPANELS Adds solar panels to houses by a
        % uniform random variable.
        function AddProbabilisticSolarPanels( this, penetrationValue, scaleValue )
            if nargin == 2
                scaleValue = 1;
            end
            for homeIndex = 1:this.numberOfHomes
                if rand() <= penetrationValue
                    solarPanel = SolarPanel();
                    solarPanel.scaleValue = scaleValue;
                    this.houseList( homeIndex ).InstallGenerators( solarPanel );
                end
            end
        end
        
        % SETHOUSENAMES Sets the names of the houses in the neighborhood.
        % If the simulation is to be run with S2Sim, these names must match
        % the OpenDSS configuration names.
        function SetHouseNames( this, houseNames )
            for homeIndex = 1:this.numberOfHomes
                this.houseList( homeIndex ).gridSupply.houseName = houseNames{ homeIndex };
            end
            for homeIndex = ( this.numberOfHomes + 1 ):length( houseNames )
                GridSupply.GetOpenDSSConnection().OpenLoad( upper( houseNames{ homeIndex } ) );
            end
        end
        
        % RANDOMIZESTARTINGTIMESGAUSS Randomizes the starting times of the
        % appliances by a Gaussian random variable.
        function RandomizeStartingTimesGauss( this, scaleFactor )
            for homeIndex = 1:this.numberOfHomes
                this.houseList( homeIndex ).RandomizeStartingTimesGauss( scaleFactor );
            end
        end
        
        % RANDOMIZESTARTINGTIMESUNIFORM Randomizes the starting times of
        % the appliances by a uniform random variable.
        function RandomizeStartingTimesUniform( this, scaleFactor )
            for homeIndex = 1:this.numberOfHomes
                this.houseList( homeIndex ).RandomizeStartingTimesUniform( scaleFactor );
            end
        end
        
        % REINITIALIZESTARTINGEVENTS Resets the events of every home.
        function ReinitializeStartingEvents( this )
            for home = this.houseList
                home.ReinitializeStartingEvents();
            end
        end
        
    end
    
    methods ( Static )
        % CREATEPROBABILISTICNEIGHBORHOOD Creates a neighborhood by the
        % given @numberOfHomes and (applianceName, applianceProbability)
        % pairs, that creates a random appliance distribution among the
        % neighborhood.
        function newNeighborhood = CreateProbabilisticNeighborhood( numberOfHomes, varargin )
            if mod(nargin, 2) == 0
                error( 'Input must consist of ApplianceName-Probability pairs' );
            end
            
            newNeighborhood = Neighborhood();
            newNeighborhood.numberOfHomes = numberOfHomes;
            
            for homeIndex = 1:numberOfHomes
                newNeighborhood.houseList(homeIndex) = Home();
                
                for appIndex = 1:( ( nargin - 1 ) / 2 )
                    applianceName = varargin{ 2 * ( appIndex - 1 ) + 1 };
                    applianceProb = varargin{ 2 * appIndex };
                    if rand(1) <= applianceProb
                        newNeighborhood.houseList(homeIndex).InstallAppliances( Appliance( applianceName ) );
                    end
                end
            end
        end
    end
    
end

