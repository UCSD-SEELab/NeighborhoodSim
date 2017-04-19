classdef OpenDSSManager < handle
    %OpenDSSManager Manages the interface with COM server
    %   This class is provided to abstract the COM server interface for
    %   OpenDSS control.
    
    properties(SetAccess='private', GetAccess='public')
        m_circuitFilePath = 'C:\Users\Alper\Documents\MATLAB\MyCkt5.DSS';
        
        m_object
        m_circuit
        m_text
        m_solution
        m_loads
        
        m_tcpIp
        m_running
    end
    
    methods(Access='private')
        function result=GiveCommand(obj,command)
            obj.m_text.command = command;
            result = obj.m_text.result;
        end
    end
    
    methods
        function obj=OpenDSSManager()
            obj.m_object = actxserver('OpenDSSEngine.DSS');
            obj.m_object.Start(0);
            obj.m_circuit = obj.m_object.ActiveCircuit;
            obj.m_text = obj.m_object.Text;
            obj.CompileCircuit(obj.m_circuitFilePath);
            obj.m_solution = obj.m_circuit.Solution;
            obj.m_loads = obj.m_circuit.Loads;
            obj.m_running = 0;
            ipAddress = load('s2SimAddress.mat');
            disp(ipAddress);
            obj.m_tcpIp = tcpip(ipAddress.s2SimAddress, 26997, 'NetworkRole', 'client');
            obj.m_tcpIp.Timeout = Inf;
            
            obj.m_solution.Mode = 16;
            obj.m_solution.StepSize = 1;
            obj.m_solution.Number = 1;
        end
        function result=LoadExists(obj,objectName)
            result = 0;
            iLoad = obj.m_loads.First;
            while iLoad > 0
                if strcmp( objectName, obj.m_loads.Name )
                    result = 1;
                    break;
                end
                obj.m_loads.Name;
                iLoad = obj.m_loads.Next;
            end
        end
        function Run( obj )
            obj.m_running = 1;
            while ( obj.m_running )
                if strcmp( obj.m_tcpIp.Status, 'closed' )
                    connectionWaiting = 1;
                    while connectionWaiting && obj.m_running
                        try
                            fopen( obj.m_tcpIp );
                            connectionWaiting = 0;
                            disp( 'Connected!' );
                            obj.m_tcpIp.Timeout = 2000;
                        catch
                            disp( 'No connection, retrying...' );
                            obj.m_tcpIp.Timeout = Inf;
                        end
                    end
                end
                while ( obj.m_running && ~connectionWaiting )
                    sizeArray = fread( obj.m_tcpIp, 4 );
                    if isempty( sizeArray )
                        disp( 'Nothing received' );
                        connectionWaiting = 1;
                        fclose( obj.m_tcpIp );
                        break;
                    end
                    messageSize = sizeArray(1)*2^24 + sizeArray(2)*2^16 + sizeArray(3)*2^8 + sizeArray(4)
                    if messageSize >= 4
                    message = fread( obj.m_tcpIp, messageSize - 4 );
                    if size( message ) > 0
                        obj.ProcessMessage( message );
                    end
                    end
                end
            end
        end
        function Stop( obj )
            obj.m_running = 0;
            fclose( obj.m_tcpIp );
            disp( 'OpenDSS Stopped' )
        end
        function ProcessMessage( obj, message )
            messageType = message(1)*2^24 + message(2)*2^16 + message(3)*2^8 + message(4);
            if messageType == 1
                'Client Existance Message Received'
                clientName = lower( char( message(5:end)' ) );
                if obj.LoadExists(clientName)
                    clientExistance = [0,0,0,1];
                    disp( [clientName ' Exists'] );
                else
                    clientExistance = [0,0,0,2];
                    disp( [clientName ' Does not exist'] );
                end
                responseMessageType = [0,0,0,2];
                sendingData = [responseMessageType, clientExistance];
                fwrite( obj.m_tcpIp, sendingData );
            elseif messageType == 3
                'Client Set Wattage Message Received'
                wattageValue = Array2Int( message( 5:8 ) );
                wattageValue = wattageValue / 1000;
                clientName = lower( char(message(9:end)') );
                obj.SetWattage( clientName, wattageValue );
            elseif messageType == 4
                'Client Get Wattage Message Received'
                clientName = lower( char(message(5:end)') );
                wattageValue = obj.GetWattage( clientName );
                responseMessageType = [0,0,0,5];
                wattageData = Int2Array( wattageValue );
                sendingData = [responseMessageType, wattageData];
                fwrite( obj.m_tcpIp, sendingData );
            elseif messageType == 6
                disp('Advance Time Step Received');
                obj.RunFor( 1 );
            elseif messageType == 7
                'Client Get Voltage Message Received'
                clientName = lower( char(message(5:end)') );
                voltageValue = mean(abs(obj.GetVoltage( clientName )));
                responseMessageType = [0,0,0,8];
                voltageData = Int2Array( uint32( voltageValue * 32768 ) );
                sendingData = [responseMessageType, voltageData];
                fwrite( obj.m_tcpIp, sendingData );
            elseif messageType == 9
                'Client Get Voltage Deviation Message Received'
                clientName = lower( char(message(5:end)') );
                voltageValue = obj.GetVoltageDeviation( clientName );
                responseMessageType = [0,0,0,10];
                voltageData = Int2Array( uint32( voltageValue * 32768 ) );
                sendingData = [responseMessageType, voltageData];
                fwrite( obj.m_tcpIp, sendingData );
            elseif messageType == 11
                'Client Get Voltage Deviation and Consumption Message Received'
                clientName = lower( char(message(5:end)') );
                voltageValue = obj.GetVoltageDeviation( clientName );
                wattageValue = obj.GetWattage( clientName );
                responseMessageType = [0,0,0,12];
                voltageData = Int2Array( uint32( voltageValue * 32768 ) );
                wattageData = Int2Array( uint32( wattageValue * 1000 ) );
                sendingData = [responseMessageType, voltageData, wattageData];
                fwrite( obj.m_tcpIp, sendingData );
            end
        end
        function result=CompileCircuit(obj,fileName)
            result = obj.GiveCommand(['Compile (' fileName ')']);
        end
        function result=SetStepSize(obj,stepSize)
            obj.m_solution.StepSize = stepSize;
            result = obj.m_solution.StepSize;
        end
        function [runTime]=RunFor(obj,time)
            runNumber = floor( time/obj.m_solution.StepSize );
            for runInstance = 1:runNumber
                obj.m_solution.Solve;
            end
            runTime = runNumber*obj.m_solution.StepSize;
        end
        function obj=SetWattage(obj,loadName,wattage)
            iLoad = obj.m_loads.First;
            while iLoad > 0
                if strcmp( loadName, obj.m_loads.Name )
                    obj.m_loads.kW=wattage;
                    obj.m_loads.kvar = wattage*0.02;
                    break;
                end
                iLoad = obj.m_loads.Next;
            end
        end
        function wattage=GetWattage(obj,loadName)
            iLoad = obj.m_loads.First;
            while iLoad > 0
                if strcmp( loadName, obj.m_loads.Name )
                    wattage = obj.m_loads.kW;
                    return;
                end
                iLoad = obj.m_loads.Next;
            end
            error([loadName ' not found']);
        end
        function voltage=GetVoltage(obj,loadName)
            iLoad = obj.m_loads.First;
            while iLoad > 0
                if strcmp( loadName, obj.m_loads.Name )
                    tempVoltage=obj.m_circuit.ActiveCktElement.Voltages;
                    if numel(tempVoltage) == 6
                    voltage=[tempVoltage(1)+1i*tempVoltage(2),...
                             tempVoltage(3)+1i*tempVoltage(4),...
                             tempVoltage(5)+1i*tempVoltage(6)];
                    return;
                    else
                    voltage=[tempVoltage(1)+1i*tempVoltage(2),...
                             tempVoltage(3)+1i*tempVoltage(4)];  
                    return;
                    end
                end
                iLoad = obj.m_loads.Next;
            end
            error([loadName ' not found']);
        end    
        function [deviation,base]=GetVoltageDeviation(obj,loadName)
            iLoad = obj.m_loads.First;
            loadFound = 0;
            while iLoad > 0
                if strcmp( loadName, obj.m_loads.Name )
                    tempVoltage=obj.m_circuit.ActiveCktElement.Voltages;
                    if numel(tempVoltage) == 6
                        voltage=[tempVoltage(1)+1i*tempVoltage(2),...
                                 tempVoltage(3)+1i*tempVoltage(4),...
                                 tempVoltage(5)+1i*tempVoltage(6)];
                        loadFound = 1;
                         break;
                    else
                        voltage=[tempVoltage(1)+1i*tempVoltage(2),...
                                 tempVoltage(3)+1i*tempVoltage(4)]; 
                         loadFound = 1;
                         break;
                    end
                end
                iLoad = obj.m_loads.Next;
            end
            if loadFound
                base = obj.m_loads.kV;
                scale = 1;
                if obj.m_loads.IsDelta
                    scale = sqrt(3);
                end
                if obj.m_circuit.ActiveCktElement.NumPhases == 1
                    deviation = 1 - abs(voltage(1))*scale/( obj.m_loads.kV * 1000 );
                else
                    if obj.m_loads.IsDelta
                        voltage = [voltage(1) - voltage(2), voltage(2) - voltage(3), voltage(3) - voltage(1)];
                    end
                    deviation = 1 - mean(abs(voltage))*scale/( obj.m_loads.kV * 1000 );
                end
            else
                error([loadName ' not found']);
            end
        end  
        function [worstDeviation,base]=GetWorstVoltageDeviation(obj)
            iLoad = obj.m_loads.First;
            worstDeviation = 0;
            while iLoad > 0
                tempVoltage=obj.m_circuit.ActiveCktElement.Voltages;
                if numel(tempVoltage) == 6
                    voltage=[tempVoltage(1)+1i*tempVoltage(2),...
                             tempVoltage(3)+1i*tempVoltage(4),...
                             tempVoltage(5)+1i*tempVoltage(6)];
                else
                    voltage=[tempVoltage(1)+1i*tempVoltage(2),...
                             tempVoltage(3)+1i*tempVoltage(4)]; 
                end
                base = obj.m_loads.kV;
                scale = 1;
                if obj.m_loads.IsDelta
                    scale = sqrt(3);
                end
                if obj.m_circuit.ActiveCktElement.NumPhases == 1
                    deviation = 1 - abs(voltage(1))*scale/( obj.m_loads.kV * 1000 );
                else
                    if obj.m_loads.IsDelta
                        voltage = [voltage(1) - voltage(2), voltage(2) - voltage(3), voltage(3) - voltage(1)];
                    end
                    deviation = 1 - mean(abs(voltage))*scale/( obj.m_loads.kV * 1000 );
                end
                if abs( worstDeviation ) < abs( deviation )
                    worstDeviation = deviation;
                end
                iLoad = obj.m_loads.Next;
            end
        end  
        function current=GetCurrent(obj,loadName)
            iLoad = obj.m_loads.First;
            while iLoad > 0
                if strcmp( loadName, obj.m_loads.Name )
                    tempCurrent=obj.m_circuit.ActiveCktElement.Currents;
                    current=[tempCurrent(1)+1i*tempCurrent(2),...
                             tempCurrent(3)+1i*tempCurrent(4),...
                             tempCurrent(5)+1i*tempCurrent(6)];
                    return;
                end
                iLoad = obj.m_loads.Next;
            end
            error([loadName ' not found']);
        end
        function power=GetPower(obj,loadName)
            iLoad = obj.m_loads.First;
            while iLoad > 0
                if strcmp( loadName, obj.m_loads.Name )
                    tempPower=obj.m_circuit.ActiveCktElement.Powers;
                    power=[tempPower(1)+1i*tempPower(2),...
                           tempPower(3)+1i*tempPower(4),...
                           tempPower(5)+1i*tempPower(6)];
                    return;
                end
                iLoad = obj.m_loads.Next;
            end
            error([loadName ' not found']);
        end
        function OpenLoad(obj,loadName)
            obj.GiveCommand(['open Line.T' loadName(2) loadName]);
        end
    end    
end

