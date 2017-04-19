classdef EnergySourceValues < uint8
    %ENERGYSOURCEVALUES Enumeration for the energy sources available.
    
    enumeration
        % No energy source connected
        None        (-1)
        % Grid is the sole energy source
        Grid        (0)
        % Solar energy is used
        Solar       (1)
        % Home battery is used
        Battery     (2)
        % Individual appliance battery is used
        OwnBattery  (3)
    end
    
    methods
        % ISGREENSOURCE Checks whether a values is green. Currently only
        % solar is green.
        function isGreen = IsGreenSource( this )
            isGreen = false;
            if this == EnergySourceValues.Solar
                isGreen = true;
            end
        end
    end
end

