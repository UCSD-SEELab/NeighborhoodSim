classdef ActiveModeValues < uint8
    %ACTIVEMODEVALUES Enumeration for the battery activity modes.
    
    enumeration
        % Battery is Idle
        Idle        (0)
        
        % Battery is charging
        Charging    (1)
        
        % Battery is discharging
        Discharging (2)
    end
    
end

