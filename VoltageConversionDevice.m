classdef VoltageConversionDevice < handle
    %VOLTAGECONVERSIONDEVICE Defines an AC/DC converter.
    
    properties
        % AC conversion inefficiency.
        acRatio;
        
        % DC conversion inefficiency.
        dcRatio;
    end
    
    methods
        % VOLTAGECONVERSIONDEVICE Reads the specs from a file or from an
        % existent voltage conversion device.
        function this = VoltageConversionDevice( input )
            if ischar( input )
                specs = load( input );
                specs = specs.specs;
            elseif isa( input, 'VoltageConversionDevice' )
                specs = input;
            else
                error( 'Unknown constructor input' );
            end
            this.acRatio = specs.acRatio;
            this.dcRatio = specs.dcRatio;
        end
        
        % TODC Converts a given power to DC.
        function results = ToDC( this, currentPower )
            results = currentPower / this.dcRatio;
        end
        
        % TOAC Converts a given power to AC.
        function results = ToAC( this, currentPower )
            results = currentPower / this.acRatio;
        end
        
        % FROMDC Converts a DC power to original value.
        function results = FromDC( this, givenPower )
            results = givenPower * this.dcRatio;
        end
        
        % FROMAC Converts an AC power to the original value.
        function results = FromAC( this, givenPower )
            results = givenPower * this.acRatio;
        end
    end
    
end

