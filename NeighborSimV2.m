% NEIGHBOSIMV2 This is the main GUI file of the neighborhood simulation
% tool. It creates the outline of the GUI and assigns callbacks for many
% events. This enables a shortcut to create neighborhoods rapidly. Running
% this file is enough to start the GUI. When a simulation is finished in
% the GUI, the results are automatically exported into the workspace.
function NeighborSimV2
clear all;

f = figure( 'Visible', 'on', 'Units', 'normalized', 'Position',[0.1,0.1,0.8,0.8], 'DockControls', 'off', 'MenuBar', 'none', 'Name', 'Neighborhood Simulator', 'NumberTitle', 'off' );
tabGroup = uitabgroup( f, 'Position', [0 0 1 1], 'SelectionChangedFcn', @TabGroupUpdate );

createNeighborTab = uitab( tabGroup, 'Title', 'Create' );
TextHouseNumber = uicontrol( createNeighborTab, 'Style', 'text', 'Units', 'normalized', 'Position', [0.05 0.95 0.9 0.05], 'String', 'Number of Homes:', 'FontSize', 20 );
EditHouseNumber = uicontrol( createNeighborTab, 'Style', 'edit', 'Units', 'normalized', 'Position', [0.05 0.9 0.9 0.05], 'String', '25', 'Value', 25,'FontSize', 20, 'Callback', @EditHouseNumberCallback );
ListAppliances = uicontrol( createNeighborTab, 'Style', 'listbox', 'Units', 'normalized', 'Position', [0.05 0.1 0.4 0.8], 'FontSize', 20 );
ListSelectedAppliances = uicontrol( createNeighborTab, 'Style', 'listbox', 'Units', 'normalized', 'Position', [0.55 0.1 0.4 0.8], 'FontSize', 20 );
ButtonAddAppliance = uicontrol( createNeighborTab, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.45 0.5 0.1 0.4], 'FontSize', 20, 'String', '->', 'Callback', @ButtonAddApplianceCallback );
ButtonRemoveAppliance = uicontrol( createNeighborTab, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.45 0.1 0.1 0.4], 'FontSize', 20, 'String', '<-', 'Callback', @ButtonRemoveApplianceCallback );
ButtonProbabilityTab = uicontrol( createNeighborTab, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.05 0 0.9 0.1], 'FontSize', 20, 'String', 'Next...', 'Callback', @ButtonProbabilityTabCallback );

applianceListFile = load('applianceList.mat');
ListAppliances.String = applianceListFile.applianceList;

neighborProbabilityTab = uitab( tabGroup, 'Title', 'Probabilities' );
TextApplianceNameList = uicontrol( 'Visible', 'off' );
EditApplianceNameList = uicontrol( 'Visible', 'off' );
SliderApplianceNameList = uicontrol( 'Visible', 'off' );
TextSolarProbability = uicontrol( neighborProbabilityTab, 'Style', 'text', 'Units', 'normalized', 'Position', [0.05 0.1 0.1 0.1], 'String', 'Solar Panel Distribution:', 'FontSize', 20 );
EditSolarProbability = uicontrol( neighborProbabilityTab, 'Style', 'edit', 'Units', 'normalized', 'Position', [0.2 0.1 0.1 0.1], 'String', '0.9', 'Value', 0.9, 'FontSize', 20, 'Callback', @EditSolarProbabilityCallback );
TextSolarScale = uicontrol( neighborProbabilityTab, 'Style', 'text', 'Units', 'normalized', 'Position', [0.3 0.1 0.1 0.1], 'String', 'Scale:', 'FontSize', 20 );
EditSolarScale = uicontrol( neighborProbabilityTab, 'Style', 'edit', 'Units', 'normalized', 'Position', [0.4 0.1 0.1 0.1], 'String', '1', 'Value', 1, 'FontSize', 20, 'Callback', @EditSolarScaleCallback );
TextShiftRandomization = uicontrol( neighborProbabilityTab, 'Style', 'text', 'Units', 'normalized', 'Position', [0.55 0.1 0.2 0.1], 'String', 'Start Time Distribution:', 'FontSize', 20 );
PopupShiftRandomization = uicontrol( neighborProbabilityTab, 'Style', 'popupmenu', 'Units', 'normalized', 'Position', [0.75 0.1 0.2 0.1], 'FontSize', 14 );
ButtonCreateNeighborhood = uicontrol( neighborProbabilityTab, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.05 0 0.9 0.1], 'FontSize', 20, 'String', 'Create Neighborhood!', 'Callback', @ButtonCreateNeighborhoodCallback );
PopupShiftRandomization.String = {'None', 'Gauss 30 min', 'Gauss 60 min', 'Gauss 90 min', 'Uniform 30 min', 'Uniform 60 min', 'Uniform 90 min'};

