classdef sublimeFigure < handle
    %sublimeFigure Easily control plot & subplot layout, figure print size.
    % Requires MATLAB r2017a.
    % Create figures with multiple subplots of the right size for
    % publications. Layout is based on a rectangular matrix, where each
    % subplot can take one or any number of cells. Define exact size to
    % match your publication, font sizes, set precise margins in cm (in).
    % Default properties create a square figure with one axis (plot) of the
    % width suitable for one-column-wide figure in an APS publication.
    %
    % 
    %
    % Designed to run in scripts, so may not respond well to manual
    % resizing in GUI, apps etc.
    %
    % Version: 1.1 (2017-08-21)
    % (C) 2017, M. Sich, The University of Sheffield
    % m.sich@sheffield.ac.uk
    
    properties (SetObservable)
        % Total width of the figure (default 8.6 cm ).
        totalWidth(1,1) double {mustBeNonnegative}        = 8.6
        
        % Total height of the figure (default 8.6 cm).
        totalHeight(1,1) double {mustBeNonnegative}       = 8.6
        
        %
        leftOuterPadding(1,1) double {mustBeNonnegative}  = 1.1
        
        %
        rightOuterPadding(1,1) double {mustBeNonnegative} = 0.1
        
        % single number or 1D array with individual values for each column
        leftPadding(:,1) double {mustBeNonnegative}       = 0
        
        % single number or 1D array with individual values for each column
        rightPadding(:,1) double {mustBeNonnegative}      = 0
        
        %
        topOuterPadding(1,1) double {mustBeNonnegative}   = 0.1
        
        %
        bottomOuterPadding(1,1) double {mustBeNonnegative}= 1.0
        
        % single number or 1D array with individual values for each row
        topPadding(:,1) double {mustBeNonnegative}        = 0
        
        % single number or 1D array with individual values for each row
        bottomPadding(:,1) double {mustBeNonnegative}     = 0
        
        % Number of columns for unit cell array
        numColumns(1,1) double {mustBeNonnegative}        = 1
        
        % Number of rows for unit cell array
        numRows(1,1) double {mustBeNonnegative}           = 1
        
        % 1D array of relative heights of columns, by default is ones.
        rowHeightWeights(:,1) double {mustBeNonnegative,...
            mustBeLessThanOrEqual(rowHeightWeights,1)}    = 1
        
        % 1D array of relative widths of rows, by default is ones.
        colWidthWeights(:,1) double {mustBeNonnegative,...
            mustBeLessThanOrEqual(colWidthWeights,1)}     = 1
        
        % Default font size for labelling features
        defFontSize(1,1) double {mustBePositive}          = 8
        
        % Colour-bar width (default 0.2 cm)
        cBarWidth(1,1) double {mustBeNonnegative}         = 0.2
        
        % Colour-bar padding from the edge of the plot (default 0.1 cm)
        cBarPadding(1,1) double {mustBeNonnegative}       = 0.1
        
        % If true temporarily changes system font size as per defFontSize.
        % Do not use if you have multiple figure windows (not subplots) 
        % and want to have different font size in each of those. 
        enableFontControl(1,1) logical                    = true
    end
    
    properties (SetObservable, AbortSet)
        % Use AbortSet = true to trigger callback listener only if the
        % value of the property has changed, so that assigning the same
        % value twice will only triiger call back on the first instance.
        
        % Default units of all physical dimensions. Can be either 'cm' or
        % 'in'.
        defUnits(1,:) char {mustBeMember(defUnits,{'cm','in'})} = 'cm'
    end
    
    % ====================================================================
   
    properties ( SetAccess = private )
        % Figure handle
        fig
    end

    % ====================================================================
    
    properties ( SetAccess = private, Hidden = true )
        % Calculated automatically
        lop(1,1) double
        rop(1,1) double
        lp(:,1) double
        rp(:,1) double
        cellWidth(1,1) double
        top(1,1) double
        bop(1,1) double
        tp(:,1) double
        bp(:,1) double
        cellHeight(1,1) double
        % structure of subplots' (axis) handles and props: ax, col, row, cSpan,
        % rSpan. Empty by default.
        sfPlots = []
        sysDefFontSize(1,1) double
        propChangeListeners = event.listener.empty
    end
    
    % ====================================================================
    % ====================================================================
    
    methods
        
        function obj = sublimeFigure( varargin )
            % Create a figure based on default or passed in a preset values
            
            % The first and only expected input is the preset string
            if nargin > 0
                preset = varargin{1};
            else
                % If nothing passed through then set to 'default'
                preset = 'default';
            end
            
            % Validate input
            validatestring( preset, {'default', 'presentation', 'tight',...
                'sparse'} );
            
            % Do different settings for different presets
            switch preset
                case 'presentation'
                    obj.totalWidth  = 15;
                    obj.totalHeight = 12;
                    obj.defFontSize = 16;
                    obj.cBarWidth   = 0.5;
                    obj.cBarPadding = 0.2;
                    obj.bottomOuterPadding = 2.1;
                    obj.leftOuterPadding = 2.9;
                case 'tight'
                    obj.leftPadding = 0.05;
                    obj.rightPadding = 0.05;
                    obj.topPadding = 0.05;
                    obj.bottomPadding = 0.05;
                    obj.topOuterPadding = 0.05;
                    obj.rightOuterPadding = 0.05;
                case 'sparse'
                    obj.leftPadding = 1.1;
                    obj.rightPadding = 0;
                    obj.topPadding = 0.1;
                    obj.bottomPadding = 1.0;
                    obj.topOuterPadding = 0;
                    obj.rightOuterPadding = 0.1;  
                    obj.leftOuterPadding = 0;
                    obj.bottomOuterPadding = 0;
                case 'default'
                	% do nothing
                otherwise
                    % Just doublechecking
                	error( 'sublimeFigure screams: Unknown preset "%s"!', preset);
            end
            
            % Set sizes
            obj.setRelativeSizes();
            
            % Creating figure object and setting paper sizes
            obj.fig = figure;
            
            % Need to change default settings since whenever something is
            % plotted in axis, it resets font size...
            if obj.enableFontControl
                obj.sysDefFontSize = get( groot, 'DefaultAxesFontSize' );
                set( groot, 'DefaultAxesFontSize', obj.defFontSize);
            end
            
            % Update figure
            obj.resizeFigure;
            
            % Adding listeners for all public property changes to update
            % figure after any change.
            % Get meta data from the current object instance.
            mco = metaclass(obj);
            % Get an array of struct containing info on all public
            % properties.
            plist = mco.PropertyList;
            for i = 1 : length(plist)
                % Add a listener only if the property can be 'listened'.
                % All of those impact figure sizing, so run resizeFigure in
                % each case.
                if plist(i).SetObservable == true
                    if string(plist(i).Name) == 'defUnits'
                        % Only if units are changed call a recalculate
                        % function instead of resize. Otherwise the actual
                        % figure size have changed.
                        % NB: Name property of a meta.class object is char
                        % array, not a string!
                        obj.propChangeListeners(end+1) = addlistener(...
                            obj, plist(i).Name,'PostSet', @obj.changeUnits);
                    else
                        obj.propChangeListeners(end+1) = addlistener(...
                            obj, plist(i).Name,'PostSet', @obj.resizeFigure);                        
                    end
                end
            end
        end
        
        % ================================================================
        
        function delete(obj)
            % Destructor
            
            % Reset default font settings 
            if obj.enableFontControl
                set( groot, 'DefaultAxesFontSize', obj.sysDefFontSize);
            end
        end
        
        % ================================================================
        
        function [ ax, axID ] = subPlot( obj, cCol, cRow, varargin )
            %(cCol,cRow) creates a subplot at unit cell at cCol column and
            % cRow row. Returns axes handle. Optional cSpan and rSpan in
            % varargin to account for having a multi-cell plot. By default
            % these are set to 1.
            
            % Validating inputs
            validateattributes( cCol, {'numeric'},...
                {'integer', 'nonnegative'});
            validateattributes( cRow, {'numeric'},...
                {'integer', 'nonnegative'});
            if cCol > obj.numColumns
                warnTxt = ['sublimeFigure warns: attempting to create'...
                    'a subplot starting at ' int2str(cCol) ' column may result'...
                    ' in unexpected figure appearance. Max columns is set'...
                    ' to ' int2str(obj.numColumns) ];
                warning( warnTxt );
            end
            if cRow > obj.numRows
                warnTxt = ['sublimeFigure warns: attempting to create'...
                    'a subplot starting at ' int2str(cRow) ' row may result'...
                    ' in unexpected figure appearance. Max rows is set'...
                    ' to ' int2str(obj.numRows) ];
                warning( warnTxt );
            end   
            if nargin == 5
                cSpan = varargin{1};
                rSpan = varargin{2};
                validateattributes( cSpan, {'numeric'},...
                    {'integer', 'nonnegative'});
                validateattributes( rSpan, {'numeric'},...
                    {'integer', 'nonnegative'});
                if ( cCol + cSpan - 1) > obj.numColumns
                    warnTxt = ['sublimeFigure warns: attempting to create'...
                        'a subplot starting at ' int2str(cCol) ' column and '...
                        'spanning over ' int2str(cSpan) ' columns may result'...
                        ' in unexpected figure appearance. Max. columns '...
                        ' is set to ' int2str(obj.numColumns) ];
                    error( warnTxt );
                end
                if ( cRow + rSpan - 1 ) > obj.numRows
                    warnTxt = ['sublimeFigure warns: attempting to create'...
                        'a subplot starting at ' int2str(cRow) ' row and '...
                        'spanning over ' int2str(rSpan) ' rows may result'...
                        ' in unexpected figure appearance. Max. rows is '...
                        'set to ' int2str(obj.numRows) ];
                    error( warnTxt );
                end                
            else
                rSpan = 1;
                cSpan = 1;
            end
            % Calculate size and position
            plotBottom = obj.getPlotBottom( cRow, rSpan );
            plotLeft   = obj.getPlotLeft( cCol );
            plotWidth  = obj.getPlotWidth( cCol, cSpan );
            plotHeight = obj.getPlotHeight( cRow, rSpan );
            % Create new axis
            ax = subplot('Position',[plotLeft, plotBottom, plotWidth, plotHeight]);
            % Add the newly created plot to the structure containing
            % handles and basic properties of all subplots
            axID = length( obj.sfPlots ) + 1;
            obj.sfPlots( axID ).ax = ax;
            obj.sfPlots( axID ).row = cRow;
            obj.sfPlots( axID ).col = cCol;
            obj.sfPlots( axID ).rSpan = rSpan;
            obj.sfPlots( axID ).cSpan = cSpan;
            
        end
        
        % ================================================================
        
        function cb = colorbar( obj, axID )
            % Add a colourbar to axis with axID. Returns handle to colourbar
            
            validateattributes( axID, {'numeric'},...
                {'integer', 'nonnegative', '<=', length(obj.sfPlots)});
            
            % Get the handle of current axis to set back focus to it once
            % the colour bar is created, in the case axID is not the same
            % as the current axis
            currAx = gca;
            
            % Change focus to the axID
            axes( obj.sfPlots( axID ).ax );
            
            % Add colour bar
            cb = colorbar;
            cbLeft = obj.getPlotLeft( obj.sfPlots(axID).col ) +...
                obj.cBarPadding/obj.totalWidth +...
                obj.getPlotWidth( obj.sfPlots(axID).col, obj.sfPlots(axID).cSpan );
            cb.Position = [ cbLeft,...
                obj.getPlotBottom( obj.sfPlots(axID).row, obj.sfPlots(axID).rSpan ),...
                obj.cBarWidth/obj.totalWidth,...
                obj.getPlotHeight( obj.sfPlots(axID).row, obj.sfPlots(axID).rSpan )];
            cb.FontSize = obj.defFontSize;
            
            % Reset current axis
            axes( currAx );
           
        end
        
        % ================================================================
        
        function lb = label( obj, axID, location, str )
            % Add a neat text label to the subplot in either 'topleft',
            % 'topright', 'bottomleft', or 'bottomright' corners.
            
            validatestring( location, {'topleft', 'topright',...
                'bottomleft', 'bottomright'} );
            
            validateattributes( axID, {'numeric'},...
                {'integer', 'nonnegative', '<=', length(obj.sfPlots)});
            
            % Default distance of the text from the edges of the specified
            % corner
            dx = 0.1;
            dy = 0.1;
            
            % Get the handle of current axis to set back focus to it once
            % the colour bar is created, in the case axID is not the same
            % as the current axis
            currAx = gca;
            
            % Change focus to the axID
            axes( obj.sfPlots( axID ).ax );
            
            % Add text label
            lb = text( 'String', str );
            lb.FontSize = obj.defFontSize;
            
            % Record default units
            defAxUnits = obj.sfPlots( axID ).ax.Units;
            defLbUnits = lb.Units;
            
            % Position the label
            switch obj.defUnits
                case 'cm'
                    lb.Units = 'centimeters';
                    obj.sfPlots( axID ).ax.Units = 'centimeters';
                    axPC = obj.sfPlots( axID ).ax.Position;
                    % get the size of the letter from pt. 1 pt = 1/72 in, 1
                    % inch = 2.54 cm....
                    lbHeight = 1/72 * obj.defFontSize * 2.54;
                case 'in'
                    lb.Units = 'inches';
                    obj.sfPlots( axID ).ax.Units = 'inches';
                    axPC = obj.sfPlots( axID ).ax.Position;
                    % get the size of the letter from pt. 1 pt = 1/72 in, 1
                    % inch = 2.54 cm....
                    lbHeight = 1/72 * obj.defFontSize;
            end
            switch location
                case 'topleft'
                    lb.HorizontalAlignment = 'left';
                    pos = [ dx, axPC(4) - dy - lbHeight/2 ];
                case 'bottomleft'
                    lb.HorizontalAlignment = 'left';
                    pos = [ dx, dy + lbHeight/2 ];
                case 'topright'
                    lb.HorizontalAlignment = 'right';
                    pos = [ axPC(3) - dx, axPC(4) - dy - lbHeight/2 ];
                case 'bottomright'
                    lb.HorizontalAlignment = 'right';
                    pos = [ axPC(3) - dx, dy + lbHeight/2 ];
                otherwise
        			error( 'sublimeFigure screams: Unknown label location "%s"!', location);
            end
            lb.Position = pos;
            
            % Reset units back for resizing to work properly later
            obj.sfPlots( axID ).ax.Units = defAxUnits;
            lb.Units = defLbUnits;           
         
            % Reset axis
            axes( currAx );
        end
        
    end
    
    % ====================================================================
    % ====================================================================
    
    methods ( Access = private, Hidden = true )
        
        function obj = changeUnits( obj, varargin )
            % Change from in to cm and back. The function is triggered
            % 'post set', so new value of defUnits is the target one.
            
            %Disable property change listeners
            for i = 1 : length(obj.propChangeListeners)
                obj.propChangeListeners(i).Enabled = false;
            end
            switch obj.defUnits
                case 'cm'
                    % Switch from in to cm
                    obj.totalWidth = obj.totalWidth * 2.54;
                    obj.totalHeight = obj.totalHeight * 2.54;
                    obj.leftOuterPadding = obj.leftOuterPadding * 2.54;
                    obj.rightOuterPadding = obj.rightOuterPadding * 2.54;
                    obj.leftPadding = obj.leftPadding * 2.54;
                    obj.rightPadding = obj.rightPadding * 2.54;
                    obj.topOuterPadding = obj.topOuterPadding * 2.54;
                    obj.bottomOuterPadding = obj.bottomOuterPadding * 2.54;
                    obj.topPadding = obj.topPadding * 2.54;
                    obj.bottomPadding = obj.bottomPadding * 2.54;
                    obj.cBarWidth = obj.cBarWidth * 2.54;
                    obj.cBarPadding = obj.cBarPadding * 2.54;
                case 'in'
                    % Switch from cm to in
                    obj.totalWidth = obj.totalWidth / 2.54;
                    obj.totalHeight = obj.totalHeight / 2.54;
                    obj.leftOuterPadding = obj.leftOuterPadding / 2.54;
                    obj.rightOuterPadding = obj.rightOuterPadding / 2.54;
                    obj.leftPadding = obj.leftPadding / 2.54;
                    obj.rightPadding = obj.rightPadding / 2.54;
                    obj.topOuterPadding = obj.topOuterPadding / 2.54;
                    obj.bottomOuterPadding = obj.bottomOuterPadding / 2.54;
                    obj.topPadding = obj.topPadding / 2.54;
                    obj.bottomPadding = obj.bottomPadding / 2.54;
                    obj.cBarWidth = obj.cBarWidth / 2.54;
                    obj.cBarPadding = obj.cBarPadding / 2.54;
                otherwise
                    error( ['Unknown unit type: ', obj.defUnits,...
                        '. Must be either in or cm.'] );                    
            end
            %Enable property change listeners back
            for i = 1 : length(obj.propChangeListeners)
                obj.propChangeListeners(i).Enabled = true;
            end            
        end
        
        function obj = resizeFigure( obj, varargin )
            % Resize figure according to the new/updated values
            switch obj.defUnits
                case 'cm'
                    % Setting paper sizes
                    obj.fig.PaperUnits = 'centimeters';
                    % PaperPosition for raster images
                    obj.fig.PaperPosition = [0 0 obj.totalWidth obj.totalHeight];
                    % PaperSize is used by full page pdf and PostScript printers
                    obj.fig.PaperSize = [obj.totalWidth obj.totalHeight];
                    obj.fig.PaperPositionMode = 'manual';
                    % Getting same proportion on screen
                    % Sets the units of the root object (screen) to pixels
                    set(0,'units','pixels');
                    % Obtains this pixel information
                    ss.px = get(0,'screensize');
                    % Sets the units of the root object (screen) to cm
                    set(0,'units','centimeters');
                    % Obtains this inch information
                    ss.cm = get(0,'screensize');
                    % Calculates the resolution (pixels per cm)
                    ss.res = ss.px ./ ss.cm;
                    % Resizing the onscreen figure
                    obj.fig.Units = 'pixels';
                    obj.fig.Position(3) = round( obj.totalWidth * ss.res(3) );
                    obj.fig.Position(4) = round( obj.totalHeight * ss.res(4) );
                    obj.fig.Position(1) = round( 0.5 * ( ss.px(3)-obj.fig.Position(3)));
                    obj.fig.Position(2) = round( 0.5 * ( ss.px(4)-obj.fig.Position(4)));
                case 'in'
                    % Setting paper sizes
                    obj.fig.PaperUnits = 'inches';
                    % PaperPosition for raster images
                    obj.fig.PaperPosition = [0 0 obj.totalWidth obj.totalHeight];
                    % PaperSize is used by full page pdf and PostScript printers
                    obj.fig.PaperSize = [obj.totalWidth obj.totalHeight];
                    obj.fig.PaperPositionMode = 'manual';
                    % Getting same proportion on screen
                    % Sets the units of the root object (screen) to pixels
                    set(0,'units','pixels');
                    % Obtains this pixel information
                    ss.px = get(0,'screensize');
                    % Sets the units of the root object (screen) to cm
                    set(0,'units','inches');
                    % Obtains this inch information
                    ss.in = get(0,'screensize');
                    % Calculates the resolution (pixels per cm)
                    ss.res = ss.px ./ ss.in;
                    % Resizing the onscreen figure
                    obj.fig.Units = 'pixels';
                    obj.fig.Position(3) = round( obj.totalWidth * ss.res(3) );
                    obj.fig.Position(4) = round( obj.totalHeight * ss.res(4) );
                    obj.fig.Position(1) = round( 0.5 * ( ss.px(3)-obj.fig.Position(3)));
                    obj.fig.Position(2) = round( 0.5 * ( ss.px(4)-obj.fig.Position(4)));
                otherwise
                    error( ['Unknown unit type: ', obj.defUnits,...
                        '. Must be either in or cm.'] );
            end
            
            % redo relative sizes
            obj.setRelativeSizes;
            % resize all existing subplots
            if ~isempty( obj.sfPlots )
                for i = 1 : length( obj.sfPlots )
                    obj.resizePlot( i );
                end
            end
        end
        
        % ================================================================
        
        function obj = resizePlot( obj, ID )
            % resize plot with handle ax according to cCol and cRow values
            % for the plot with ID

            % Calculate size and position
            plotBottom = obj.getPlotBottom( obj.sfPlots(ID).row,...
                obj.sfPlots(ID).rSpan);
            plotLeft   = obj.getPlotLeft( obj.sfPlots(ID).col );
            plotWidth  = obj.getPlotWidth( obj.sfPlots(ID).col,...
                obj.sfPlots(ID).cSpan );
            plotHeight = obj.getPlotHeight( obj.sfPlots(ID).row,...
                obj.sfPlots(ID).rSpan );      
            % Update
            obj.sfPlots(ID).ax( 'Position',...
                [plotLeft, plotBottom, plotWidth, plotHeight] );
        end
        
        % ================================================================
        
        function plotBottom = getPlotBottom( obj, cRow, rSpan )
            % Calculates position of the bottom of a subplot at cRow row
            % taking into account that the plot may span several rows
            cRow = cRow + rSpan - 1;
            if cRow == obj.numRows
                plotBottom = obj.bp(end) + obj.bop;
            else
                if length( obj.bp ) == 1 
                    sumOfBottomPaddings = obj.bp * (obj.numRows-cRow+1);
                else
                    sumOfBottomPaddings = sum(obj.bp(cRow:end));
                end
                if length( obj.tp ) == 1 
                    sumOfTopPaddings = obj.tp * (obj.numRows-cRow);
                else
                    sumOfTopPaddings = sum(obj.tp(cRow+1:end));
                end
                plotBottom = (obj.numRows-cRow)*...
                    (obj.cellHeight * mean(obj.rowHeightWeights(cRow+1:end)))+...
                    + sumOfBottomPaddings + sumOfTopPaddings + obj.bop;
            end
        end

        % ================================================================
        
        function plotLeft = getPlotLeft( obj, cCol )
            % Calculates position of the left of a subplot at cCol column
            if cCol == 1
                plotLeft = obj.lp(1) + obj.lop;
            else
                if length( obj.lp ) == 1 
                    sumOfLeftPaddings = obj.lp(1) * cCol;
                else
                    sumOfLeftPaddings = sum(obj.lp(1:cCol));
                    
                end
                if length( obj.rp ) == 1 
                    sumOfRightPaddings = obj.rp(1) * (cCol-1);
                else
                    sumOfRightPaddings = sum(obj.rp(1:cCol-1));
                    
                end
                plotLeft = (cCol-1)*(obj.cellWidth * mean(obj.colWidthWeights(1:cCol-1)))+...
                    + sumOfLeftPaddings + sumOfRightPaddings + obj.lop;
            end
        end

        % ================================================================
        
        function plotHeight = getPlotHeight( obj, cRow, rSpan )
            cRow = cRow + rSpan - 1;
            plotHeight  = obj.cellHeight * sum(obj.rowHeightWeights(cRow-rSpan+1:cRow));
            if rSpan > 1
                if length( obj.tp ) > 1
                    plotHeight = plotHeight + sum( obj.tp( cRow-rSpan+2:cRow));
                else
                    plotHeight = plotHeight + obj.tp(1)*( rSpan - 1 );
                end
                if length( obj.bp ) > 1
                    plotHeight = plotHeight + sum( obj.bp( cRow-rSpan+1:cRow-1));
                else
                    plotHeight = plotHeight + obj.bp(1)*( rSpan - 1 );
                end
            end
        end        
        
        % ================================================================
        
        function plotWidth = getPlotWidth( obj, cCol, cSpan )
            plotWidth  = obj.cellWidth * sum(obj.colWidthWeights(cCol:cCol+cSpan-1));
            if cSpan > 1
                if length( obj.rp ) > 1
                    plotWidth = plotWidth + sum( obj.rp(cCol:cCol+cSpan-2));
                else
                    plotWidth = plotWidth + obj.rp(1)*(cSpan-1);
                end
                if length( obj.lp ) > 1
                    plotWidth = plotWidth + sum( obj.lp(cCol+1:cCol+cSpan-1));
                else
                    plotWidth = plotWidth + obj.lp(1)*(cSpan-1);
                end
            end
        end
        
        % ================================================================
        
        function obj = setRelativeSizes( obj )
            % Recalculates all relative sizes of paddings and unit cells
            
            obj.checkWeightArrays;
            obj.lop = obj.leftOuterPadding / obj.totalWidth;
            obj.rop = obj.rightOuterPadding / obj.totalWidth;
            obj.lp = obj.leftPadding ./ obj.totalWidth;
            obj.rp = obj.rightPadding ./ obj.totalWidth;
            obj.cellWidth = ( 1-obj.lop-obj.rop-(mean(obj.lp)+mean(obj.rp))*...
                (obj.numColumns)) / sum( obj.colWidthWeights );
            obj.top = obj.topOuterPadding / obj.totalHeight;
            obj.bop = obj.bottomOuterPadding / obj.totalHeight;
            obj.tp = obj.topPadding ./ obj.totalHeight;
            obj.bp = obj.bottomPadding ./ obj.totalHeight;
            obj.cellHeight = (1-obj.top-obj.bop-(mean(obj.tp)+mean(obj.bp)) *...
                (obj.numRows)) / sum( obj.rowHeightWeights );
        end
        
        % ================================================================
        
        function obj = checkWeightArrays( obj )
            % Checks if rowHeightWeights and colWidthWeights are the same
            % length as the number of rows and colunmns. If they are too long -
            % trims, if too short then appends with ones
            
            if length( obj.rowHeightWeights ) > obj.numRows
                obj.rowHeightWeights = obj.rowHeightWeights( 1:obj.numRows);
            elseif length( obj.rowHeightWeights ) < obj.numRows
                for i = length( obj.rowHeightWeights )+1 : obj.numRows
                    obj.rowHeightWeights(i) = 1;
                end
            end
            if length( obj.colWidthWeights ) > obj.numColumns
                obj.colWidthWeights = obj.colWidthWeights( 1:obj.numColumns);
            elseif length( obj.colWidthWeights ) < obj.numColumns
                for i = length( obj.colWidthWeights )+1 : obj.numColumns
                    obj.colWidthWeights(i) = 1;
                end
            end
        end
    end
end