neighborhoodSummaryTab = uitab( tabGroup, 'Title', 'Summary' );
TextHouseList = uicontrol( neighborhoodSummaryTab, 'Style', 'text', 'Units', 'normalized', 'Position', [0.05 0.9 0.4 0.05], 'String', 'House List:', 'FontSize', 20 );
ListHouses = uicontrol( neighborhoodSummaryTab, 'Style', 'listbox', 'Units', 'normalized', 'Position', [0.05 0.1 0.4 0.79], 'FontSize', 20, 'Callback', @ListHousesCallback );
TextHouseApplianceList = uicontrol( neighborhoodSummaryTab, 'Style', 'text', 'Units', 'normalized', 'Position', [0.55 0.9 0.4 0.05], 'String', 'Appliance List:', 'FontSize', 20 );
ListHouseAppliances = uicontrol( neighborhoodSummaryTab, 'Style', 'listbox', 'Units', 'normalized', 'Position', [0.55 0.4 0.4 0.49], 'FontSize', 20 );
PopupAppliance = uicontrol( neighborhoodSummaryTab, 'Style', 'popupmenu', 'Units', 'normalized', 'Position', [0.55 0.3 0.4 0.1], 'FontSize', 14 );
ButtonInstallAppliance = uicontrol( neighborhoodSummaryTab, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.55 0.2 0.2 0.1], 'FontSize', 20, 'String', 'Install', 'Callback', @ButtonInstallApplianceCallback );
ButtonUninstallAppliance = uicontrol( neighborhoodSummaryTab, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.75 0.2 0.2 0.1], 'FontSize', 20, 'String', 'Remove', 'Callback', @ButtonUninstallApplianceCallback );
CheckSolarConnected = uicontrol( neighborhoodSummaryTab, 'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.55 0.1 0.2 0.1], 'FontSize', 20, 'String', 'Solar?', 'Callback', @CheckSolarConnectedCallback );
PopupBattery = uicontrol( neighborhoodSummaryTab, 'Style', 'popupmenu', 'Units', 'normalized', 'Position', [0.75 0.1 0.2 0.1], 'FontSize', 14, 'String', 'None', 'Callback', @PopupBatteryCallback );
ButtonSimulateNeighborhood = uicontrol( neighborhoodSummaryTab, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.05 0 0.9 0.1], 'FontSize', 20, 'String', '!RUN!', 'Callback', @ButtonSimulateNeighborhoodCallback );
PopupAppliance.String = applianceListFile.applianceList;

resultsTab = uitab( tabGroup, 'Title', 'Results' );
AxesTotalConsumption = axes( 'parent', resultsTab, 'Units', 'normalized', 'Position', [0.1 0.2 0.35 0.7], 'XGrid', 'on', 'YGrid', 'on', 'ButtonDownFcn', @FigureClickCallback );
xlabel(AxesTotalConsumption, 'Time');
datetick(AxesTotalConsumption, 'x');
ylabel(AxesTotalConsumption, 'Consumption (W)');
AxesDeviation = axes( 'parent', resultsTab, 'Units', 'normalized', 'Position', [0.55 0.2 0.35 0.7], 'XGrid', 'on', 'YGrid', 'on', 'ButtonDownFcn', @FigureClickCallback );
xlabel(AxesDeviation, 'Time');
datetick(AxesDeviation, 'x');
ylabel(AxesTotalConsumption, 'Deviation (%)');
PopupHouseSelection = uicontrol( resultsTab, 'Style', 'popupmenu', 'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.05], 'FontSize', 14, 'String', 'None', 'Callback', @PopupHouseSelectionCallback );

optionsTab = uitab( tabGroup, 'Title', 'Options' );
CheckLog = uicontrol( optionsTab, 'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.05 0.9 0.9 0.1], 'FontSize', 20, 'String', 'Console Logs Enabled', 'Callback', @CheckLogCallback );
CheckLogCallback();
CheckDrawNow = uicontrol( optionsTab, 'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.05 0.8 0.9 0.1], 'FontSize', 20, 'String', 'Interactive Simulation Result Enabled', 'Callback', @CheckDrawNowCallback );
ButtonSaveNeighborhood = uicontrol( optionsTab, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.05 0.7 0.9 0.1], 'FontSize', 20, 'String', 'Save Neighborhood', 'Callback', @ButtonSaveNeighborhoodCallback );
ButtonLoadNeighborhood = uicontrol( optionsTab, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.05 0.6 0.9 0.1], 'FontSize', 20, 'String', 'Load Neighborhood', 'Callback', @ButtonLoadNeighborhoodCallback );
CheckDrawNowCallback();

% The main neighborhood object.
myNeighborhood = Neighborhood();
dummyGridSupply = GridSupply();
dummyGridSupply.GetMainGridSupply().consumptionAxes = AxesTotalConsumption;
dummyGridSupply.GetMainGridSupply().deviationAxes = AxesDeviation;

    function EditHouseNumberCallback( source, ~ )
        source.Value = str2double( source.String );
        numberOfHouses = min( max( source.Value, 1 ), 25 );
        source.Value = numberOfHouses;
        source.String = num2str( source.Value );
    end

    function ButtonAddApplianceCallback( ~, ~ )
        if ~isempty( ListAppliances.String )
            selectedAppliance = ListAppliances.String{ ListAppliances.Value };
            ListSelectedAppliances.String{end + 1} = selectedAppliance;
            ListAppliances.String( ListAppliances.Value ) = [];
            ListAppliances.Value = min( max( ListAppliances.Value, 1 ), length( ListAppliances.String ) );
            ListSelectedAppliances.Value = min( max( ListSelectedAppliances.Value, 1 ), length( ListSelectedAppliances.String ) );
        end
    end

    function ButtonRemoveApplianceCallback( ~, ~ )
        if ~isempty( ListSelectedAppliances.String )
            selectedAppliance = ListSelectedAppliances.String{ ListSelectedAppliances.Value };
            ListAppliances.String{end + 1} = selectedAppliance;
            ListSelectedAppliances.String( ListSelectedAppliances.Value ) = [];
            ListSelectedAppliances.Value = min( max( ListSelectedAppliances.Value, 1 ), length( ListSelectedAppliances.String ) );
            ListAppliances.Value = min( max( ListAppliances.Value, 1 ), length( ListAppliances.String ) );
        end
    end

    function ButtonProbabilityTabCallback( ~, ~ )
        tabGroup.SelectedTab = neighborProbabilityTab;
        NeighborProbabilityTabUpdate();
    end

    function TabGroupUpdate( ~, eventData )
        if eventData.NewValue == neighborProbabilityTab
            NeighborProbabilityTabUpdate();
        elseif eventData.NewValue == neighborhoodSummaryTab
            NeighborhoodSummaryTabUpdate();
        end
    end

    function NeighborProbabilityTabUpdate()
        numberOfAppliances = length( ListSelectedAppliances.String );
        delete(TextApplianceNameList);
        delete(EditApplianceNameList);
        delete(SliderApplianceNameList);
        if numberOfAppliances == 0
            return;
        end
        
        positionLeft = 0.05 * ones( numberOfAppliances, 1 );
        positionBottom = linspace( 0.2, 0.9, numberOfAppliances + 1 )';
        thickness = ( positionBottom( 2 ) - positionBottom( 1 ) );
        if thickness > 0.1
            thickness = 0.1;
            positionBottom = 0.9:(-0.1):0.2;
        end
        positionBottom( ( numberOfAppliances + 1 ):end ) = [];
        if isrow( positionBottom )
            positionBottom = positionBottom';
        end
        positionWidth = 0.25 * ones( numberOfAppliances, 1 );
        positionHeight = thickness * ones( numberOfAppliances, 1 );
        
        positionVectorText = [positionLeft, positionBottom, positionWidth, positionHeight];
        positionVectorEdit = [positionLeft + 0.3, positionBottom, positionWidth, positionHeight];
        positionVectorSlider = [positionLeft + 0.6, positionBottom, positionWidth, positionHeight];
        
        for appIndex = 1:numberOfAppliances
            TextApplianceNameList( appIndex ) = uicontrol( neighborProbabilityTab, 'Style', 'text', 'Units', 'normalized', 'Position', positionVectorText( appIndex, : ), 'String', ListSelectedAppliances.String{ appIndex }, 'FontSize', 14 );
            if strcmp( ListSelectedAppliances.String{ appIndex }, 'HVAC' )
                value = 1;
            elseif strcmp( ListSelectedAppliances.String{ appIndex }, 'EVLevel1' )
                value = 0.05;
            elseif strcmp( ListSelectedAppliances.String{ appIndex }, 'EVLevel2' )
                value = 0.05;
            else
                value = 0.9;
            end
            EditApplianceNameList( appIndex ) = uicontrol( neighborProbabilityTab, 'Style', 'edit', 'Units', 'normalized', 'Position', positionVectorEdit( appIndex, : ), 'String', num2str(value), 'Value', value, 'FontSize', 14, 'Callback', @ProbabilityEditCallback );
            SliderApplianceNameList( appIndex ) = uicontrol( neighborProbabilityTab, 'Style', 'slider', 'Units', 'normalized', 'Position', positionVectorSlider( appIndex, : ), 'Value', value, 'FontSize', 20, 'Max', 1, 'Min', 0, 'Callback', @ProbabilitySliderCallback );
        end
    end

    function ProbabilityEditCallback( source, ~ )
        source.Value = str2double( source.String );
        probValue = min( max( source.Value, 0 ), 1 );
        source.Value = probValue;
        SliderApplianceNameList( source == EditApplianceNameList ).Value = probValue;
        source.String = num2str( source.Value );
    end

    function ProbabilitySliderCallback( source, ~ )
        probValue = min( max( source.Value, 0 ), 1 );
        source.Value = probValue;
        EditApplianceNameList( source == SliderApplianceNameList ).String = num2str( probValue );
        EditApplianceNameList( source == SliderApplianceNameList ).Value = probValue;
    end

    function ButtonCreateNeighborhoodCallback( ~, ~ )
        delete( myNeighborhood );
        HomeSimEventScheduler.GetScheduler().ResetScheduler();
        numberOfAppliances = length( ListSelectedAppliances.String );
        if numberOfAppliances > 0
            neighborhoodParameters{ 2 * numberOfAppliances } = {};
            for appIndex = 1:numberOfAppliances
                neighborhoodParameters{ 2*appIndex - 1 } = TextApplianceNameList( appIndex ).String;
                neighborhoodParameters{ 2*appIndex } = SliderApplianceNameList( appIndex ).Value;
            end   
        else
            neighborhoodParameters = {};
        end

        myNeighborhood = Neighborhood.CreateProbabilisticNeighborhood( EditHouseNumber.Value, neighborhoodParameters{:} );
        myNeighborhood.AddProbabilisticSolarPanels( EditSolarProbability.Value, EditSolarScale.Value );
        houseNamesFile = load( 'houseNames' );
        houseNames = houseNamesFile.houseNames;
        myNeighborhood.SetHouseNames( houseNames );
        switch PopupShiftRandomization.Value
            case 1
                myNeighborhood.RandomizeStartingTimesGauss( 0 );
            case 2
                myNeighborhood.RandomizeStartingTimesGauss( 30 * 60 );
            case 3
                myNeighborhood.RandomizeStartingTimesGauss( 60 * 60 );
            case 4
                myNeighborhood.RandomizeStartingTimesUniform( 30 * 60 );
            case 5
                myNeighborhood.RandomizeStartingTimesUniform( 60 * 60 );
            case 6
                myNeighborhood.RandomizeStartingTimesUniform( 90 * 60 );
        end
        
        tabGroup.SelectedTab = neighborhoodSummaryTab;
        NeighborhoodSummaryTabUpdate();
    end

    function EditSolarProbabilityCallback( source, ~ )
        source.Value = str2double( source.String );
        probValue = min( max( source.Value, 0 ), 1 );
        source.Value = probValue;
        source.String = num2str( source.Value );
    end

    function EditSolarScaleCallback( source, ~ )
        source.Value = str2double( source.String );
        probValue = max( source.Value, 0 );
        source.Value = probValue;
        source.String = num2str( source.Value );
    end
        
    function ListHousesCallback( ~, ~ )
        if isempty( ListHouses.Value )
            return;
        end
        houseIndex = ListHouses.Value;
        numberOfAppliances = myNeighborhood.houseList( houseIndex ).numberOfLoads;
        houseApplianceList = {};
        if numberOfAppliances == 0
            ListHouseAppliances.String = {};
        else
            houseApplianceList{ numberOfAppliances } = '';
            for appIndex = 1:numberOfAppliances
                houseApplianceList{appIndex} = myNeighborhood.houseList( houseIndex ).loadList( appIndex ).applianceName;
            end
        end
        ListHouseAppliances.String = houseApplianceList;
        
        if myNeighborhood.houseList( houseIndex ).numberOfGenerators > 0
            CheckSolarConnected.Value = 1;
        else
            CheckSolarConnected.Value = 0;
        end
        
        batteryListFile = load('batteryList');
        batteryList = batteryListFile.batteryList;
        PopupBattery.String = { 'None', batteryList{:} };
        
        if myNeighborhood.houseList( houseIndex ).numberOfHybrids > 0
            for batteryIndex = 1:length( PopupBattery.String )
                if strcmp( PopupBattery.String{batteryIndex}, myNeighborhood.houseList( houseIndex ).hybridList( 1 ).batteryName )
                    PopupBattery.Value = batteryIndex;
                    break;
                end
            end
        else
            PopupBattery.Value = 1;
        end
    end

    function NeighborhoodSummaryTabUpdate()
        numberOfHomes = myNeighborhood.numberOfHomes;
        if numberOfHomes == 0
            houseNames = {};
        else
            houseNames{numberOfHomes} = '';
            for houseIndex = 1:numberOfHomes
                houseNames{houseIndex} = ['House ' num2str(houseIndex)];
            end
        end
        ListHouses.String = houseNames;
        PopupHouseSelection.String = [ houseNames, 'Total' ];
        PopupHouseSelection.Value = length( [ houseNames, 'Total' ] );
        ListHousesCallback();
    end

    function CheckSolarConnectedCallback( source, ~ )
        if isempty( ListHouses.Value )
            return;
        end
        houseIndex = ListHouses.Value;
        if source.Value == 0
            delete( myNeighborhood.houseList( houseIndex ).generatorList(1) );
            myNeighborhood.houseList( houseIndex ).numberOfGenerators = 0;
        else
            solarPanel = SolarPanel();
            myNeighborhood.houseList( houseIndex ).InstallGenerators( solarPanel );
        end
    end

    function PopupBatteryCallback( source, ~ )
        if isempty( ListHouses.Value )
            return;
        end
        houseIndex = ListHouses.Value;
        if source.Value > 1
            newBattery = Battery( source.String{ source.Value } );
            myNeighborhood.houseList( houseIndex ).InstallHybrids( newBattery );
        else
            delete( myNeighborhood.houseList( houseIndex ).hybridList(1) );
            myNeighborhood.houseList( houseIndex ).numberOfHybrids = 0;
        end
    end

    function ButtonInstallApplianceCallback( ~, ~ )
        if isempty( ListHouses.Value )
            return;
        end
        houseIndex = ListHouses.Value;
        
        selectedAppliance = PopupAppliance.String{ PopupAppliance.Value };
        newAppliance = Appliance( selectedAppliance );
        myNeighborhood.houseList( houseIndex ).InstallAppliances( newAppliance );
        ListHousesCallback();
    end

    function ButtonUninstallApplianceCallback( ~, ~ )
        if isempty( ListHouses.Value )
            return;
        end
        houseIndex = ListHouses.Value;
        if isempty( ListHouseAppliances.Value )
            return;
        end
        appIndex = ListHouseAppliances.Value;
        myNeighborhood.houseList( houseIndex ).RemoveAppliance( appIndex );
        ListHousesCallback();
    end

    function ButtonSimulateNeighborhoodCallback( ~, ~ )
        tabGroup.SelectedTab = resultsTab;
        dummyGridSupply.ResetMainGridHistory();
        Logger.GetLogger().StartSimulation();
        HomeSimEventScheduler.GetScheduler().RunSimulation( 24*60*60 );
        Logger.GetLogger().StopSimulation();
        
        [consumption, deviation, timestamps] = GridSupply.GetMainGridSupply().GetInterpolatedHistory( 60 );
        stairs( AxesTotalConsumption, timestamps / ( 24 * 3600 ), consumption );
        datetick( AxesTotalConsumption, 'x' );
        xlabel( AxesTotalConsumption, 'Time' );
        ylabel( AxesTotalConsumption, 'Consumption (W)' );
        grid( AxesTotalConsumption, 'on' );
        AxesTotalConsumption.ButtonDownFcn = @FigureClickCallback;
        stairs( AxesDeviation, timestamps / ( 24 * 3600 ), deviation );
        datetick( AxesDeviation, 'x' );
        xlabel( AxesDeviation, 'Time' );
        ylabel( AxesDeviation, 'Deviation (%)' );
        grid( AxesDeviation, 'on' );
        AxesDeviation.ButtonDownFcn = @FigureClickCallback;
        HomeSimEventScheduler.GetScheduler().ResetScheduler();
        resultValues = [consumption; deviation; timestamps];
        assignin( 'base', 'resultValues', resultValues );
    end

    function PopupHouseSelectionCallback( source, ~ )
        if source.Value > myNeighborhood.numberOfHomes
            [consumption, deviation, timestamps] = GridSupply.GetMainGridSupply().GetInterpolatedHistory( 60 );
        else
            [consumption, deviation, timestamps] = myNeighborhood.houseList( source.Value ).gridSupply.GetInterpolatedHistory( 60 );
        end
        stairs( AxesTotalConsumption, timestamps / ( 24 * 3600 ), consumption );
        datetick( AxesTotalConsumption, 'x' );
        xlabel( AxesTotalConsumption, 'Time' );
        ylabel( AxesTotalConsumption, 'Consumption (W)' );
        grid( AxesTotalConsumption, 'on' );
        AxesTotalConsumption.ButtonDownFcn = @FigureClickCallback;
        stairs( AxesDeviation, timestamps / ( 24 * 3600 ), deviation );
        datetick( AxesDeviation, 'x' );
        xlabel( AxesDeviation, 'Time' );
        ylabel( AxesDeviation, 'Deviation (%)' );
        grid( AxesDeviation, 'on' );
        AxesDeviation.ButtonDownFcn = @FigureClickCallback;
    end

    function CheckLogCallback( ~, ~ )
        if CheckLog.Value == 1
            Logger.GetLogger().EnableLogs();
        else
            Logger.GetLogger().DisableLogs();
        end
    end

    function CheckDrawNowCallback( ~, ~ )
        if CheckDrawNow.Value == 1
            Logger.GetLogger().EnableImmediateDraw();
        else
            Logger.GetLogger().DisableImmediateDraw();
        end
    end

    function ButtonSaveNeighborhoodCallback( ~, ~ )
        fileName = uiputfile('*.mat','Save Neighborhood','myNeighborhood.mat');
        save( fileName, 'myNeighborhood' );
    end

    function ButtonLoadNeighborhoodCallback( ~, ~ )
        fileName = uigetfile('*.mat','Load Neighborhood','myNeighborhood.mat');
        myNeighborhoodFile = load( fileName, 'myNeighborhood' );
        delete( myNeighborhood );
        myNeighborhood = myNeighborhoodFile.myNeighborhood;
        myNeighborhood.ReinitializeStartingEvents();
        tabGroup.SelectedTab = neighborhoodSummaryTab;
        NeighborhoodSummaryTabUpdate();
    end

    function FigureClickCallback( ~, ~ )
        [consumption, deviation, timestamps] = GridSupply.GetMainGridSupply().GetInterpolatedHistory( 60 );
        resultValues = [consumption; deviation; timestamps];
        assignin( 'base', 'resultValues', resultValues );
    end
end